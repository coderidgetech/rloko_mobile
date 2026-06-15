import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_region.dart';
import '../domain/usecases/resolve_region_usecase.dart';

part 'location_gate_state.dart';

/// Backend-enrich half of "local-first, backend enrich". The view resolves the
/// market locally (offline-safe) and persists it immediately; this cubit then
/// confirms `enabled` / `comingSoonMessage` / `city` via [ResolveRegionUseCase].
class LocationGateCubit extends Cubit<LocationGateState> {
  LocationGateCubit(this._resolveRegion) : super(const LocationGateState());

  final ResolveRegionUseCase _resolveRegion;

  Future<void> enrich({String? pincode, String? country, String? city}) async {
    // The gate often navigates away (closing this cubit) while enrichment is
    // still in flight — guard every emit against a closed cubit.
    if (isClosed) return;
    emit(state.copyWith(
      status: LocationGateStatus.resolving,
      clearResolved: true,
    ));
    try {
      final result =
          await _resolveRegion(pincode: pincode, country: country, city: city);
      if (isClosed) return;
      if (!result.isResolved) {
        // Server definitively could not map the input — distinct from a
        // transport failure so the view can re-ask vs. proceed best-effort.
        emit(state.copyWith(
          status: LocationGateStatus.unresolved,
          error: 'Enter a valid pincode or ZIP to continue',
        ));
        return;
      }
      emit(state.copyWith(
        status: LocationGateStatus.resolved,
        resolvedRegion: result.region,
        enabled: result.enabled,
        comingSoonMessage: result.comingSoonMessage,
        city: result.city,
      ));
    } catch (_) {
      // Enrichment is best-effort; the local resolution already admitted the user.
      if (isClosed) return;
      emit(state.copyWith(
        status: LocationGateStatus.error,
        error: "Couldn't confirm your region. You can continue anyway.",
      ));
    }
  }

  void reset() => emit(const LocationGateState());
}
