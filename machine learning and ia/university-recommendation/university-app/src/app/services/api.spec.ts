import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';

import { ApiService } from './api.service';

describe('ApiService', () => {
  let service: ApiService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(ApiService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should POST to /predict', () => {
    const payload = { country: 'France', skills: 'python', moyenne: '14' };
    const body = {
      recommendations: [
        {
          name: 'Test',
          country: 'France',
          score: 95,
          components: {
            country: 40,
            rules_profile: 61,
            similarity: 4.2,
            similarity_01: 0.19,
          },
        },
      ],
      meta: {
        model: {
          id: 'hybrid_v1_tfidf_rules',
          family: 'hybrid',
          description: 'Test',
          library: 'scikit-learn',
          similarity_scale_points: 22,
        },
        points: { country_max: 40, skills: 25, study: 10, grades: 26, rules_profile_max: 75 },
        skill_categories: ['Programming & software'],
        study_categories: ['Engineering'],
        skill_breadth_bonus: 0,
        skills_listed: 1,
        query_text_length: 12,
      },
    };
    service.predict(payload).subscribe((res) => {
      expect(res).toEqual(body);
    });
    const req = httpMock.expectOne('http://127.0.0.1:5000/predict');
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(payload);
    req.flush(body);
  });
});
