# TODO

- [ ] Add `fetchWeeklyCompletionCounts` to `LearningRepository` to compute per-weekday completion counts from `user_progress` (`is_completed=true`, grouped by `last_accessed`).
- [ ] Update `home_screen.dart`:
  - [ ] Replace `_WeeklyBars` hardcoded data with data-driven heights.
  - [ ] Wrap `_WeeklyBars` to load data for the logged-in user (FutureBuilder).
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test` (if available) and verify the Home “This Week” chart reflects real progress.

