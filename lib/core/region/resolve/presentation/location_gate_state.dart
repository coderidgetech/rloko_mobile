part of 'location_gate_cubit.dart';

enum LocationGateStatus {
  idle,
  resolving,

  /// Server resolved a market for the input.
  resolved,

  /// Server responded but could not map the input to a supported market.
  unresolved,

  /// Enrichment call threw (network/transport). Best-effort: the local
  /// resolution already admitted the user.
  error,
}

class LocationGateState extends Equatable {
  const LocationGateState({
    this.status = LocationGateStatus.idle,
    this.resolvedRegion,
    this.enabled = true,
    this.comingSoonMessage,
    this.city,
    this.error,
  });

  final LocationGateStatus status;
  final AppRegion? resolvedRegion;
  final bool enabled;
  final String? comingSoonMessage;
  final String? city;
  final String? error;

  bool get isResolving => status == LocationGateStatus.resolving;

  LocationGateState copyWith({
    LocationGateStatus? status,
    AppRegion? resolvedRegion,
    bool? enabled,
    String? comingSoonMessage,
    String? city,
    String? error,
    bool clearError = false,
    bool clearResolved = false,
  }) {
    return LocationGateState(
      status: status ?? this.status,
      resolvedRegion: clearResolved ? null : (resolvedRegion ?? this.resolvedRegion),
      enabled: clearResolved ? true : (enabled ?? this.enabled),
      comingSoonMessage:
          clearResolved ? null : (comingSoonMessage ?? this.comingSoonMessage),
      city: clearResolved ? null : (city ?? this.city),
      error: (clearError || clearResolved) ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, resolvedRegion, enabled, comingSoonMessage, city, error];
}
