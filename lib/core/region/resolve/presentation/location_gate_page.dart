import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../di/injection.dart';
import '../../../theme/app_theme.dart';
import '../../region_repository.dart';
import '../domain/usecases/resolve_region_usecase.dart';
import 'location_gate_cubit.dart';
import 'widgets/location_gate_view.dart';

/// Enforced first-launch location gate (`/location-gate`). Shown whenever no
/// location has been chosen yet. Cannot be dismissed without choosing.
class LocationGatePage extends StatelessWidget {
  const LocationGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocationGateCubit(sl<ResolveRegionUseCase>()),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor(context),
          body: SafeArea(
            child: Center(
              child: LocationGateView(
                onChosen: () async {
                  // Best-effort: a prefs failure must not strand the user on the
                  // gate — the guard simply re-fires on the next cold start.
                  try {
                    await sl<RegionRepository>().markLocationChosen();
                  } catch (_) {/* ignore */}
                  if (context.mounted) context.go('/');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
