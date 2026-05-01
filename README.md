# JobAlert — Flutter App

Mobile client for the JobAlert platform. Discover jobs and business
opportunities, save & upvote listings, post your own, and track your points.

## Stack

- Flutter 3.22+ / Dart 3.4+
- Riverpod for state management
- Dio for networking
- go_router for navigation
- Frappe UI design tokens (Inter variable font)

## Architecture

```
lib/
  app/                    application bootstrap, theme, routing
  core/                   shared primitives (network, storage, utils)
  features/
    auth/                 login, signup, OTP, password reset
    listings/             home, jobs, biz, detail, comments, plus-sheet
    profile/              profile screen, points, preferences
    shell/                main scaffold + bottom nav
```

## Getting started

```bash
flutter pub get
flutter run
```

The app ships pointing at the deployed backend at
`https://jobalertapp.nexogms.com/api/v1`. To target a different
environment (e.g. a local Django server) override it at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## Backend

All data and auth flows talk to the `jobalert-api-drf` Django REST
backend deployed at `https://jobalertapp.nexogms.com`. Endpoints live
under `/api/v1/`; see `lib/core/network/api_endpoints.dart`.
