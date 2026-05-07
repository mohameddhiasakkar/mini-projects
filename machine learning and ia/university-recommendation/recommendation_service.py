"""
Hybrid university recommender: interpretable rule features + TF–IDF semantic similarity.

Rules encode country match, skills, field of study, and grades. ML layer ranks
institutions by cosine similarity between the student text profile and each
university document (name, country, domains).
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

_DATA_DIR = Path(__file__).resolve().parent
_DATA_FILE = _DATA_DIR / "contry.json"

with open(_DATA_FILE, encoding="utf-8") as f:
    universities: list[dict[str, Any]] = json.load(f)

# ---------------------------------------------------------------------------
# Rule-based feature taxonomy (same as before)
# ---------------------------------------------------------------------------

SKILL_CATEGORIES: list[tuple[str, int, list[str]]] = [
    (
        "Programming & software",
        5,
        [
            "python",
            "java",
            "javascript",
            "typescript",
            "c++",
            "c#",
            "rust",
            "go",
            "kotlin",
            "swift",
            "php",
            "ruby",
            "scala",
            "perl",
            "matlab",
            "sql",
            "programming",
            "coding",
            "software",
            "algorithm",
            "backend",
            "compiler",
        ],
    ),
    (
        "Web & cloud",
        5,
        [
            "react",
            "angular",
            "vue",
            "svelte",
            "node",
            "html",
            "css",
            "sass",
            "django",
            "flask",
            "fastapi",
            "spring",
            "laravel",
            "express",
            "graphql",
            "docker",
            "kubernetes",
            "aws",
            "azure",
            "gcp",
            "devops",
            "terraform",
            "linux",
            "nginx",
            "microservices",
        ],
    ),
    (
        "Data & AI",
        5,
        [
            "data science",
            "machine learning",
            "deep learning",
            "neural",
            "tensorflow",
            "pytorch",
            "pandas",
            "numpy",
            "scikit",
            "nlp",
            "computer vision",
            "artificial intelligence",
            "statistics",
            "analytics",
            "big data",
            "spark",
            "hadoop",
            "tableau",
            "power bi",
            "excel",
        ],
    ),
    (
        "Arts & performance",
        5,
        [
            "dance",
            "dancing",
            "ballet",
            "hip hop",
            "hip-hop",
            "choreography",
            "music",
            "piano",
            "guitar",
            "violin",
            "singing",
            "vocal",
            "orchestra",
            "theater",
            "theatre",
            "acting",
            "drama",
            "film",
            "cinema",
            "painting",
            "drawing",
            "sculpture",
            "photography",
            "illustration",
            "fashion",
            "creative writing",
            "poetry",
            "salsa",
            "tango",
            "jazz",
        ],
    ),
    (
        "Sports & fitness",
        5,
        [
            "football",
            "soccer",
            "basketball",
            "volleyball",
            "tennis",
            "badminton",
            "swimming",
            "athletics",
            "running",
            "marathon",
            "cycling",
            "rugby",
            "handball",
            "boxing",
            "martial arts",
            "karate",
            "judo",
            "fitness",
            "gym",
            "yoga",
            "pilates",
            "crossfit",
            "hiking",
            "skiing",
            "surfing",
        ],
    ),
    (
        "Languages & communication",
        5,
        [
            "english",
            "french",
            "spanish",
            "german",
            "italian",
            "portuguese",
            "arabic",
            "chinese",
            "mandarin",
            "japanese",
            "korean",
            "russian",
            "turkish",
            "dutch",
            "swedish",
            "translation",
            "interpretation",
            "public speaking",
            "debate",
            "journalism",
            "copywriting",
        ],
    ),
    (
        "Leadership & teamwork",
        5,
        [
            "leadership",
            "teamwork",
            "team lead",
            "management",
            "project management",
            "scrum",
            "agile",
            "mentoring",
            "coaching",
            "negotiation",
            "networking",
            "volunteering",
            "ngo",
            "organization",
            "time management",
            "empathy",
        ],
    ),
    (
        "STEM & research",
        5,
        [
            "physics",
            "chemistry",
            "biology",
            "mathematics",
            "calculus",
            "algebra",
            "research",
            "laboratory",
            "lab work",
            "robotics",
            "electronics",
            "iot",
            "nanotechnology",
            "biotech",
        ],
    ),
]

STUDY_FIELD_CATEGORIES: list[tuple[str, int, list[str]]] = [
    (
        "Engineering",
        5,
        [
            "engineering",
            "mechanical engineering",
            "electrical engineering",
            "civil engineering",
            "chemical engineering",
            "industrial engineering",
            "aerospace",
            "automotive",
            "materials engineering",
            "mining engineering",
            "telecom",
            "telecommunications",
            "mechatronics",
            "hydraulic",
            "geotechnical",
            "structural engineering",
            "biomedical engineering",
            "process engineering",
            "systems engineering",
        ],
    ),
    (
        "Energy & power",
        5,
        [
            "energy",
            "renewable energy",
            "solar energy",
            "wind energy",
            "nuclear engineering",
            "petroleum",
            "oil and gas",
            "power systems",
            "power engineering",
            "thermodynamics",
            "thermal",
            "hydropower",
            "geothermal",
            "smart grid",
            "electrical power",
            "battery",
            "fuel cell",
            "sustainable energy",
        ],
    ),
    (
        "Environmental & earth sciences",
        4,
        [
            "environmental",
            "climate",
            "ecology",
            "geology",
            "earth science",
            "oceanography",
            "hydrology",
            "agricultural engineering",
            "water resources",
        ],
    ),
    (
        "Natural sciences",
        5,
        [
            "physics",
            "chemistry",
            "biology",
            "mathematics",
            "applied mathematics",
            "statistics",
            "astronomy",
            "natural science",
            "marine biology",
            "microbiology",
            "genetics",
        ],
    ),
    (
        "Computer & IT studies",
        5,
        [
            "computer science",
            "informatics",
            "software engineering",
            "information technology",
            "ict",
            "cybersecurity",
            "networks",
            "data engineering",
        ],
    ),
    (
        "Life sciences & health",
        5,
        [
            "medicine",
            "medical",
            "pharmacy",
            "nursing",
            "dentistry",
            "veterinary",
            "biochemistry",
            "biotechnology",
            "public health",
            "physiotherapy",
            "nutrition",
            "radiology",
        ],
    ),
    (
        "Architecture & built environment",
        4,
        [
            "architecture",
            "urban planning",
            "construction",
            "surveying",
            "civil engineering",
        ],
    ),
    (
        "Business & economics",
        4,
        [
            "economics",
            "finance",
            "accounting",
            "business administration",
            "management",
            "marketing",
            "commerce",
        ],
    ),
    (
        "Law & social sciences",
        4,
        [
            "law",
            "legal",
            "political science",
            "sociology",
            "psychology",
            "anthropology",
            "history",
            "philosophy",
            "education",
            "pedagogy",
        ],
    ),
    (
        "Arts & humanities",
        4,
        [
            "literature",
            "linguistics",
            "fine arts",
            "graphic design",
            "music",
            "film studies",
        ],
    ),
]

SKILLS_CAP = 30
STUDY_CAP = 15
COUNTRY_POINTS = 40
# Max points from TF–IDF cosine similarity (differentiates universities with same rule score)
ML_SIMILARITY_POINTS = 22

MODEL_ID = "hybrid_v1_tfidf_rules"


def _tokenize_skills(raw: str) -> list[str]:
    if not raw or not str(raw).strip():
        return []
    parts = re.split(r"[,;\n|/]+", raw)
    return [p.strip() for p in parts if p.strip()]


def analyze_skills(skills_raw: str) -> tuple[int, list[str], int]:
    text = f" {str(skills_raw or '').lower()} "
    matched_labels: list[str] = []
    total = 0
    for label, weight, keywords in SKILL_CATEGORIES:
        if any(kw in text for kw in keywords):
            matched_labels.append(label)
            total += weight
    total = min(SKILLS_CAP, total)
    tokens = _tokenize_skills(str(skills_raw or ""))
    breadth = min(5, max(0, (len(tokens) - 3) // 2) * 2) if len(tokens) > 3 else 0
    combined = min(SKILLS_CAP, total + breadth)
    return combined, matched_labels, breadth


def analyze_study(major_raw: str) -> tuple[int, list[str]]:
    text = f" {str(major_raw or '').lower()} "
    if not text.strip():
        return 0, []
    matched_labels: list[str] = []
    total = 0
    for label, weight, keywords in STUDY_FIELD_CATEGORIES:
        if any(kw in text for kw in keywords):
            matched_labels.append(label)
            total += weight
    return min(STUDY_CAP, total), matched_labels


def grade_points(student: dict) -> int:
    try:
        m = float(student.get("moyenne") or 0)
    except (TypeError, ValueError):
        return 0
    if m >= 16:
        return 30
    if m >= 14:
        return 26
    if m >= 12:
        return 20
    if m >= 10:
        return 12
    return 5


def student_query_text(student: dict) -> str:
    parts = [
        str(student.get("major") or ""),
        str(student.get("skills") or ""),
        str(student.get("language") or ""),
    ]
    return " ".join(p.strip() for p in parts if p and str(p).strip())


# ---------------------------------------------------------------------------
# TF–IDF index (fit once at import)
# ---------------------------------------------------------------------------


def _uni_document(u: dict[str, Any]) -> str:
    name = str(u.get("name") or "")
    country = str(u.get("country") or "")
    domains = u.get("domains") or []
    dom = " ".join(str(d) for d in domains if d)
    return f"{name} {country} {dom}".lower()


class _SemanticIndex:
    def __init__(self, rows: list[dict[str, Any]]) -> None:
        self.docs = [_uni_document(u) for u in rows]
        self.vectorizer = TfidfVectorizer(
            max_features=30_000,
            ngram_range=(1, 2),
            min_df=2,
            max_df=0.92,
            stop_words="english",
            sublinear_tf=True,
            dtype=np.float64,
        )
        self.X = self.vectorizer.fit_transform(self.docs)

    def similarities(self, query: str, row_indices: list[int]) -> np.ndarray:
        if not row_indices:
            return np.array([], dtype=np.float64)
        q = (query or "").strip()
        if not q:
            return np.full(len(row_indices), 0.25, dtype=np.float64)
        qv = self.vectorizer.transform([q])
        block = self.X[row_indices]
        sims = cosine_similarity(qv, block).ravel()
        return np.clip(sims, 0.0, 1.0)


_semantic_index: _SemanticIndex | None = None


def _get_index() -> _SemanticIndex:
    global _semantic_index
    if _semantic_index is None:
        _semantic_index = _SemanticIndex(universities)
    return _semantic_index


# ---------------------------------------------------------------------------
# Candidate selection (same semantics as legacy)
# ---------------------------------------------------------------------------


def get_unis_by_country(country: str) -> list[dict[str, Any]]:
    needle = (country or "").lower()
    return [u for u in universities if needle in (u.get("country") or "").lower()]


def _candidate_indices(country: str) -> tuple[list[int], list[dict[str, Any]]]:
    if country:
        needle = country.lower()
        pairs: list[tuple[int, dict[str, Any]]] = []
        for i, u in enumerate(universities):
            if needle in (u.get("country") or "").lower():
                pairs.append((i, u))
            if len(pairs) >= 50:
                break
        if not pairs:
            return [], []
        idx, unis = zip(*pairs)
        return list(idx), list(unis)
    pairs = list(enumerate(universities[:200]))[:50]
    if not pairs:
        return [], []
    idx, unis = zip(*pairs)
    return list(idx), list(unis)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def recommend(student: dict[str, Any]) -> dict[str, Any]:
    country = str(student.get("country") or "")
    skill_pts, skill_cats, breadth_bonus = analyze_skills(str(student.get("skills") or ""))
    study_pts, study_cats = analyze_study(str(student.get("major") or ""))
    grade_pts = grade_points(student)

    rule_total = skill_pts + study_pts + grade_pts
    idx_list, unis_slice = _candidate_indices(country)
    query = student_query_text(student)
    index = _get_index()
    sims = index.similarities(query, idx_list)

    results: list[dict[str, Any]] = []
    student_country = (student.get("country") or "").lower()

    for uni, sim in zip(unis_slice, sims, strict=True):
        uni_country_pts = (
            COUNTRY_POINTS if student_country == (uni.get("country") or "").lower() else 0
        )
        ml_pts = float(sim) * ML_SIMILARITY_POINTS
        raw = uni_country_pts + rule_total + ml_pts
        score = min(100, int(round(raw)))
        results.append(
            {
                "name": uni["name"],
                "country": uni.get("country", ""),
                "score": score,
                "components": {
                    "country": uni_country_pts,
                    "rules_profile": rule_total,
                    "similarity": round(ml_pts, 2),
                    "similarity_01": round(float(sim), 4),
                },
            }
        )

    results.sort(key=lambda x: x["score"], reverse=True)
    top = results[:5]

    return {
        "recommendations": top,
        "meta": {
            "model": {
                "id": MODEL_ID,
                "family": "hybrid",
                "description": (
                    "Interpretable rules (skills, study, grades, country) plus TF–IDF cosine "
                    "similarity between your profile text and each institution (name, country, domains)."
                ),
                "library": "scikit-learn",
                "similarity_scale_points": ML_SIMILARITY_POINTS,
            },
            "points": {
                "country_max": COUNTRY_POINTS,
                "skills": skill_pts,
                "study": study_pts,
                "grades": grade_pts,
                "rules_profile_max": SKILLS_CAP + STUDY_CAP + 30,
            },
            "skill_categories": skill_cats,
            "study_categories": study_cats,
            "skill_breadth_bonus": breadth_bonus,
            "skills_listed": len(_tokenize_skills(str(student.get("skills") or ""))),
            "query_text_length": len(query.strip()),
        },
    }
