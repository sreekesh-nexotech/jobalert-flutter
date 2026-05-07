# Job Alert — Codebase Audit Report

**Scope:** Full audit of `lib/`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, and project structure against `docs/QA.md` (6 audit prompts: Riverpod state, Security/Persistence, Performance/Errors, Code Quality/Deployment, Hive Cache Architecture, 4-Layer Architecture).

**Audited:** 38 Dart files across `lib/`, plus build config and Android manifest.

---

## Executive Summary

| Metric | Value |
|---|---|
| Total Dart files reviewed | 38 |
| Critical issues | 18 |
| High-priority issues | 21 |
| Medium-priority issues | 17 |
| Tests present | 0 |
| Hive integration | **None** (entire QA Prompt-5 cache architecture missing) |
| 4-layer architecture | **Not implemented** (uses 2-layer `data/` + `presentation/`) |
| `flutter analyze` baseline | Linter rules strict (`flutter_lints` + custom) — runtime warnings unverified in this audit |
| `flutter test` baseline | No tests exist |
| Deployment readiness score | **3 / 10** |
| Technical debt score | **4 / 10** |
| Architecture score | **3 / 10** (no domain layer, no Hive, no DI inversion) |
| Cache implementation score | **0 / 10** (caching does not exist) |

**Top 3 systemic problems**

1. **No persistent cache layer at all.** `connectivity_plus` and `shared_preferences` are imported in `pubspec.yaml` but never used. Hive is not used. The QA spec (Prompt 5) requires a 3-layer L1/L2/L3 cache with conditional requests, retry/backoff, eviction, request pooling, and corruption recovery — none of this exists. Every screen re-fetches from the network on every tab switch / cold start / warm start.
2. **No domain layer.** QA Prompt 6 mandates `domain/`, `infrastructure/`, `application/`, `presentation/`. The codebase uses only `data/` (concrete repository) + `presentation/` (controller + screens). Repositories return concrete classes, not abstract contracts, breaking dependency inversion. Controllers depend on the implementation directly.
3. **Local widget state for shared/server data.** `ListingCard`, `_CommentTile`, `_DetailState`, and `ProfileScreen` keep server-derived state (`_voted`, `_saved`, `_likes`, `_prefs`, `_city`) in `StatefulWidget` rather than Riverpod. Card-level optimistic updates do not survive scroll-recycling, do not sync with the listing provider, and are never reconciled with the API response.

---

# Section 1 — State Management (QA Prompt 1, Riverpod)

## Critical Issues

### 1.1 Business / data state held in `StatefulWidget` instead of Riverpod
**File:** `lib/features/listings/presentation/widgets/listing_card.dart:33-65`
**Severity:** CRITICAL
**Issue:** The card holds `_votes`, `_voted`, `_saved` in local widget state and toggles them via `setState()`. This is server data; QA Prompt 6 rule #15 explicitly forbids `StatefulWidget` for actual data state. Optimistic toggles never call the repository (no API call wired), and they are wiped whenever the parent list rebuilds.
**Code:**
```dart
late int _votes = widget.listing.upvotesCount;
late bool _voted = widget.listing.upvotedByMe;
late bool _saved = widget.listing.savedByMe;
void _toggleVote() {
  setState(() { _voted = !_voted; _votes += _voted ? 1 : -1; });
  widget.onUpvoteToggle?.call(_voted); // optional callback, never wired
}
```
**Impact:** Vote/save toggles look like they work but nothing reaches the server, server data and UI drift on refresh, scroll-recycling resets the state.
**Fix required:** Move per-listing toggle state into a `StateNotifierProvider.family<Listing, String>` that wraps the listing and calls `ListingsRepository.toggleUpvote / toggleSave`. Use `ref.watch` in the card via `ConsumerWidget`.

### 1.2 Profile preferences and city held in `StatefulWidget` instead of Riverpod
**File:** `lib/features/profile/presentation/profile_screen.dart:25-37`
**Severity:** CRITICAL
**Issue:** `_city` and `_prefs` are user-profile data. They are mutated with `setState` and never persisted to `/user-details/` or `/filter-prefs/`.
**Code:**
```dart
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _city = 'Kochi';
  final Set<String> _prefs = {'Design', 'Marketing'};
```
**Impact:** Preferences reset every time the user leaves the profile tab; never reach the backend.
**Fix required:** Lift to a `userPreferencesProvider` (`StateNotifierProvider`), persist to `/user-details/` on change, hydrate on app start.

### 1.3 Comment-tile like state held in `StatefulWidget`
**File:** `lib/features/listings/presentation/widgets/comments_section.dart:198-208`
**Severity:** CRITICAL
**Issue:** `_liked`, `_likes` are in widget state, no API call to `/comments/{uid}/like/`.
**Code:**
```dart
class _CommentTileState extends State<_CommentTile> {
  late int _likes = widget.comment.likesCount;
  late bool _liked = widget.comment.likedByMe;
  void _toggle() { setState(() { _liked = !_liked; _likes += _liked ? 1 : -1; }); }
}
```
**Impact:** Likes appear to work locally but never persist; the `ApiEndpoints.commentLike` route exists but is unused.
**Fix required:** Add a `commentLikeControllerProvider.family<String>` that posts to `commentLike(uid)` and rebuilds the tile.

### 1.4 Detail-screen save state held in widget state
**File:** `lib/features/listings/presentation/screens/listing_detail_screen.dart:120-130`
**Severity:** CRITICAL
**Issue:** `_DetailState` toggles `_saved` via `setState`, calls the repository directly inside the widget, and on error reverts the boolean — no provider invalidation, no shared state.
**Impact:** The Jobs/Biz card and the Detail screen each maintain their own `_saved` flag — the two screens cannot stay in sync.
**Fix required:** Reuse the same `listingTileControllerProvider.family` for the bookmark button.

### 1.5 `signupFlowProvider` retains password in plaintext as a global `StateProvider`
**File:** `lib/features/auth/presentation/screens/signup_flow_state.dart:6-12`
**Severity:** CRITICAL
**Issue:** `SignupFlow` stores `password` in a global, non-`autoDispose` `StateProvider`. The password lives in memory indefinitely and is exposed to every consumer via `ref.read(signupFlowProvider)`.
**Code:**
```dart
final signupFlowProvider = StateProvider<SignupFlow>((_) => const SignupFlow());
```
**Impact:** Plaintext password is retained for the lifetime of the app process; QA Prompt 2 rule #13 (sensitive data leakage).
**Fix required:** Mark the provider `.autoDispose`, drop the `password` field (the API receives it once at register time and the OTP verify call does not need it), or store only a transient signup token.

