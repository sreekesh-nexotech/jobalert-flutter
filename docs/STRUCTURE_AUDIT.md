# Folder Structure Audit — `jobalert-flutter`

Date: 2026-05-07
Scope: `lib/` tree only.
Reference docs:
1. `docs/Folder structure - structure.csv` (project's prescribed scaffold)
2. The 4-layer Clean Architecture spec given by the user
   (Domain → Infrastructure → Application → Presentation).

> No code was changed. This is a structural diff only.

---

## 1. TL;DR

| Question | Answer |
| --- | --- |
| Does `lib/` follow `Folder structure - structure.csv`? | **No — partially.** Top-level `app/`, `core/`, `features/` and `main.dart` exist, but most of the prescribed sub-folders/files are missing, and feature internals diverge from the spec. |
| Does `lib/` follow the Domain / Infrastructure / Application / Presentation layering? | **No.** Features use a flattened `data/` + `presentation/` layout. There is no `domain/`, no `infrastructure/`, no `application/`, and no separation of entities, repository contracts, data sources, states, providers, or use cases. |

The codebase currently sits at a "feature-first, 2-layer" scaffold (data + presentation), which is much shallower than either reference design.

---

## 2. Current `lib/` tree (as on disk)

```
lib/
├─ app/
│  ├─ app.dart
│  ├─ router.dart
│  └─ theme/
│     ├─ app_colors.dart
│     ├─ app_theme.dart
│     └─ app_typography.dart
├─ core/
│  ├─ network/
│  │  ├─ api_client.dart
│  │  ├─ api_endpoints.dart
│  │  └─ api_exception.dart
│  └─ storage/
│     └─ token_storage.dart
├─ features/
│  ├─ auth/
│  │  ├─ data/
│  │  │  ├─ auth_repository.dart
│  │  │  └─ models/auth_models.dart
│  │  └─ presentation/
│  │     ├─ auth_controller.dart
│  │     ├─ screens/{login, signup, otp, details, success, forgot_password, signup_flow_state}.dart
│  │     └─ widgets/auth_widgets.dart
│  ├─ listings/
│  │  ├─ data/
│  │  │  ├─ listings_repository.dart
│  │  │  └─ models/listing.dart
│  │  └─ presentation/
│  │     ├─ listings_controller.dart
│  │     ├─ screens/{home, jobs, biz, listing_detail}.dart
│  │     └─ widgets/{listing_card, comments_section, plus_sheet, report_dialog,
│  │                  skeleton_card, sort_control, _relative_time}.dart
│  ├─ profile/
│  │  └─ presentation/profile_screen.dart
│  └─ shell/
│     ├─ bottom_nav.dart
│     └─ main_shell.dart
└─ main.dart
```

---

## 3. Audit vs. `Folder structure - structure.csv`

Legend: ✅ present · ⚠️ present but located/named differently · ❌ missing

### 3.1 `lib/app/`

| Spec path | Status | Notes |
| --- | --- | --- |
| `app/bootstrap/app_bootstrap.dart` | ❌ | No bootstrap folder. `ProviderScope` is wired inline in `main.dart`. |
| `app/bootstrap/hive_init.dart` | ❌ | Hive is not initialised anywhere. |
| `app/bootstrap/env_loader.dart` | ❌ | No env loader; base URL is hard-coded in `core/network/api_endpoints.dart`. |
| `app/config/env.dart` | ❌ | No env model. |
| `app/config/constants.dart` | ❌ | No central constants module. |
| `app/config/feature_flags.dart` | ❌ | No feature flag layer. |
| `app/router/app_router.dart` | ⚠️ | Router exists as `lib/app/router.dart` (flat), not under `router/` with the spec name. |
| `app/router/guards/` | ❌ | No route guards directory. |
| `app/theme/colors.dart` | ⚠️ | Present as `app_colors.dart` (prefix differs from spec). |
| `app/theme/typography.dart` | ⚠️ | Present as `app_typography.dart`. |
| `app/theme/theme.dart` | ⚠️ | Present as `app_theme.dart`. |
| `app/localization/l10n.dart` | ❌ | No localization layer. |
| `app/localization/arb/` | ❌ | No `.arb` files. |
| `app/monitoring/analytics.dart` | ❌ | No analytics wrapper. |
| `app/monitoring/crash_reporting.dart` | ❌ | No Crashlytics/Sentry hooks. |
| `app/app.dart` | ✅ | Thin `MaterialApp` entry exists. |

### 3.2 `lib/core/`

| Spec path | Status | Notes |
| --- | --- | --- |
| `core/network/api_client.dart` | ✅ | Present. |
| `core/network/endpoints.dart` | ⚠️ | Present as `api_endpoints.dart` (spec name is `endpoints.dart`). |
| `core/network/network_exceptions.dart` | ⚠️ | Present as `api_exception.dart`. |
| `core/storage/hive/boxes.dart` | ❌ | No Hive layer at all. |
| `core/storage/hive/keys.dart` | ❌ | Missing. |
| `core/storage/hive/adapters/` | ❌ | Missing. |
| `core/storage/secure_store.dart` | ⚠️ | Closest match is `token_storage.dart` (single-purpose, not a generic secure store). |
| `core/utils/date_utils.dart` | ❌ | No `core/utils/` folder. (A private `_relative_time.dart` lives inside listings/widgets.) |
| `core/utils/validators.dart` | ❌ | Missing. |
| `core/utils/logger.dart` | ❌ | Missing. |
| `core/widgets/app_button.dart` | ❌ | No design-system widgets folder. |
| `core/widgets/app_card.dart` | ❌ | Missing. |
| `core/widgets/app_text_field.dart` | ❌ | Missing. |
| `core/widgets/navbar.dart` | ⚠️ | Bottom nav exists at `features/shell/bottom_nav.dart` instead of `core/widgets/`. |
| `core/error/failure.dart` | ❌ | No domain failure type. |
| `core/error/error_view.dart` | ❌ | No shared error/empty-state widgets. |

### 3.3 `lib/features/`

The spec prescribes per-feature 4-layer scaffolds (`domain/`, `application/`, `infrastructure/`, `presentation/`). The codebase uses 2 layers (`data/`, `presentation/`).

| Feature | `domain/` | `application/` | `infrastructure/` | `presentation/` | Notes |
| --- | --- | --- | --- | --- | --- |
| `auth` | ❌ | ❌ | ❌ (a `data/` folder exists instead) | ✅ | Repository, DTOs and the `AuthController` (state notifier) all live in `data/` or `presentation/`. |
| `listings` | ❌ | ❌ | ❌ | ✅ | Same shape as `auth`. Riverpod providers (`jobsListProvider`, etc.) live in `presentation/listings_controller.dart`. |
| `profile` | ❌ | ❌ | ❌ | partial | Only a screen is present; no repository/state layer. |
| `shell` | n/a | n/a | n/a | partial | Not in the spec; holds the bottom-nav scaffold. |
| `dashboard` | ❌ | ❌ | ❌ | ❌ | Not implemented (spec lists it). |
| `common/pagination` | ❌ | ❌ | ❌ | ❌ | Not implemented. |
| `common/attachments` | ❌ | ❌ | ❌ | ❌ | Not implemented. |

### 3.4 Top-level

| Spec path | Status | Notes |
| --- | --- | --- |
| `main.dart` | ⚠️ | Present, but it does **not** delegate to `app/bootstrap/app_bootstrap.dart` (the spec wants `main.dart` to be a one-liner that calls bootstrap). |
| `globals.dart` | ❌ (optional) | Not present — fine, since the spec marks it optional. |

---

## 4. Audit vs. the Domain / Infrastructure / Application / Presentation spec

The user-supplied spec:

```
Domain (declare)
  - entities         — data models of each class
  - repositories     — function declarations only

Infrastructure (definition)
  - data_sources
      - remote       — API calls
      - local        — Hive (only if required)
  - repositories     — implementations of domain repository contracts

Application (calling)
  - state            — declared states for the screen
  - providers        — state-management layer

Presentation (displaying)
```

### 4.1 Per-layer findings

**Domain — ❌ Not present.**
- No `entities/` folder anywhere. DTOs (`AppUser`, `Listing`, `ListingComment`, `OtpPurpose`, `Gender`) live under `features/<f>/data/models/` and double as both API DTOs (with `fromJson`) and entities.
- No abstract `repositories/` declarations. The repository classes are concrete-only — there is no interface/abstract base, so the contract and the implementation are the same class.

**Infrastructure — ❌ Not present (as named).**
- No `infrastructure/` folder; the closest analogue is `features/<f>/data/`.
- No `data_sources/remote/` or `data_sources/local/` separation. Each repository (`AuthRepository`, `ListingsRepository`) calls `ApiClient` directly inside repository methods, mixing data-source and repository responsibilities.
- No Hive / local data source. Only `TokenStorage` (in `core/storage/`) plays a "local" role, and it's consumed straight from the repository.
- Repositories are **implementations without a contract** — there is no domain interface they implement.

**Application — ❌ Not present (as named).**
- No `application/` folder. State + providers live in `features/<f>/presentation/<f>_controller.dart`.
- `state` and `providers` are co-located with the UI:
  - `auth_controller.dart` declares `AuthState`, `AuthStatus`, `AuthController`, and the `authControllerProvider` in one file inside `presentation/`.
  - `listings_controller.dart` declares `ListingsQuery` plus several Riverpod providers inside `presentation/`.
- No `usecases/` layer; the controllers call repositories directly.

**Presentation — ✅ Present (the only layer that aligns).**
- `screens/` and `widgets/` subfolders exist for `auth` and `listings` and follow the spec idea.
- `profile/` only has a screen (no widgets folder).
- Note: `presentation/` currently also hosts the controllers/providers that the spec wants under `application/`.

### 4.2 Concrete examples of the divergence

| Spec expectation | Where it lives today |
| --- | --- |
| `features/auth/domain/entities/user.dart` (entity) | `features/auth/data/models/auth_models.dart` (`AppUser` — DTO+entity hybrid). |
| `features/auth/domain/repositories/auth_repository.dart` (abstract) | Does not exist — only the concrete `AuthRepository` exists at `features/auth/data/auth_repository.dart`. |
| `features/auth/infrastructure/data_sources/remote/auth_api.dart` | Inlined inside `AuthRepository` (calls `ApiClient` directly). |
| `features/auth/infrastructure/data_sources/local/auth_local_ds.dart` | Partially covered by `core/storage/token_storage.dart`, used directly by the repository. |
| `features/auth/infrastructure/repositories/auth_repository_impl.dart` | Same file as the "contract" — `features/auth/data/auth_repository.dart` is both. |
| `features/auth/application/states/auth_state.dart` | `features/auth/presentation/auth_controller.dart` (`AuthState` defined inline). |
| `features/auth/application/providers/auth_provider.dart` | `features/auth/presentation/auth_controller.dart` (`authControllerProvider`). |
| `features/auth/application/usecases/login.dart` | Not present — `AuthController.login` calls `AuthRepository.login` directly. |

The same pattern repeats verbatim for `listings/`.

---

## 5. Cross-cutting observations

1. **Provider definitions live next to data classes.** `authRepositoryProvider` is declared at the bottom of `auth_repository.dart`; `listingsRepositoryProvider` likewise. The spec wants providers under `application/providers/`.
2. **No DI / bootstrap module.** `ProviderScope` is configured inline in `main.dart`. There is no `app_bootstrap.dart`, no error hooks, and no place to inject test/mocks overrides — both reference structures call this out as a required file.
3. **`shell/` is an unspec'd feature folder.** `features/shell/{bottom_nav,main_shell}.dart` doesn't appear in either reference; the bottom nav specifically belongs in `core/widgets/navbar.dart` per the CSV.
4. **Theme file naming.** Current `app_colors.dart`/`app_theme.dart`/`app_typography.dart` differ from the spec's `colors.dart`/`theme.dart`/`typography.dart`. Cosmetic, but worth noting.
5. **Missing foundations.** `core/utils/`, `core/widgets/`, `core/error/`, `app/localization/`, `app/monitoring/`, `app/config/`, `app/bootstrap/`, and the entire Hive sub-tree (`core/storage/hive/{boxes,keys,adapters}`) do not exist.
6. **`profile/` is a stub.** Only `profile_screen.dart` exists — no data/state/repository at all.
7. **`dashboard/` feature is not implemented**, although the CSV documents it as a first-class feature.

---

## 6. Verdict

- **CSV scaffold compliance:** roughly **20 %**. The shell (`app/`, `core/`, `features/`, `main.dart`) is in place, but most prescribed sub-folders and almost every supporting file (bootstrap, env, config, monitoring, localization, hive, utils, widgets, error) are absent, and feature internals are flatter than the CSV requires.
- **Domain / Infrastructure / Application / Presentation compliance:** **~25 %**. Only the `presentation/` layer maps cleanly. There is no `domain/`, no `infrastructure/`, no `application/`, no use-case layer, and no separation between data sources and repositories.

If alignment is desired, the highest-leverage next steps (still no code change implied here, just listing them as observations) would be to:

1. Introduce per-feature `domain/{entities,repositories}` and move the abstract contracts there.
2. Split each `data/<f>_repository.dart` into `infrastructure/data_sources/remote/*.dart` + `infrastructure/repositories/<f>_repository_impl.dart`.
3. Move state classes and Riverpod providers from `presentation/*_controller.dart` into `application/{states,providers,usecases}`.
4. Create the missing `app/bootstrap`, `app/config`, `app/localization`, `app/monitoring`, `core/utils`, `core/widgets`, `core/error`, and `core/storage/hive/*` scaffolds the CSV calls for.
5. Relocate `features/shell/bottom_nav.dart` into `core/widgets/navbar.dart` per the CSV.
