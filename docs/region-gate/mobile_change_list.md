# Mobile Change List — Region Entry Gate (Phase 1)

## Context

- **Platform:** Flutter (`mobile-app/`), confirmed via `pubspec.yaml`.
- **Architecture:** Clean Architecture (data / domain / presentation per feature; shared infra in `lib/core/`).
- **State management:** flutter_bloc (BLoC + Cubit), `equatable`.
- **Navigation:** go_router (`lib/app/router/app_router.dart`).
- **DI:** get_it (`lib/core/di/injection.dart`), BLoCs provided app-wide in `main.dart` MultiBlocProvider.
- **HTTP:** Dio via `lib/core/network/dio_client.dart`; base path already `/api`. Backend `GET /api/region/resolve` is live + verified.

## Decisions (confirmed with user)

1. **Local-first, backend enrich.** Derive market instantly from the existing local regex (offline-safe), then call `/region/resolve` to confirm `enabled` / `comingSoonMessage` / `city`.
2. **Enforced gate + onboarding step.** New location step in onboarding AND a splash/redirect-enforced `/location-gate` for any user with no location chosen. Guarded by a new `locationChosen` flag.
3. **Logged-in address → market derivation: DEFERRED** to a follow-up (not in this pass).

## What already exists (reuse, do NOT duplicate)

- `lib/core/widgets/deliver_to_location_sheet.dart` — functional GPS + manual pincode/ZIP entry + IN/US segments + config gating; on apply fires `RegionSetRequested`.
- `lib/core/delivery/presentation/guest_delivery_cubit.dart` — `setIndia()` (6-digit regex) / `setUnitedStatesZip()` (5 or 5+4 regex), persists guest pincode/ZIP.
- `lib/core/region/` — `AppRegion` enum, `RegionRepository` (sync prefs), `RegionBloc`, `CurrencyScope`. Market already flows region → `ProductRemoteDataSource._marketCode` → `?market=` API param.
- `lib/features/config/presentation/bloc/config_bloc.dart` — `ConfigLoaded.config.general.regions[market]` → `enabled` / `comingSoonMessage` gating.
- Onboarding completion: `setOnboardingComplete()` / `hasSeenOnboarding()` (`hasSeenOnboarding` pref key).

## Files to CREATE

### Domain (region resolution)
- `lib/core/region/resolve/domain/entities/region_resolution.dart`
  - `RegionResolution { AppRegion? region; String currencyCode; String city; bool enabled; String comingSoonMessage; }` — pure, no framework imports. `region == null` ⇒ unresolved.
- `lib/core/region/resolve/domain/repositories/region_resolve_repository.dart`
  - `abstract class RegionResolveRepository { Future<RegionResolution> resolve({String? pincode, String? country, String? city}); }`
- `lib/core/region/resolve/domain/usecases/resolve_region_usecase.dart`
  - `ResolveRegionUseCase(this._repo); Future<RegionResolution> call({String? pincode, String? country, String? city})`.

### Data (region resolution)
- `lib/core/region/resolve/data/dto/region_resolution_dto.dart`
  - `RegionResolutionDto.fromJson` (fields: `market`, `currency`, `city`, `enabled`, `comingSoonMessage`); `toEntity()` maps `market` string → `AppRegion?` (`IN`→india, `US`→unitedStates, else null).
- `lib/core/region/resolve/data/datasources/region_resolve_remote_datasource.dart`
  - `RegionResolveRemoteDataSource(DioClient _client)`; `Future<RegionResolutionDto> resolve({pincode, country, city})` → `GET /region/resolve` with non-null query params. Handles `{data:{...}}` wrapper defensively like config datasource.
- `lib/core/region/resolve/data/repositories/region_resolve_repository_impl.dart`
  - `RegionResolveRepositoryImpl(RegionResolveRemoteDataSource _ds)` → `resolve()` returns `dto.toEntity()`.

### Presentation (gate)
- `lib/core/region/resolve/presentation/location_gate_cubit.dart`
  - `LocationGateCubit(ResolveRegionUseCase _resolve)`; calls use case (CA: cubit→use case, never repo). State: `LocationGateState { status (idle/resolving/resolved/error); RegionResolution? resolution; String? error }`. Method `enrich({pincode, country, city})`.
- `lib/core/region/resolve/presentation/location_gate_cubit_state.dart` (if states split out per convention; otherwise colocated).
- `lib/core/region/resolve/presentation/widgets/location_gate_view.dart`
  - Shared full-screen body: heading, GPS button (reuse `resolveGuestLocationFromGpsAndApply`), IN/US segment + manual pincode/ZIP entry. **Local-first:** on submit, persist via existing `GuestDeliveryCubit` + `RegionBloc` immediately; **enrich:** fire `LocationGateCubit.enrich()` to confirm gating; if resolved `enabled == false`, show `comingSoonMessage` and steer to the live region. On success calls an `onChosen` callback.
- `lib/features/auth/presentation/pages/location_gate_page.dart` (or `lib/core/region/resolve/presentation/location_gate_page.dart`)
  - Full-screen `/location-gate` route. Wraps `LocationGateView` in a `BlocProvider<LocationGateCubit>`. `onChosen` → mark `locationChosen`, `context.go('/')`.

### Core
- Extend `RegionRepository` (+impl) with `bool hasChosenLocation()` and `Future<void> markLocationChosen()` — new pref key `locationChosen` (bool). Keeps all region prefs in one owner.

## Files to MODIFY

- `lib/app/router/app_router.dart`
  - Add `GoRoute('/location-gate')`.
  - In top-level `redirect`: if `!sl<RegionRepository>().hasChosenLocation()` and target not in `{/splash, /onboarding, /location-gate, /login, /signup, /forgot-password, /otp-verification}` → redirect to `/location-gate`. (Sync prefs read is safe.)
- `lib/features/auth/presentation/pages/splash_page.dart`
  - After onboarding check: `seen ? (hasChosenLocation ? go('/') : go('/location-gate')) : go('/onboarding')`.
- `lib/features/onboarding/presentation/pages/onboarding_page.dart`
  - Add a final **location step** rendering `LocationGateView`. "Get Started" enabled only after a location is chosen; on finish call `setOnboardingComplete()` + `markLocationChosen()` then `go('/')`. "Skip" no longer bypasses location (either remove skip on the last step or route skip → location step).
- `lib/core/di/injection.dart`
  - Register `RegionResolveRemoteDataSource`, `RegionResolveRepository`, `ResolveRegionUseCase` (all `registerLazySingleton`, matching config/shipping pattern). `LocationGateCubit` created per-route via `BlocProvider` using `sl<ResolveRegionUseCase>()`.

## API calls

- `GET /api/region/resolve?pincode=&country=&city=` → `{ market, currency, city, enabled, comingSoonMessage }`. Already implemented + live-verified. No backend change.

## Permissions

- None new. GPS path reuses the existing `resolveGuestLocationFromGpsAndApply` (location permission already handled there).

## CA compliance notes

- Domain entity/repo-interface/use case are framework-free.
- Cubit depends on `ResolveRegionUseCase` only (not the repository).
- Data layer owns Dio + DTO mapping; presentation never touches Dio.
- Local-first persistence reuses existing `GuestDeliveryCubit`/`RegionBloc` (no new persistence path invented).

## Open risk / flag

- Extracting `LocationGateView` for reuse by both the route page and the onboarding step is justified reuse (avoids duplicating GPS+entry UI). The existing `deliver_to_location_sheet.dart` is left untouched this pass to limit blast radius; a later cleanup could fold it onto the same shared view.
