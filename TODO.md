# TODO - user_xp_summary leaderboard refactor

## Step 1
Update `quiz_results_screen.dart` upsert into `user_xp_summary` to include:
- `videos_watched`
- `correct_answers`
- `total_xp`, `streak`, `level`, `xp_updated_at`

## Step 2
Update `learning_repository.dart` so that when a lesson is marked completed (`logLessonCompletion`) it also:
- recalculates streak, videos_watched, correct_answers
- computes `total_xp` and `level`
- upserts into `user_xp_summary` onConflict: `user_id`

## Step 3
Replace `fetchLeaderboardFromProgress` with new `fetchLeaderboard({int limit = 100})` that:
- selects from `user_xp_summary` (user_id, total_xp, level)
- joins `profiles` for display name + avatar
- orders by `total_xp DESC`
- computes rank client-side (or SQL)
- returns ALL users (caller can slice)

## Step 4
Update `profile_screen.dart` `_LeaderboardSection`:
- call `fetchLeaderboard`
- show user with 0 XP if missing in summary
- show error UI if fetch fails
- remove fallback logic that only displayed current user

## Step 5
Run `flutter analyze` and fix any compile issues.

