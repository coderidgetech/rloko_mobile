import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../region/app_region.dart';
import '../region/presentation/region_bloc.dart'; // RegionSetRequested
import '../theme/app_theme.dart';
import '../delivery/presentation/guest_delivery_cubit.dart';
import '../delivery/apply_guest_gps_to_stores.dart';

/// Half-sheet: **current location** first (Myntra-style), then optional manual pin / ZIP.
Future<void> showDeliverToLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return BlocBuilder<RegionBloc, RegionState>(
        builder: (context, rState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: _SheetBody(initialRegion: rState.region),
          );
        },
      );
    },
  );
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({required this.initialRegion});
  final AppRegion initialRegion;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  late final TextEditingController _code = TextEditingController();
  late final TextEditingController _city = TextEditingController();
  bool _saving = false;
  bool _gpsBusy = false;
  String? _error;
  bool _isIndia = true;
  bool _loadedFromCubit = false;
  bool _showManual = false;

  @override
  void initState() {
    super.initState();
    _isIndia = widget.initialRegion == AppRegion.india;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedFromCubit) return;
    _loadedFromCubit = true;
    final s = context.read<GuestDeliveryCubit>().state;
    if (_isIndia) {
      _code.text = s.indiaPincode ?? '';
      _city.text = s.indiaCityHint ?? '';
    } else {
      _code.text = s.usZip ?? '';
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _city.dispose();
    super.dispose();
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
      err = "Something went wrong. Try again, or enter your pincode or ZIP below.";
    }
    if (!mounted) return;
    setState(() => _gpsBusy = false);
    if (err == null) {
      Navigator.of(context).pop();
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
        err = await cubit.setIndia(_code.text, city: _city.text.trim().isNotEmpty ? _city.text : null);
        if (err == null) {
          if (regBloc.state.region != AppRegion.india) {
            regBloc.add(const RegionSetRequested(AppRegion.india));
          }
        }
      } else {
        err = await cubit.setUnitedStatesZip(_code.text);
        if (err == null) {
          if (regBloc.state.region != AppRegion.unitedStates) {
            regBloc.add(const RegionSetRequested(AppRegion.unitedStates));
          }
        }
      }
    } catch (_) {
      err = "Something went wrong. Try again.";
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = err;
    });
    if (err == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.foregroundColor(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Choose your location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg),
        ),
        const SizedBox(height: 6),
        Text(
          'We use your location to show the right prices and delivery options. No sign-in required.',
          style: TextStyle(fontSize: 13, height: 1.35, color: AppTheme.mutedForegroundColor(context)),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: (_saving || _gpsBusy) ? null : _useCurrentLocation,
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
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: (_gpsBusy || _saving)
                ? null
                : () => setState(() {
                      _showManual = !_showManual;
                      _error = null;
                    }),
            child: Text(
              _showManual ? 'Hide manual entry' : 'Enter pincode or ZIP manually',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor(context),
              ),
            ),
          ),
        ),
        if (_showManual) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Segment(
                  label: 'India',
                  selected: _isIndia,
                  onTap: _gpsBusy || _saving
                      ? null
                      : () {
                          final s = context.read<GuestDeliveryCubit>().state;
                          setState(() {
                            _isIndia = true;
                            _code.text = s.indiaPincode ?? '';
                            _city.text = s.indiaCityHint ?? '';
                            _error = null;
                          });
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Segment(
                  label: 'United States',
                  selected: !_isIndia,
                  onTap: _gpsBusy || _saving
                      ? null
                      : () {
                          final s = context.read<GuestDeliveryCubit>().state;
                          setState(() {
                            _isIndia = false;
                            _code.text = s.usZip ?? '';
                            _error = null;
                          });
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            enabled: !_saving && !_gpsBusy,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (_isIndia) LengthLimitingTextInputFormatter(6) else LengthLimitingTextInputFormatter(10),
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
              enabled: !_saving && !_gpsBusy,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'City (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_saving || _gpsBusy) ? null : _apply,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.mutedColor(context).withValues(alpha: 0.3),
              foregroundColor: fg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13, height: 1.3),
          ),
        ],
        const SizedBox(height: 8),
      ],
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
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onTap == null
            ? AppTheme.foregroundColor(context).withValues(alpha: 0.35)
            : (selected ? p : AppTheme.foregroundColor(context).withValues(alpha: 0.55)),
      ),
    );
    if (onTap == null) {
      return Opacity(
        opacity: 0.6,
        child: Material(
          color: selected ? p.withValues(alpha: 0.12) : AppTheme.mutedColor(context).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(child: child),
          ),
        ),
      );
    }
    return Material(
      color: selected ? p.withValues(alpha: 0.12) : AppTheme.mutedColor(context).withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
