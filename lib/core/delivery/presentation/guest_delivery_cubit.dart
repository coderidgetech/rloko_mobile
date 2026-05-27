import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../guest_delivery_location_repository.dart';

class GuestDeliveryState extends Equatable {
  const GuestDeliveryState({
    this.indiaPincode,
    this.indiaCityHint,
    this.usZip,
  });

  final String? indiaPincode;
  final String? indiaCityHint;
  final String? usZip;

  GuestDeliveryState copyWith({
    String? indiaPincode,
    String? indiaCityHint,
    String? usZip,
  }) {
    return GuestDeliveryState(
      indiaPincode: indiaPincode ?? this.indiaPincode,
      indiaCityHint: indiaCityHint ?? this.indiaCityHint,
      usZip: usZip ?? this.usZip,
    );
  }

  @override
  List<Object?> get props => [indiaPincode, indiaCityHint, usZip];
}

class GuestDeliveryCubit extends Cubit<GuestDeliveryState> {
  GuestDeliveryCubit(this._repo) : super(const GuestDeliveryState()) {
    refresh();
  }

  final GuestDeliveryLocationRepository _repo;

  void refresh() {
    emit(GuestDeliveryState(
      indiaPincode: _repo.getIndiaPincode(),
      indiaCityHint: _repo.getIndiaCityHint(),
      usZip: _repo.getUsZip(),
    ));
  }

  /// Returns an error message if invalid, null if ok.
  Future<String?> setIndia(String pin, {String? city}) async {
    final d = pin.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{6}$').hasMatch(d)) {
      return 'Enter a valid 6-digit pincode';
    }
    final ch = city?.trim();
    try {
      await _repo.setIndiaPincode(d, cityHint: (ch != null && ch.isNotEmpty) ? ch : null);
    } catch (_) {
      return "We couldn't save your location. Check storage permissions and try again.";
    }
    refresh();
    return null;
  }

  /// US ZIP: 5 digits (optionally 5+4).
  Future<String?> setUnitedStatesZip(String zip) async {
    final z = zip.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(z)) {
      return 'Enter a valid 5 or 9 digit ZIP';
    }
    try {
      await _repo.setUsZip(z);
    } catch (_) {
      return "We couldn't save your location. Check storage permissions and try again.";
    }
    refresh();
    return null;
  }
}
