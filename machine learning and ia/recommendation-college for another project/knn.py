import pandas as pd
import numpy as np

from sklearn.preprocessing import OneHotEncoder
from sklearn.neighbors import NearestNeighbors

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ==============================
# 1. LOAD DATA
# ==============================
df = pd.read_csv("contry.csv")
df.columns = df.columns.str.strip()
df["major"] = df["major"].str.strip()
df["country"] = df["country"].str.strip()

# ==============================
# 2. MAJOR NORMALIZATION
# ==============================
MAJOR_MAPPING = {
    "health": "medicine",
    "medicine": "medicine",
    "medical": "medicine",
    "pharmacy": "medicine",
    "chinese_medicine": "medicine",
    "law": "law",
    "legal": "law",
    "economics": "business",
    "business": "business",
    "business_administration": "business",
    "education": "education",
    "architecture": "engineering",
    "civil_architecture": "engineering",
    "urban_design": "engineering",
    "civil_engineering": "engineering",
    "software_engineering": "engineering",
    "mechanical_engineering": "engineering",
    "digital_engineering": "engineering",
    "ai": "engineering",
    "engineering": "engineering",
    "craftsmanship": "arts"
}

def normalize_major(m):
    if not isinstance(m, str):
        return ""
    m = m.lower().strip().replace(" ", "_")
    return MAJOR_MAPPING.get(m, m)

df["normalized_major"] = df["major"].apply(normalize_major)

# ==============================
# 3. FEATURE ENCODING (TRAINED ONCE - STABLE)
# ==============================
encoder_country = OneHotEncoder(handle_unknown="ignore", sparse_output=False)
encoder_major = OneHotEncoder(handle_unknown="ignore", sparse_output=False)

country_vec = encoder_country.fit_transform(df[["country"]])
major_vec = encoder_major.fit_transform(df[["normalized_major"]])

# Global feature matrix with stable weights (Country 0.3, Major 0.7)
X_global = np.hstack([
    country_vec * 0.3,
    major_vec * 0.7
])

# ==============================
# 4. KNN MODEL (TRAINED ONCE - GLOBAL)
# ==============================
knn_model = NearestNeighbors(metric="cosine", algorithm="auto")
knn_model.fit(X_global)

# ==============================
# 5. FASTAPI APP
# ==============================
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==============================
# 6. INPUT MODEL
# ==============================
class RecommendationRequest(BaseModel):
    country: str
    major: str

# ==============================
# 7. CORE RECOMMENDER
# ==============================
def recommend(country, major, top_n=5):
    major_norm = normalize_major(major)

    try:
        # Encode user input using the GLOBAL stable encoders (use DataFrames to avoid warnings)
        user_country_df = pd.DataFrame([[country]], columns=["country"])
        user_major_df = pd.DataFrame([[major_norm]], columns=["normalized_major"])

        user_country_vec = encoder_country.transform(user_country_df)
        user_major_vec = encoder_major.transform(user_major_df)
    except Exception as e:
        print(f"Encoding Error: {e}")
        return []

    # Apply stable global feature weighting
    try:
        user_vec = np.hstack([
            user_country_vec * 0.3,
            user_major_vec * 0.7
        ])
    except ValueError:
        # Handle cases where hstack fails due to empty dimensions
        return []

    # Query the GLOBAL model for ALL potentially relevant neighbors
    # This prevents numerical explosions caused by small per-country datasets
    distances, indices = knn_model.kneighbors(user_vec, n_neighbors=len(df))

    # Debugging as requested
    if len(distances[0]) > 0:
        print(f"DEBUG: Min Dist: {distances[0].min():.4f}, Max Dist: {distances[0].max():.4f}")

    results = []

    for i, idx in enumerate(indices[0]):
        dist = float(distances[0][i])
        row = df.iloc[idx]

        # STEP 1: Strict Country Constraint
        if str(row["country"]).strip().lower() != str(country).strip().lower():
            continue

        # STEP 2: Score Calculation (1 - distance)
        # Cosine distance is [0, 2]. Similarity = 1 - distance.
        similarity = 1.0 - (dist if dist <= 1.0 else 1.0) 
        similarity = max(0, min(similarity, 1))  # Safety clamp

        results.append({
            "institution_name": row["institution_name"],
            "country": row["country"],
            "major": row["major"],
            "similarity_score": round(similarity * 1, 2)
        })

        if len(results) >= top_n:
            break

    return results

# ==============================
# 8. API ROUTES
# ==============================
@app.get("/")
def home():
    return {"message": "LinkedU Recommender API 🚀"}

@app.get("/options")
def options():
    return {
        "countries": sorted(df["country"].dropna().unique().tolist()),
        "majors": sorted(df["major"].dropna().unique().tolist())
    }

@app.post("/recommend")
def get_recommendations(req: RecommendationRequest):
    try:
        return recommend(req.country, req.major)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# ==============================
# 9. RUN SERVER
# ==============================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("knn:app", host="0.0.0.0", port=8000, reload=True)