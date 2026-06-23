# TODO

- [ ] Fix initial navigation flow in `lib/main.dart` so:
  - Onboarding shows only once (fresh install), then goes to login.
  - If user is already logged in (session restored), skip onboarding + login and go directly to the app.
  - After login, do not show login/onboarding again on app reopen until explicit logout.
  - Ensure only one navigation happens during initial startup.

- [ ] Test manually (fresh install / relaunch / logout) and verify routing behavior.

