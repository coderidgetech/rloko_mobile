import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app_region.dart';
import '../../../presentation/region_bloc.dart';
import '../../../../delivery/apply_guest_gps_to_stores.dart';
import '../../../../delivery/presentation/guest_delivery_cubit.dart';
import '../../../../theme/app_theme.dart';
import '../../../../../features/config/presentation/bloc/config_bloc.dart';
import '../location_gate_cubit.dart';

/// Full-screen location picker body shared by the enforced `/location-gate`
/// route and the onboarding location step.
///
/// Local-first: validates + persists the chosen market immediately via the
/// existing [GuestDeliveryCubit] + [RegionBloc], then fires a background
/// [LocationGateCubit.enrich] to confirm availability with the server.
/// Calls [onChosen] once a location is committed.
class LocationGateView extends StatefulWidget {
  const LocationGateView({super.key, required this.onChosen});

  /// Invoked after a location has been chosen and persisted.
  final VoidCallback onChosen;

  @override
  State<LocationGateView> createState() => _LocationGateViewState();
}

class _LocationGateViewState extends State<LocationGateView> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _city = TextEditingController();
  bool _saving = false;
  bool _gpsBusy = false;
  String? _error;
  bool _isIndia = false;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    // Seed from RegionBloc (the source of truth), but never start on a disabled
    // region (e.g. India when it's "coming soon").
    final indiaEnabled = _regionAvailability('IN').enabled;
    final currentRegion = context.read<RegionBloc>().state.region;
    _isIndia = indiaEnabled && currentRegion == AppRegion.india;
    _syncFieldsToRegion(context.read<GuestDeliveryCubit>().state);
  }

  @override
  void dispose() {
    _code.dispose();
    _city.dispose();
    super.dispose();
  }

  ({bool enabled, String message}) _regionAvailability(String marketCode) {
    final state = context.read<ConfigBloc>().state;
    if (state is ConfigLoaded) {
      final region = state.config.general.regions[marketCode];
      if (region != null) {
        return (enabled: region.enabled, message: region.comingSoonMessage);
      }
    }
    return (enabled: true, message: '');
  }

  void _syncFieldsToRegion(GuestDeliveryState s) {
    if (_isIndia) {
      _code.text = s.indiaPincode ?? '';
      _city.text = s.indiaCityHint ?? '';
    } else {
      _code.text = s.usZip ?? '';
    }
  }

  void _selectRegion({required bool india}) {
    final s = context.read<GuestDeliveryCubit>().state;
    setState(() {
      _isIndia = india;
      _error = null;
      _syncFieldsToRegion(s);
    });
  }

  Future<void> _useCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _gpsBusy = true;
    });
    String? err;
    try {
      err = await resolveGuestLocationFromGpsAndApply(context);
    } catch (_) {
      err = 'Something went wrong. Try again, or enter your pincode or ZIP below.';
    }
    if (!mounted) return;
    setState(() => _gpsBusy = false);
    if (err == null) {
      _enrichInBackground();
      widget.onChosen();
      return;
    }
    setState(() => _error = err);
  }

  Future<void> _apply() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _saving = true;
    });
    String? err;
    try {
      final cubit = context.read<GuestDeliveryCubit>();
      final regBloc = context.read<RegionBloc>();
      if (_isIndia) {
        err = await cubit.setIndia(
          _code.text,
          city: _city.text.trim().isNotEmpty ? _city.text : null,
        );
        if (err == null && regBloc.state.region != AppRegion.india) {
          regBloc.add(const RegionSetRequested(AppRegion.india));
        }
      } else {
        err = await cubit.setUnitedStatesZip(_code.text);
        if (err == null && regBloc.state.region != AppRegion.unitedStates) {
          regBloc.add(const RegionSetRequested(AppRegion.unitedStates));
        }
      }
    } catch (_) {
      err = 'Something went wrong. Try again.';
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = err;
    });
    if (err == null) {
      _enrichInBackground();
      widget.onChosen();
    }
  }

  /// Fire-and-forget server confirmation of the locally-derived market.
  void _enrichInBackground() {
    final country = _isIndia ? 'IN' : 'US';
    context.read<LocationGateCubit>().enrich(
          pincode: _code.text.trim().isNotEmpty ? _code.text.trim() : null,
          country: country,
          city: _city.text.trim().isNotEmpty ? _city.text.trim() : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.foregroundColor(context);
    final india = _regionAvailability('IN');
    final busy = _saving || _gpsBusy;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_outlined,
                size: 36, color: AppTheme.primaryColor(context)),
          ),
          const SizedBox(height: 20),
          Text(
            'Where should we deliver?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: fg),
          ),
          const SizedBox(height: 8),
          Text(
            'We use your location to show the right prices, currency and delivery options. No sign-in required.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppTheme.mutedForegroundColor(context),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: busy ? null : _useCurrentLocation,
            icon: _gpsBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded, size: 20),
            label: Text(
              _gpsBusy ? 'Finding your location…' : 'Use current location',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: fg.withValues(alpha: 0.12))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or enter manually',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForegroundColor(context),
                  ),
                ),
              ),
              Expanded(child: Divider(color: fg.withValues(alpha: 0.12))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Segment(
                  label: india.enabled ? 'India' : 'India (Coming soon)',
                  selected: _isIndia,
                  onTap: !india.enabled || busy ? null : () => _selectRegion(india: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Segment(
                  label: 'United States',
                  selected: !_isIndia,
                  onTap: busy ? null : () => _selectRegion(india: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            enabled: !busy,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (_isIndia)
                LengthLimitingTextInputFormatter(6)
              else
                LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: _isIndia ? 'Pincode' : 'ZIP code',
              hintText: _isIndia ? '6-digit pincode' : '5-digit ZIP',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_isIndia) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'City (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : _apply,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.primaryColor(context);
    final child = Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onTap == null
            ? AppTheme.foregroundColor(context).withValues(alpha: 0.35)
            : (selected ? p : AppTheme.foregroundColor(context).withValues(alpha: 0.55)),
      ),
    );
    final color = selected
        ? p.withValues(alpha: 0.12)
        : AppTheme.mutedColor(context).withValues(alpha: 0.2);
    if (onTap == null) {
      return Opacity(
        opacity: 0.6,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: child),
          ),
        ),
      );
    }
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
