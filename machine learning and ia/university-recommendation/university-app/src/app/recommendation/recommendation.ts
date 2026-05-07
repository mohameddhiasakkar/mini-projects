import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService, PredictMeta, UniversityRecommendation } from '../services/api.service';

@Component({
  selector: 'app-recommendation',
  imports: [CommonModule, FormsModule],
  templateUrl: './recommendation.html',
  styleUrl: './recommendation.css',
})
export class Recommendation {
  student = {
    age: '',
    country: '',
    major: '',
    language: '',
    skills: '',
    moyenne: '',
  };

  /** Typical fields of study — engineering, energy, sciences, etc. */
  readonly quickMajors = [
    'Electrical engineering',
    'Mechanical engineering',
    'Civil engineering',
    'Renewable energy',
    'Petroleum engineering',
    'Computer science',
    'Physics',
    'Chemistry',
    'Biology',
    'Environmental science',
    'Medicine',
    'Economics',
    'Architecture',
  ];

  /** Suggested skills — mix of tech, arts, sports, languages (add with one click). */
  readonly quickSkills = [
    'Python',
    'JavaScript',
    'React',
    'Dance',
    'Theater',
    'Photography',
    'English',
    'Arabic',
    'French',
    'Leadership',
    'Machine learning',
    'Data science',
    'Yoga',
    'Football',
    'Public speaking',
    'Project management',
    'Violin',
    'Graphic design',
  ];

  results: UniversityRecommendation[] = [];
  meta: PredictMeta | null = null;
  loading = false;
  error: string | null = null;

  constructor(private api: ApiService) {}

  addMajor(label: string) {
    const needle = label.trim().toLowerCase();
    const current = this.student.major.trim().toLowerCase();
    if (!needle || current.includes(needle)) {
      return;
    }
    this.student.major = this.student.major.trim()
      ? `${this.student.major.trim()}, ${label}`
      : label;
  }

  addSkill(label: string) {
    const needle = label.trim().toLowerCase();
    const current = this.student.skills.trim().toLowerCase();
    if (!needle || current.includes(needle)) {
      return;
    }
    this.student.skills = this.student.skills.trim()
      ? `${this.student.skills.trim()}, ${label}`
      : label;
  }

  submit() {
    this.error = null;
    this.loading = true;
    this.meta = null;
    this.api.predict(this.student).subscribe({
      next: (res) => {
        this.results = res.recommendations ?? [];
        this.meta = res.meta ?? null;
        this.loading = false;
      },
      error: () => {
        this.results = [];
        this.meta = null;
        this.loading = false;
        this.error =
          'Could not reach the recommendation API. Start the Flask server on port 5000 (python preduction.py from the machine learning folder).';
      },
    });
  }
}
