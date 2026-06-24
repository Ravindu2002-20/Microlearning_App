# Profile screen: replace mock data with DB

- [ ] Inspect profile UI sections (Stats row, My Learning, Leaderboard) and identify mock values.
- [ ] Add missing DB methods in `LearningRepository`:
  - [ ] `fetchUserStatsFromProgress`
  - [ ] `fetchUserMyLearningFromProgress`
  - [ ] `fetchLeaderboardFromProgress` (weekly + all-time)
- [ ] Update `lib/features/profile/screens/profile_screen.dart`:
  - [ ] Remove mock values from `_StatsRow`.
  - [ ] Replace “My Learning” body with DB-driven list; show `no records` if empty.
  - [ ] Replace “Leaderboard” body with DB-driven rows; show `no records` if empty.
- [ ] Run `flutter analyze`.
- [ ] Run app / ensure profile screen builds.

