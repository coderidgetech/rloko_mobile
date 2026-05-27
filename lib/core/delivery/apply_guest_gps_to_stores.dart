import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../location/guest_delivery_gps.dart';
import '../region/app_region.dart';
import '../region/presentation/region_bloc.dart';
import 'presentation/guest_delivery_cubit.dart';

/// Returns `null` on success, or a user-facing error string.
Future<String?> applyGuestGpsToStores(
  GuestDeliveryCubit cubit,
  RegionBloc regBloc,
  GuestDeliveryGpsSuccess s,
) async {
  try {
    if (s.isIndia) {
      final err = await cubit.setIndia(s.postalCode, city: s.city);
      if (err == null) {
        if (regBloc.state.region != AppRegion.india) {
          regBloc.add(const RegionSetRequested(AppRegion.india));
        }
      }
      return err;
    } else {
      final err = await cubit.setUnitedStatesZip(s.postalCode);
      if (err == null) {
        if (regBloc.state.region != AppRegion.unitedStates) {
          regBloc.add(const RegionSetRequested(AppRegion.unitedStates));
        }
      }
      return err;
    }
  } catch (_) {
    return "We couldn't save your location. Try again or enter a pincode or ZIP manually.";
  }
}

/// Resolves GPS → reverse geocoding, then updates guest + region. Returns `null` if success.
Future<String?> resolveGuestLocationFromGpsAndApply(BuildContext context) async {
  final cubit = context.read<GuestDeliveryCubit>();
  final regBloc = context.read<RegionBloc>();
  try {
    final result = await GuestDeliveryGps.resolve();
    if (result is GuestDeliveryGpsFailure) {
      return result.message;
    }
    if (result is GuestDeliveryGpsSuccess) {
      return applyGuestGpsToStores(cubit, regBloc, result);
    }
    return 'Could not set location. Try again or enter a pincode manually.';
  } catch (_) {
    return "Something went wrong. Try again, or enter your pincode or ZIP below.";
  }
}
