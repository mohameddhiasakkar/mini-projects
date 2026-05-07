import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';

import { Recommendation } from './recommendation';

describe('Recommendation', () => {
  let fixture: ComponentFixture<Recommendation>;
  let httpMock: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Recommendation],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();

    fixture = TestBed.createComponent(Recommendation);
    httpMock = TestBed.inject(HttpTestingController);
    fixture.detectChanges();
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should create', () => {
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should load recommendations on submit', () => {
    const comp = fixture.componentInstance;
    comp.student.country = 'Greece';
    comp.submit();
    const req = httpMock.expectOne('http://127.0.0.1:5000/predict');
    req.flush({
      recommendations: [
        {
          name: 'Uni A',
          country: 'Greece',
          score: 70,
          components: {
            country: 40,
            rules_profile: 35,
            similarity: 5,
            similarity_01: 0.2,
          },
        },
      ],
      meta: {
        model: {
          id: 'hybrid_v1_tfidf_rules',
          family: 'hybrid',
          description: 'x',
          library: 'scikit-learn',
          similarity_scale_points: 22,
        },
        points: { country_max: 40, skills: 10, study: 5, grades: 20 },
        skill_categories: [],
        study_categories: ['Natural sciences'],
        skill_breadth_bonus: 0,
        skills_listed: 0,
      },
    });
    expect(comp.results.length).toBe(1);
    expect(comp.results[0].name).toBe('Uni A');
    expect(comp.loading).toBe(false);
  });
});
