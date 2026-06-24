- [ ] Inspect existing profile/progress/leaderboard Supabase access patterns in repositories (beyond learning_repository).
- [ ] Refactor `lib/features/profile/screens/profile_screen.dart` to remove all hardcoded/mock data.
- [ ] Implement DB-backed loading for:
  - [x] Profile header (full_name/username/avatar_url from `profiles`)
  - [ ] Stats row (lessons completed count, total XP, streak, rank) from DB if available; otherwise show `no records`.
  - [ ] My Learning section (recently watched categories) from user_progress + lessons.
  - [ ] Leaderboard section (top users & current user) from DB if available; otherwise show `no records`.
- [ ] Add “no records” UI per section when result sets are empty.
- [ ] Run `flutter analyze` / `flutter test` to ensure build passes.

