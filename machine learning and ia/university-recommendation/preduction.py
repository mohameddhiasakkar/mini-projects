"""Flask API for university recommendations. Core logic lives in recommendation_service."""

from flask import Flask, jsonify, request

from recommendation_service import get_unis_by_country, recommend, universities

app = Flask(__name__)


@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return response


@app.route("/predict", methods=["OPTIONS"])
@app.route("/universities", methods=["OPTIONS"])
def preflight():
    return "", 204


@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json(silent=True) or {}
    return jsonify(recommend(data))


@app.route("/universities", methods=["GET"])
def list_universities():
    country = request.args.get("country", "")
    filtered = get_unis_by_country(country)
    return jsonify(filtered[:50])


@app.route("/health", methods=["GET"])
def health():
    return jsonify(
        {
            "status": "ok",
            "universities_loaded": len(universities),
            "model": "recommendation_service.hybrid_v1_tfidf_rules",
        }
    )


if __name__ == "__main__":
    app.run(debug=True)