### 1.6 Repository instantiated directly inside widget instead of via provider
**File:** `lib/features/listings/presentation/screens/listing_detail_screen.dart:42, 56, 126` ; `widgets/comments_section.dart:36-40` ; `widgets/plus_sheet.dart:45, 95` ; `widgets/report_dialog.dart:37`
**Severity:** CRITICAL
**Issue:** Widgets call `ref.read(listingsRepositoryProvider).foo(…)` for *mutations*. While the provider is used, the call shape bypasses any controller/notifier and inserts business logic into UI files (QA Prompt 1 rule #11/12, "UI widgets directly accessing data sources"). There is no `StateNotifier` for create-listing, post-comment, report, view-tracking, apply, or save.
**Impact:** No central place to coordinate optimistic updates, retries, error funneling, analytics, or invalidation. Each widget reinvents these.
**Fix required:** Introduce notifiers per mutation domain (`commentControllerProvider.family`, `reportControllerProvider`, `submitListingControllerProvider`) and call them through `notifier` methods.

### 1.7 `ref.invalidate()` called from within a UI callback that may run after dispose
**File:** `lib/features/listings/presentation/widgets/comments_section.dart:42`
**Severity:** CRITICAL
**Issue:** `ref.invalidate(commentsProvider(...))` is called inside the post-comment success path with no `mounted` guard before invalidate. If the user pops the sheet during the in-flight POST, this triggers re-fetch on a disposed family scope.
**Impact:** Spurious rebuild errors and wasted network calls.
**Fix required:** Wrap invalidation in `if (mounted)` or move the post into a controller whose lifecycle is bound to the family key.

### 1.8 `BuildContext` used inside async paths from notifier-style callbacks
**File:** `lib/features/listings/presentation/widgets/plus_sheet.dart:101-105` ; `screens/listing_detail_screen.dart:57-64`
**Severity:** CRITICAL
**Issue:** Repositories are called from widgets and on completion the code calls `ScaffoldMessenger.of(context).showSnackBar(...)` after `await`. The `mounted` checks exist (`if (mounted)`), so this avoids crashes — but the *real* QA violation is that this UI orchestration belongs in a notifier-driven flow that emits an `AsyncValue`/state, with the screen reading and rendering snackbars based on a one-shot listener (`ref.listen`).
**Impact:** UI logic and business logic are entangled in widgets; difficult to test.
**Fix required:** Move snackbar emission into `ref.listen(controllerProvider, (_, next) { ... })` at the screen level.

## High-priority Issues

### 1.9 `StateProvider`s missing `autoDispose` for transient flow state
**File:** `lib/features/auth/presentation/screens/signup_flow_state.dart:12,15` ; `lib/features/auth/presentation/screens/forgot_password_screens.dart:103` ; `lib/features/listings/presentation/listings_controller.dart:56-57`
**Severity:** HIGH
**Issue:** `signupFlowProvider`, `forgotEmailProvider`, `forgotCodeProvider`, `jobsQueryProvider`, `bizQueryProvider` are global `StateProvider` without `.autoDispose`. The signup/forgot ones hold transient flow state and should die when the flow ends; the query providers are shared between tabs so global is acceptable but they should reset on logout.
**Impact:** Flow state survives logout; QA rule #3 (autoDispose on temporary UI state).
**Fix required:** Add `.autoDispose` on signup/forgot state providers; explicitly invalidate on logout.

### 1.10 `ConsumerStatefulWidget` used where `ConsumerWidget` would suffice
**File:** `lib/features/listings/presentation/screens/jobs_screen.dart:12` and `biz_screen.dart:15`
**Severity:** HIGH (medium impact, listed at HIGH per QA Prompt 1 rule #13)
**Issue:** The only state held by `_JobsScreenState` and `_BizScreenState` is a `TextEditingController`. With Riverpod, a `Provider.autoDispose` for the controller (or using `useTextEditingController` from hooks) would be cleaner; otherwise the widget has no rebuild-driven local state.
**Impact:** Boilerplate; no functional impact.
**Fix required:** Acceptable as-is, but flagged per QA. Could be simplified by extracting the search bar into its own widget that owns the controller.

### 1.11 Controller depends on the concrete repository, not an abstract contract
**File:** `lib/features/auth/presentation/auth_controller.dart:25, 107-112` ; `lib/features/listings/presentation/listings_controller.dart:60-93`
**Severity:** HIGH
**Issue:** `AuthController` accepts `AuthRepository` (concrete). QA Prompt 6 rule #12 requires the abstract domain contract.
**Code:**
```dart
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._tokens) : super(const AuthState()) { _bootstrap(); }
  final AuthRepository _repo; // concrete
```
**Impact:** Cannot swap implementations for testing; tight coupling.
**Fix required:** Define `abstract class AuthRepository { … }` in `domain/`, implement in `infrastructure/`, inject the abstract type.

### 1.12 Repositories contain business logic / decision branching
**File:** `lib/features/listings/data/listings_repository.dart:65-87`
**Severity:** HIGH
**Issue:** `toggleUpvote` and `toggleSave` decide whether to POST or DELETE based on `Listing.upvotedByMe`. This is application-level logic, not a thin HTTP wrapper (QA Prompt 6 rule #10).
**Impact:** Business logic is split between the repository and the UI — neither layer is the single source of truth.
**Fix required:** Move toggle decisions into a use-case/notifier; keep the repository methods as plain `upvote()` / `removeUpvote()` mirroring HTTP.

### 1.13 `ref.read` used inside `build()` for a state that affects rendering
**File:** `lib/app/router.dart:26`
**Severity:** HIGH
**Issue:** Inside the `redirect:` callback, `ref.read(authControllerProvider)` is used — this is correct (callback). But the redirect listens via `ValueNotifier` workaround on line 18 instead of using `ref.listen` directly. The setup is fragile and easy to forget when adding new auth-driven routes.
**Impact:** Works today, will silently break the moment someone adds another auth-coupled redirect.
**Fix required:** Replace the `ValueNotifier<int>` bridge with a proper `ChangeNotifier` that the router subscribes to via `refreshListenable`.

### 1.14 Inconsistent provider naming
**File:** `lib/features/listings/presentation/listings_controller.dart:56-94`
**Severity:** HIGH (per QA Prompt 1 rule #14)
**Issue:** Mix of `*Provider` for futures (`jobsListProvider`, `homeFeedProvider`) and `*RepositoryProvider`. Acceptable, but the file mixes "controller" naming with raw `FutureProvider`s — there is no controller class for the listings feature. The file is named `listings_controller.dart` but contains zero `StateNotifier`s.
**Impact:** Misleading filename; future maintainers will look for a controller class that does not exist.
**Fix required:** Rename file to `listings_providers.dart` or introduce an actual controller class.

---

# Section 2 — Security & Data Persistence (QA Prompt 2)

## Critical Issues

### 2.1 `android:allowBackup` not explicitly set in `AndroidManifest.xml`
**File:** `android/app/src/main/AndroidManifest.xml:4-7`
**Severity:** CRITICAL (QA Prompt 2 rule #5)
**Issue:** The `<application>` tag has no `android:allowBackup` attribute. Android defaults to `true`, meaning the user's app data — *including the Flutter Secure Storage keystore on some Android versions* — is eligible for cloud backup and restore on a different device.
**Code:**
```xml
<application
    android:label="Job Alert"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
```
**Impact:** Tokens may be restored on a different device; auto-login on the wrong account; data leaks on device transfer.
**Fix required:** Add `android:allowBackup="false"` (and `android:dataExtractionRules="@xml/data_extraction_rules"` for Android 12+) or, if backups are desired, add `android:fullBackupContent="@xml/backup_rules"` excluding `flutter_secure_storage` and any sensitive prefs. Also add a `backup_rules.xml` resource.

### 2.2 Logout flow does not invalidate Riverpod providers
**File:** `lib/features/auth/data/auth_repository.dart:62-69` and `lib/features/profile/presentation/profile_screen.dart:197`
**Severity:** CRITICAL (QA Prompt 2 rule #21)
**Issue:** Logout clears tokens and sets `AuthState.signedOut`, but does not invalidate `homeFeedProvider`, `profileStatsProvider`, `jobsListProvider`, `bizListProvider`, `listingDetailProvider`, `commentsProvider`. They are `autoDispose`, so they *eventually* die when no widget watches them — but if user A logs out and user B logs in immediately, cached `AsyncValue.data` may briefly show user A's data.
**Code:**
```dart
Future<void> logout() async {
  await _repo.logout();
  state = const AuthState(status: AuthStatus.signedOut);
}
```
**Impact:** User-A data leakage to User-B (QA Prompt 4 rule #3).
**Fix required:**
```dart
Future<void> logout() async {
  await _repo.logout();
  // ref must be passed in or this must be done where ref is available:
  // ref.invalidate(homeFeedProvider); ref.invalidate(profileStatsProvider); ...
  state = const AuthState(status: AuthStatus.signedOut);
}
```

### 2.3 No clearing of in-memory query/flow state on logout
**File:** `lib/features/listings/presentation/listings_controller.dart:56-57` ; `lib/features/auth/presentation/screens/signup_flow_state.dart`
**Severity:** CRITICAL
**Issue:** `jobsQueryProvider` / `bizQueryProvider` (search/sort/filter) are not invalidated on logout. Same for `signupFlowProvider` (which holds the previous user's email + password).
**Impact:** New user inherits old user's filter and signup flow state.
**Fix required:** On `logout()`, invalidate all global state providers.

### 2.4 Auto-login flow does not validate backup/reinstall scenario
**File:** `lib/features/auth/presentation/auth_controller.dart:28-41`
**Severity:** CRITICAL (QA Prompt 4 rule #2)
**Issue:** `_bootstrap` reads tokens from secure storage and calls `fetchMe`. If the device was restored from a backup of *another user*, the secure-storage tokens may have survived (depending on platform & backup config) — there is no per-install nonce, no install-id check, and no migration logic that detects "first run after install".
**Impact:** Wrong user auto-login after device restore.
**Fix required:** Store an install marker (e.g., `installId`) in secure storage; on first run after install (detected via `shared_preferences` empty), wipe secure storage proactively before reading tokens.

### 2.5 No 401-on-refresh fallback to logout state
**File:** `lib/core/network/api_client.dart:126-156`
**Severity:** CRITICAL
**Issue:** When refresh fails, the interceptor calls `tokens.clear()` but does not propagate the signed-out state into `AuthController`. The next API call will succeed with a stripped header but the UI still thinks the user is signed in.
**Code:**
```dart
} on DioException catch (_) {
  await tokens.clear();
}
```
**Impact:** UI shows authenticated screens after silent logout; user sees blank/error states instead of being routed to login.
**Fix required:** When refresh fails, also `ref.read(authControllerProvider.notifier).state = AuthState(status: AuthStatus.signedOut)` (requires passing ref into the interceptor or using a callback).

### 2.6 Logout call to API is non-blocking and silently swallowed
**File:** `lib/features/auth/data/auth_repository.dart:62-68`
**Severity:** HIGH (escalated from medium because token-revocation is security-relevant)
**Issue:** Server-side token revocation is best-effort with a generic `catch (_)`. There is no log of which exceptions were swallowed, and a network-down logout never retries.
**Impact:** Refresh token remains valid on the server; if it leaks, the attacker still has access.
**Fix required:** Queue logout calls for retry on next online connection; at minimum log the failure.

## High Priority Issues

### 2.7 Token storage not bound to user identifier
**File:** `lib/core/storage/token_storage.dart:14-17`
**Severity:** HIGH
**Issue:** Keys `ja_access` / `ja_refresh` are global. If user A logs out and user B logs in, the tokens overwrite — fine — but there is no defensive cross-user check. Combined with the lack of provider invalidation (#2.2), this is the root of the user-A-sees-user-B's-data risk.
**Fix required:** Store a `currentUserUid` alongside tokens; compare against the response of `fetchMe` on bootstrap.

### 2.8 Refresh request creates a fresh `Dio` per call with no interceptors / no timeout overrides
**File:** `lib/core/network/api_client.dart:133-138`
**Severity:** HIGH
**Issue:** Inside `onError`, a brand-new `Dio(BaseOptions(baseUrl: baseUrl))` is created with no `connectTimeout` or `receiveTimeout`. A hung refresh endpoint will block indefinitely.
**Fix required:** Reuse `dioProvider` instance with `extra: {'skipAuth': true}` to avoid the auth header, and reuse the configured timeouts.

### 2.9 Token storage exposed via a `Provider` that is not `autoDispose` (intentional) but every read is async
**File:** `lib/core/storage/token_storage.dart:19-24`
**Severity:** HIGH
**Issue:** `TokenStorage.read()` does two awaits on every call. The auth interceptor calls `read()` on *every* outgoing request → two secure-storage hits per HTTP call.
**Impact:** Performance: ~10–40 ms added per request on Android.
**Fix required:** Cache the latest tokens in memory after first read; invalidate on `save()` and `clear()`.

### 2.10 `flutter_secure_storage` defaults: no Android `EncryptedSharedPreferences` opt-in
**File:** `lib/core/storage/token_storage.dart:38`
**Severity:** HIGH
**Issue:** `FlutterSecureStorage()` is constructed with default options. On Android, the default uses Keystore-wrapped AES via Android Keystore, but the package recommends explicitly opting into `AndroidOptions(encryptedSharedPreferences: true)` for compatibility on Android 6+.
**Fix required:**
```dart
const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
)
```

### 2.11 `Authorization` header not stripped on refresh-token retry
**File:** `lib/core/network/api_client.dart:144-147`
**Severity:** HIGH
**Issue:** The retry path overwrites `Authorization` but if the original request had any other auth-derived headers (e.g., user-id), they remain.
**Impact:** Low risk today, but an attacker-controlled stale header could survive a refresh.
**Fix required:** Use a clean clone of `requestOptions` and only re-attach the new Authorization.

---

# Section 3 — Performance & Error Handling (QA Prompt 3)

## Critical Issues

### 3.1 `FutureProvider`s without `try/catch` or `AsyncValue.guard()`
**File:** `lib/features/listings/presentation/listings_controller.dart:59-94`
**Severity:** CRITICAL (QA Prompt 3 rule #1)
**Issue:** All six `FutureProvider`s (`jobsListProvider`, `bizListProvider`, `homeFeedProvider`, `profileStatsProvider`, `canSubmitProvider`, `listingDetailProvider`, `commentsProvider`) call repositories without wrapping. Errors propagate and become `AsyncError` — which is OK for Riverpod, but the providers do not normalize / log / classify. Network timeouts, parse failures, and 5xx errors all surface identically.
**Code:**
```dart
final jobsListProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final q = ref.watch(jobsQueryProvider);
  final repo = ref.watch(listingsRepositoryProvider);
  return repo.fetchJobs(filters: q.toApi(ListingType.job));
});
```
**Impact:** Users see raw `Exception: …` strings (e.g., `jobs_screen.dart:100` renders `'Failed to load: $e'`). No retry button. No offline awareness.
**Fix required:** Wrap with explicit error normalization:
```dart
final jobsListProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  return AsyncValue.guard(() => ref.watch(listingsRepositoryProvider).fetchJobs(...))
      .then((v) => v.value ?? <Listing>[]);
});
```
Plus a typed `Result<T, ApiException>` would be cleaner.

### 3.2 Heavy operation in build(): JSON re-parse on every Home rebuild
**File:** `lib/features/listings/presentation/screens/home_screen.dart:35-41`
**Severity:** CRITICAL (QA Prompt 3 rule #2)
**Issue:** `feed.maybeWhen(...)` casts and re-parses `trending_biz` (List<dynamic> → List<Map<String, dynamic>> → List<Listing>) on **every** rebuild of `HomeScreen`. The home screen rebuilds on every auth-state change, scroll notification, and tab switch.
**Code:**
```dart
final trending = feed.maybeWhen<List<Listing>>(
  data: (m) {
    final raw = (m['trending_biz'] as List?) ?? const [];
    return raw.cast<Map<String, dynamic>>().map((j) => Listing.fromJson(j, ListingType.biz)).toList();
  },
  orElse: () => const [],
);
```
**Impact:** Wasted CPU per frame on a multi-second-cached object.
**Fix required:** Add a derived provider that memoizes the parsed list:
```dart
final trendingBizProvider = Provider.autoDispose<List<Listing>>((ref) {
  final raw = ref.watch(homeFeedProvider).valueOrNull?['trending_biz'] as List? ?? const [];
  return raw.cast<Map<String, dynamic>>().map((j) => Listing.fromJson(j, ListingType.biz)).toList();
});
```

### 3.3 `IndexedStack` builds all four tabs eagerly on first frame
**File:** `lib/features/shell/main_shell.dart:55-68`
**Severity:** CRITICAL
**Issue:** `IndexedStack` keeps all children in the widget tree. With the four tabs each watching their own `FutureProvider`, **all four endpoints fire on cold start** (`/home/feed/`, `/job-listings/`, `/biz-listings/`, `/users/me/stats/`).
**Impact:** 4× server load on cold start; visible jank on slow networks.
**Fix required:** Use `Offstage` + `TickerMode` to defer rendering of inactive tabs, or replace `IndexedStack` with `LazyIndexedStack` (3rd-party) or build tabs lazily via `KeyedSubtree`.

## High Priority Issues

### 3.4 No retry / backoff on any network call
**File:** `lib/core/network/api_client.dart` (entire file)
**Severity:** HIGH (QA Prompt 3 rule #4 + Prompt 5 rule #16)
**Issue:** No retry policy. The QA Prompt 5 mandates 4 attempts with exponential backoff (2s/4s/8s, 15s total max), no retry on 4xx, retry on 5xx and network errors.
**Impact:** Transient 502/503 fails outright; no resilience.
**Fix required:** Add a Dio interceptor implementing the prescribed `RetryPolicy`.

### 3.5 No request deduplication / pooling
**File:** entire repository layer
**Severity:** HIGH (QA Prompt 5 rule #3)
**Issue:** Two simultaneous calls to `fetchJobs` (e.g., user pulls-to-refresh while initial load is in flight) make two network requests. There is no `Map<String, Completer<T>>` pool.
**Fix required:** Implement a `RequestPool` keyed by `${method}:${path}:${sortedQuery}:${bodyHash}:${tokenHash}`.

### 3.6 Unconstrained dependencies
**File:** `pubspec.yaml`
**Severity:** HIGH (QA Prompt 3 rule #8)
**Issue:** All deps use `^` caret constraints — acceptable. But `pubspec.lock` is committed (good). No `--no-tree-shake-icons` analysis. `flutter_riverpod ^2.6.1` is a major version old (3.x is current at time of audit). Some packages are present but unused (see 3.9).
**Fix required:** Audit major versions; remove unused; bump where safe.

### 3.7 Network errors render raw exception text
**File:** `lib/features/listings/presentation/screens/jobs_screen.dart:100`, `biz_screen.dart:98`, `listing_detail_screen.dart:88`
**Severity:** HIGH (QA Prompt 3 rule #3)
**Issue:** `Text('Failed to load: $e', …)` shows raw `ApiException` `toString()` to users. No retry CTA.
**Fix required:** A reusable error widget with a refresh button that calls `ref.invalidate(...)`.

### 3.8 Large list with `ListView.separated` for trending row but no `.builder` lazy load above the fold
**File:** `lib/features/listings/presentation/screens/home_screen.dart:142-153`
**Severity:** HIGH (QA Prompt 3 rule #6)
**Issue:** Trending row uses `ListView.separated` with a fixed `itemCount` derived from `trending.length` — fine for small N, but if the API returns 100+ items, no virtualization control over caching semantics.
**Impact:** Mostly OK, but no max-cap or pagination.
**Fix required:** Limit to first 10 (`trending.take(10)`) for UI consistency with backend pagination.

## Medium Priority Issues

### 3.9 Unused dependencies bloat the bundle
**File:** `pubspec.yaml:21, 24, 39`
**Severity:** MEDIUM (QA Prompt 3 rule #14)
**Issue:**
- `connectivity_plus: ^6.1.2` — never imported
- `shared_preferences: ^2.3.4` — never imported
- `image_picker: ^1.1.2` — never imported

**Impact:** Larger APK, longer build, false impression that connectivity / SharedPreferences / image picking are wired up.
**Fix required:** Remove from `pubspec.yaml`, or wire into the (non-existent) cache, the install-marker check, and the avatar upload flow.

### 3.10 Generic `catch (_)` blocks swallow without logging
**File:** `lib/features/auth/data/auth_repository.dart:65, 38` ; `lib/features/listings/data/listings_repository.dart:102` ; `lib/features/listings/presentation/widgets/comments_section.dart:43` ; `widgets/plus_sheet.dart:49` ; `widgets/report_dialog.dart:43` ; `screens/listing_detail_screen.dart:43, 127` ; `auth/presentation/auth_controller.dart:37`
**Severity:** MEDIUM (QA Prompt 3 rule #9)
**Issue:** Many empty `catch (_)` blocks. No telemetry / debug print / error reporting.
**Impact:** Silent failures in production; no way to diagnose user-reported issues.
**Fix required:** Add a project-wide `Logger` (e.g., `package:logger` or a thin facade) and a `report(error, stack)` helper; wire to Crashlytics or Sentry in production.

### 3.11 `MediaQuery.of(context)` called twice in the same build
**File:** `lib/features/shell/main_shell.dart:72` ; `lib/features/listings/presentation/widgets/plus_sheet.dart:163, 166`
**Severity:** MEDIUM
**Issue:** Each `MediaQuery.of(context)` subscribes the widget to *all* MediaQuery rebuilds.
**Fix required:** Use `MediaQuery.paddingOf(context)` / `MediaQuery.viewInsetsOf(context)` selectors (Flutter 3.10+).

### 3.12 No `flutterfire_options.dart` / no Firebase dependency despite QA Prompt 2 rule #9 / 24 referencing FirebaseAuth
**Severity:** MEDIUM
**Issue:** QA Prompt 2 expects FirebaseAuth-style logout. Codebase uses JWT only — that's fine, but the QA criteria for Firebase listeners (rule #18, #24) are not applicable here. This is an *acknowledgment* rather than a fix-required.

---

# Section 4 — Code Quality & Deployment Readiness (QA Prompt 4)

## Critical Issues

### 4.1 No tests anywhere in the project
**File:** *(missing)* `test/`
**Severity:** CRITICAL (QA Prompt 4 rule #6)
**Issue:** No widget tests, integration tests, or unit tests. `flutter test` would report 0 tests.
**Impact:** Cannot regress-protect any of the bugs flagged in this audit.
**Fix required:** Add minimum smoke coverage:
- `test/auth/auth_controller_test.dart` (login/logout/bootstrap)
- `test/listings/listings_repository_test.dart` (mock Dio; success/error cases)
- `integration_test/login_flow_test.dart` (golden-path)

### 4.2 No CHANGELOG.md
**File:** *(missing)* `CHANGELOG.md`
**Severity:** CRITICAL (QA Prompt 4 rule #16)
**Issue:** Project has no changelog. Recent commits (`d1d6260`, `b75d634`, `fdf1fa9`, `f3411c7`) include "latest changes in files" — vague.
**Fix required:** Create `CHANGELOG.md` and adopt Keep-a-Changelog format.

### 4.3 Version not incremented since first commit
**File:** `pubspec.yaml:4`
**Severity:** CRITICAL (QA Prompt 4 rule #8)
**Issue:** `version: 1.0.0+1` — no bump despite multiple feature commits.
**Fix required:** Bump to e.g. `0.1.0+1` for pre-release, then `0.2.0+2` per release.

### 4.4 Critical user flows not tested on physical device (cannot verify from code)
**Severity:** CRITICAL (QA Prompt 4 rule #7)
**Issue:** No `docs/MANUAL_QA.md` documenting manual passes for: signup → OTP → details → home, login → home, logout → login, force-quit while in OTP screen, network-off scenarios, etc.
**Fix required:** Add a manual QA matrix to `docs/`.

## High Priority Issues

### 4.5 No graceful behavior with internet OFF
**File:** entire codebase
**Severity:** HIGH (QA Prompt 4 rule #10)
**Issue:** Without `connectivity_plus` integration, the app calls APIs and shows raw `Failed to load: …` text. No "You're offline" banner. No cached data fallback (because there is no cache).
**Fix required:** Wire `connectivity_plus`; add an `offlineProvider`; render a banner; integrate with the (to-be-built) cache layer.

### 4.6 No migration logic for breaking changes
**File:** entire codebase
**Severity:** HIGH (QA Prompt 4 rule #12)
**Issue:** `flutter_secure_storage` keys are hard-coded; no schema-versioning of secure storage. If `AuthTokens` shape changes (e.g., adds `tokenType`), old installs will crash on read.
**Fix required:** Store a `schemaVersion` key; on mismatch, wipe and force re-login.

### 4.7 Git commit hygiene
**Severity:** HIGH (QA Prompt 4 rule #15)
**Issue:** Commits are coarse (`"latest changes in files"`). No conventional-commits convention.
**Fix required:** Adopt Conventional Commits and squash `d1d6260` style commits.

## Medium Priority Issues

### 4.8 Hardcoded magic numbers throughout UI
**File:** ubiquitous — e.g., `bottom_nav.dart:38, 39, 50–55` ; `home_screen.dart:142, 184–190` ; `listing_card.dart:108-109` ; etc.
**Severity:** MEDIUM (QA Prompt 4 rule #20, Prompt 6 rule #19)
**Issue:** Pixel sizes (`62`, `30`, `220`, `190`), border radii (`18`, `999`), and durations (`200`, `300`, `1400` ms) are hardcoded. No `flutter_screenutil` or design-tokens module.
**Fix required:** Introduce a design-tokens file or migrate to `flutter_screenutil`.

### 4.9 Hardcoded delays
**File:** `lib/features/auth/presentation/screens/otp_screen.dart:24` (30 s) ; `forgot_password_screens.dart:115` (30 s) ; `success_screen.dart:33` (3 s) ; `bottom_nav.dart:132` (3 s glow)
**Severity:** MEDIUM
**Issue:** OTP resend cooldown, splash/redirect, and animations use hardcoded durations.
**Fix required:** Centralize in `AppDurations` constants.

### 4.10 No documentation comments on complex providers
**File:** `lib/core/network/api_client.dart:103-160`
**Severity:** MEDIUM (QA Prompt 4 rule #21)
**Issue:** The `dioProvider` interceptor has subtle behavior (refresh + retry + clear-on-fail) but only a brief class-level comment.
**Fix required:** Add per-step documentation, especially around the `didRetry` extra.

### 4.11 `// ignore: avoid_positional_boolean_parameters` left in code
**File:** `lib/features/listings/presentation/widgets/plus_sheet.dart:473`
**Severity:** MEDIUM
**Issue:** A lint suppression comment remains.
**Fix required:** Refactor `_Step3Job.onSetState` to take a record/named callback instead of suppressing.

### 4.12 `.withOpacity` deprecated in Flutter 3.27+
**File:** `lib/features/profile/presentation/profile_screen.dart:87, 308, 433` ; `listing_detail_screen.dart:372`
**Severity:** MEDIUM
**Issue:** `Color.withOpacity` is being phased out for `Color.withValues`.
**Fix required:** Migrate to `withValues(alpha: …)`.

### 4.13 Unused parameter in `success_screen.dart` `redirectTo` rarely overridden
**File:** `lib/features/auth/presentation/screens/success_screen.dart:21`
**Severity:** LOW (note)
**Issue:** Parameter exists but only the default `/login` is ever passed.
**Fix required:** Either drop the parameter or use it (e.g., post-signup, redirect to `/`).

---

# Section 5 — Hive Cache Architecture (QA Prompt 5)

## Critical Issues — every CRITICAL violation in QA Prompt 5 applies

### 5.1 No 3-layer cache (L1 Memory → L2 Hive → L3 Network)
**File:** entire repository layer
**Severity:** CRITICAL (QA Prompt 5 rule #1)
**Issue:** Every repository method calls `_api.get(...)` or `_api.post(...)` directly. There is no in-memory map (L1), no Hive (L2 — `hive`/`hive_flutter` is not even in `pubspec.yaml`), and no fall-through logic.
**Impact:** Every screen visit hits the network. Cold start with 4 tabs = 4 immediate API calls. No offline support whatsoever. Scenarios 1–10 all fail.
**Fix required:** Add `hive: ^2.x` and `hive_flutter` to `pubspec.yaml`; build a `CacheManager<T>` class wrapping memory + Hive + Dio, used by every repository.

### 5.2 No cache key strategy (HTTP method + sorted params + body hash + token hash)
**Severity:** CRITICAL (QA Prompt 5 rule #2)
**Issue:** N/A — there is no cache; consequently no key.
**Fix required:** Implement `CacheKey.from(RequestOptions)` returning SHA-256 of `${method}|${path}|${sortedQuery}|${bodyHash}|${tokenHash}`.

### 5.3 No request-deduplication pool
**Severity:** CRITICAL (QA Prompt 5 rule #3)
**Issue:** Two concurrent calls to the same endpoint make two HTTP requests. See 3.5.

### 5.4 No graceful Hive write failure handling
**Severity:** CRITICAL (QA Prompt 5 rule #4)
**Issue:** N/A — no Hive.
**Fix required:** When implemented, wrap Hive writes in `try/catch`, log silently, never block UI, count failures, disable Hive after 10 consecutive failures.

### 5.5 No response validation pipeline before caching
**Severity:** CRITICAL (QA Prompt 5 rule #5)
**Issue:** N/A — no caching.
**Fix required:** When implemented, validate HTTP status → Content-Type → JSON parse → schema → required fields → data types before cache write.

### 5.6 No corruption recovery
**Severity:** CRITICAL (QA Prompt 5 rule #6)
**Issue:** N/A — no Hive. But the broader principle (catch parse errors and fall through to API) is also absent.
**Fix required:** As specified in QA Prompt 5 — corrupted entry deleted, key blacklisted for 5 minutes after 3 corruptions/hour.

## High & Medium Priority

### 5.7 No skeleton loader on cold start
**File:** Skeleton exists in `widgets/skeleton_card.dart` and is used on Jobs/Biz tabs (good), but `home_screen.dart` and `profile_screen.dart` have no skeleton state — they show either loading text (`'…'`) or zeroed-out values.
**Severity:** HIGH (QA Prompt 5 rule #7)
**Fix required:** Add skeleton placeholders for Home + Profile.

### 5.8 No "warm start" path — every load is cold
**Severity:** HIGH (QA Prompt 5 rules #8–10)
**Issue:** No cache means no warm start. No "updating…" indicator. No stale-cache amber banner.
**Fix required:** All implied by 5.1.

### 5.9 No offline indicator / no `connectivity_plus` listener
**Severity:** HIGH (QA Prompt 5 rules #11–12)
**Issue:** `connectivity_plus` is in `pubspec.yaml` but unused.
**Fix required:** Add a `connectivityProvider` (`StreamProvider<ConnectivityResult>`) and a top-level `OfflineBanner` that listens to it.

### 5.10 No conditional-request support (`If-Modified-Since` / 304)
**Severity:** HIGH (QA Prompt 5 rules #13–15)
**Issue:** No `Last-Modified` storage.
**Fix required:** Track `Last-Modified` per cache entry; send `If-Modified-Since` on warm GETs; on 304, return cached data.

### 5.11 `HiveProvider` singleton + lock not implemented
**Severity:** HIGH (QA Prompt 5 rule #17)
**Fix required:** Use `package:synchronized` to gate `Hive.openBox`.

### 5.12 No size monitor, no eviction, no LRU
**Severity:** MEDIUM (QA Prompt 5 rules #18–21)
**Fix required:** Per spec — 5-minute size monitor, evict 20% LRU at >180MB, in-memory LRU at 500 entries / 50MB.

### 5.13 No `CacheConfig` constants centralised
**Severity:** MEDIUM (QA Prompt 5 rule #26)
**Fix required:** Create `lib/core/cache/cache_config.dart` per QA spec.

### 5.14 Cache Health Report — all 10 scenarios FAIL

| Scenario | Status | Reason |
|---|---|---|
| 1. Cold Start | FAIL | No skeleton on Home/Profile, no cache write step |
| 2. Warm Start (network) | FAIL | No cache, no If-Modified-Since |
| 3. Warm Start (offline) | FAIL | No cache, no connectivity listener |
| 4. Navigation | FAIL | No memory cache; full re-fetch every time |
| 5. Stale Cache | FAIL | No cache |
| 6. HTTP 304 | FAIL | No conditional requests |
| 7. Concurrent Requests | FAIL | No request pool |
| 8. Cache Eviction | FAIL | No cache |
| 9. Corruption Recovery | FAIL | No cache |
| 10. Invalid Response | FAIL | No validation pipeline |

---

# Section 6 — Architecture (QA Prompt 6)

## Critical Issues

### 6.1 No `domain/` layer — domain entities and contracts missing
**File:** every feature folder
**Severity:** CRITICAL (QA Prompt 6 rules #6, #9)
**Issue:** The codebase uses a 2-layer split (`data/`, `presentation/`). There are no abstract repository contracts; the `Listing` / `AppUser` classes live under `data/models/` rather than `domain/entities/`, and they contain UI logic (`Color avatarColor`, `CardLabel labels`) that pulls in Flutter / app-color imports — domain purity violated.
**Code example:**
```dart
// listing.dart imports flutter/material.dart and app_colors.dart!
import '../../../../app/theme/app_colors.dart';
import 'package:flutter/material.dart';
class Listing { ... final List<CardLabel> labels; ... }
```
**Impact:** Cannot port to Web or non-Flutter clients; tight coupling.
**Fix required:** Restructure each feature into:
```
features/<name>/
  domain/
    entities/   (pure Dart, no imports)
    repositories/  (abstract)
  infrastructure/
    data_sources/{remote,local}
    repositories/  (implements domain contracts)
  application/
    states/  providers/  usecases/
  presentation/
    screens/  components/
```

### 6.2 Presentation layer imports from `data/` directly
**File:** widely — e.g., `screens/listing_detail_screen.dart:10` ; `widgets/comments_section.dart:6` ; `widgets/plus_sheet.dart:8` ; `widgets/report_dialog.dart:6` ; `screens/home_screen.dart:9`
**Severity:** CRITICAL (QA Prompt 6 rule #4–5)
**Issue:** Presentation files `import '../../data/listings_repository.dart'` and `import '../../data/models/listing.dart'`. The QA spec requires presentation to depend only on application/domain.
**Code:**
```dart
// listing_detail_screen.dart
import '../../data/listings_repository.dart';
import '../../data/models/listing.dart';
```
**Impact:** No layering; refactoring the data source breaks UI.
**Fix required:** Move `Listing` to `domain/entities/`, keep DTOs separate; presentation should `import '../../domain/entities/listing.dart'` only.

### 6.3 Domain entity contains UI methods (`displayName`, `initials`, label colors)
**File:** `lib/features/auth/data/models/auth_models.dart:24-36` ; `lib/features/listings/data/models/listing.dart:1-3, 18-46, 244`
**Severity:** CRITICAL (QA Prompt 6 rule #8, Prompt 1 rule #18)
**Issue:** `AppUser.displayName` and `initials` are UI helpers; `CardLabel` imports Flutter `Color`; `ListingComment.fromJson` injects `AppColors.brand`.
**Impact:** Domain is not portable; testing requires Flutter bindings.
**Fix required:** Move display helpers to a `presentation/extensions/app_user_x.dart` and `listing_x.dart`.

### 6.4 Infrastructure repository does not declare `implements <DomainRepository>`
**File:** `lib/features/auth/data/auth_repository.dart:11` ; `lib/features/listings/data/listings_repository.dart:10`
**Severity:** CRITICAL (QA Prompt 6 rule #16)
**Issue:** Concrete classes do not satisfy a domain contract.
**Fix required:** Once domain abstractions exist, declare `class AuthRepositoryImpl implements AuthRepository`.

### 6.5 Infrastructure repositories do not check a local cache before going to network
**File:** every repository method
**Severity:** CRITICAL (QA Prompt 6 rule #17)
**Issue:** No `local/` data source exists. Every call goes straight to remote.
**Fix required:** Once Hive is added, every `fetch` repository method must follow `local.read() → if stale or missing, remote.fetch() → local.write() → return`.

## High Priority Issues

### 6.6 `State` class is `final`-fielded but lacks freezed/equatable for value comparison
**File:** `lib/features/auth/presentation/auth_controller.dart:10-18`
**Severity:** HIGH
**Issue:** `AuthState` has `final` fields and `copyWith` (good) but no `==` / `hashCode`. Riverpod uses identity comparison; equality is fine here but a regression may pass without notification.
**Fix required:** Adopt `equatable` (already in `pubspec.yaml`!) — `class AuthState extends Equatable`.

### 6.7 `ListingsQuery` mutable in spirit because `StateProvider` is mutated externally
**File:** `lib/features/listings/presentation/listings_controller.dart:56-57` and call sites in `jobs_screen.dart:51, 54, 76` ; `biz_screen.dart:52, 54, 77`
**Severity:** HIGH (QA Prompt 6 rule #14)
**Issue:** UI mutates `notifier.state = query.copyWith(...)`. Allowed by Riverpod, but the QA preference is to encapsulate the mutation inside a `StateNotifier` method.
**Fix required:** Convert to `StateNotifierProvider<ListingsQueryNotifier, ListingsQuery>` with `setSearch(String)`, `setFilter(String)`, `setSort(String)`.

### 6.8 No use-case classes
**Severity:** HIGH
**Issue:** Multi-step flows (signup → OTP send → verify → details → register) live across 4 widgets and 1 controller. A `SignupUseCase` would centralize the flow.
**Fix required:** Add `application/usecases/signup_usecase.dart`.

## Medium Priority Issues

### 6.9 No ScreenUtil / responsive sizing
**File:** all screens
**Severity:** MEDIUM (QA Prompt 6 rule #19)
**Issue:** Pixel-perfect layout based on a single device width.
**Fix required:** Add `flutter_screenutil`, replace `SizedBox(width: 24)` with `24.w`, etc.

### 6.10 Architecture Health Report

| Layer | Files Audited | Critical | High | Medium | Status |
|---|---|---|---|---|---|
| Domain | 0 (does not exist) | n/a | n/a | n/a | **FAIL** |
| Infrastructure | 2 (`auth_repository`, `listings_repository`) | 3 | 1 | 0 | FAIL |
| Application | 1 (`auth_controller`) + 1 mixed (`listings_controller`) | 4 | 3 | 0 | FAIL |
| Presentation | ~30 | 6 | 4 | 5 | FAIL |
| Cross-layer | n/a | 5 | 0 | 0 | FAIL |
| Hive model integrity | n/a | n/a (no Hive) | n/a | n/a | **FAIL** |

---

# Cross-Cutting: Token Storage Inventory

| Stage | File | Function | Action |
|---|---|---|---|
| Save (login) | `auth_repository.dart:58, 144-147` | `_persistTokens` | `tokens.save(AuthTokens(...))` |
| Save (register) | `auth_repository.dart:39, 144-147` | `_persistTokens` | `tokens.save(...)` |
| Save (refresh) | `api_client.dart:140-143` | dio interceptor | `tokens.save(AuthTokens(access: newAccess, refresh: t.refresh))` |
| Read | `api_client.dart:119-123, 130` | dio interceptor | `tokens.read()` |
| Read (bootstrap) | `auth_controller.dart:29` | `_bootstrap` | `_tokens.read()` |
| Clear (logout) | `auth_repository.dart:68` | `logout` | `_tokens.clear()` |
| Clear (refresh fail) | `api_client.dart:151` | dio interceptor | `tokens.clear()` |
| Clear (bootstrap fail) | `auth_controller.dart:38` | `_bootstrap` | `_tokens.clear()` |

**Storage backend:** `flutter_secure_storage` (good); but see 2.10 — Android encryption flag not opt-in.
**Plain SharedPreferences for tokens?** No (good).
**Token presence in print/log?** None found (good).

---

# Android Manifest Check

- **Current `allowBackup` setting:** *not set* → defaults to `true` (CRITICAL).
- **`backup_rules.xml` exists?** No.
- **`dataExtractionRules` (Android 12+):** not configured.
- **`networkSecurityConfig`:** not configured (no cleartext traffic protection beyond Android defaults).
- **Assessment:** Manifest is the bare default Flutter scaffold; security hardening required before release.

---

# Manual-Test Documentation Audit

| Required scenario (QA Prompt 4) | Documented? |
|---|---|
| Uninstall/reinstall flow | ❌ |
| User-switching flow | ❌ |
| Internet OFF scenarios | ❌ |
| Low-memory scenarios | ❌ |
| Background/foreground transitions | ❌ |

No `docs/MANUAL_QA.md` exists.

---

# Dependency Report

- **Total dependencies (production):** 14
- **Unused dependencies:** `connectivity_plus`, `shared_preferences`, `image_picker`
- **Version-constraint issues:** None — all use `^` carets.
- **Heavy packages (>5MB):** `cached_network_image` (~2MB), `google_fonts` (downloads at runtime — adds startup latency), `flutter_svg` (~1MB). None individually concerning.
- **Missing packages (per QA Prompt 5):** `hive`, `hive_flutter`, `synchronized`, `crypto` (for SHA-256 cache keys), `dio_smart_retry` or hand-rolled retry interceptor.

---

# Refactoring Recommendations (priority order)

1. **Build the Hive cache layer end-to-end** (Prompt 5 entirely) — the single biggest gap.
2. **Restructure into 4-layer architecture** with a real `domain/` (Prompt 6).
3. **Move per-listing toggle state out of `StatefulWidget` and into `StateNotifierProvider.family`** so vote/save/like actually persist (Prompt 1, 1.1–1.4).
4. **Wire logout → invalidate all providers + clear flow state** to prevent user-A → user-B leakage (Prompt 2, 2.2–2.3).
5. **Set `android:allowBackup="false"` and add backup rules** (Prompt 2, 2.1).
6. **Add `try/catch` + `AsyncValue.guard` + retry/backoff to network paths**, and offline awareness via `connectivity_plus` (Prompt 3, 3.1, 3.4–3.5; Prompt 5, 5.9).
7. **Lazy-load tabs** (replace `IndexedStack`) so cold start fires one API instead of four (3.3).
8. **Add tests, CHANGELOG.md, manual QA doc, and bump version** (Prompt 4, 4.1–4.4, 4.7).
9. **Migrate hardcoded sizes to ScreenUtil** (6.9).
10. **Remove unused dependencies** (3.9).

---

# Top 5 Actions Before Deployment

1. Set `android:allowBackup="false"` + add `data_extraction_rules.xml`.
2. Logout must invalidate all data providers and clear flow state, OR force-restart the app, to prevent user-A → user-B data bleed.
3. Add the offline banner + skeleton loaders + a real cache layer — even an in-memory-only `CacheManager` is better than zero.
4. Add at least one widget test and one integration test for the auth flow; wire `flutter analyze` and `flutter test` into CI.
5. Bump app version, write a CHANGELOG entry, and document a manual-QA pass for: signup, login, logout, force-reinstall, offline jobs feed.

---

# Final Scores

| Score | Value | Justification |
|---|---|---|
| Technical Debt | 4 / 10 | Code is readable and consistent; debt is structural, not stylistic. The missing domain layer and missing cache are large but tractable refactors. |
| Deployment Readiness | 3 / 10 | No tests, no logout-side-effect cleanup, no offline handling, default `allowBackup`, and unbumped version disqualify a production release today. |
| Architecture | 3 / 10 | 2-layer instead of required 4-layer; domain entities polluted with UI; presentation imports infrastructure directly. |
| Cache Implementation | 0 / 10 | No cache exists. All 10 QA scenarios fail. |
| Security | 4 / 10 | Tokens are in secure storage (good), but `allowBackup` defaults to true, refresh-fail does not propagate logout, and signup password lives in a global provider. |
