import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Recommendation } from './recommendation/recommendation';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Recommendation],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  protected readonly title = signal('university-app');
}
