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
cp .env.example .env       # set API_BASE_URL
flutter pub get
flutter run
```

The default `API_BASE_URL` (`http://10.0.2.2:8000/api/v1`) targets a
locally-running [`jobalert-api-drf`](../jobalert-api-drf) on the Android
emulator. For iOS or web, swap `10.0.2.2` for `localhost`.

## Backend

All data and auth flows talk to the `jobalert-api-drf` Django REST
backend. Endpoints live under `/api/v1/`; see `lib/core/network/api_endpoints.dart`.
