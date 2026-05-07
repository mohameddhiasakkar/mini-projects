import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface PredictModelMeta {
  id: string;
  family: string;
  description: string;
  library: string;
  similarity_scale_points: number;
}

export interface PredictMeta {
  model?: PredictModelMeta;
  points: {
    country_max: number;
    skills: number;
    study: number;
    grades: number;
    rules_profile_max?: number;
  };
  skill_categories: string[];
  study_categories: string[];
  skill_breadth_bonus: number;
  skills_listed: number;
  query_text_length?: number;
}

export interface ScoreComponents {
  country: number;
  rules_profile: number;
  similarity: number;
  similarity_01: number;
}

export interface UniversityRecommendation {
  name: string;
  country: string;
  score: number;
  components?: ScoreComponents;
}

export interface PredictResponse {
  recommendations: UniversityRecommendation[];
  meta: PredictMeta;
}

@Injectable({
  providedIn: 'root',
})
export class ApiService {
  private apiUrl = 'http://127.0.0.1:5000/predict';

  constructor(private http: HttpClient) {}

  predict(data: Record<string, string>): Observable<PredictResponse> {
    return this.http.post<PredictResponse>(this.apiUrl, data);
  }

  getUniversities(country: string) {
    const q = encodeURIComponent(country);
    return this.http.get(`http://127.0.0.1:5000/universities?country=${q}`);
  }
}
