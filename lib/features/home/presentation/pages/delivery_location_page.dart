import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/constants/delivery_constants.dart';
import '../../../../core/constants/form_hints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/region/presentation/region_bloc.dart';
import '../../../../core/region/app_region.dart';
import '../../../../core/delivery/presentation/guest_delivery_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/deliver_to_location_sheet.dart';
import '../../../../core/delivery/apply_guest_gps_to_stores.dart';
import '../../../address/domain/entities/address_entity.dart';
import '../../../address/domain/usecases/address_usecases.dart';
import '../../../address/presentation/bloc/address_list_bloc.dart';

/// Delivery location – uses addresses API (AddressListBloc); parity with web DeliveryLocationPage.
class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({super.key});

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  String _searchQuery = '';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthAuthenticated) {
        context.read<AddressListBloc>().add(const AddressListLoadRequested());
      }
    });
  }

  String _typeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'HOME':
        return 'Home';
      case 'OFFICE':
        return 'Work';
      case 'OTHER':
        return 'Other';
      default:
        return type;
    }
  }

  String _typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'HOME':
        return '🏠';
      case 'OFFICE':
        return '💼';
      default:
        return '📍';
    }
  }

  Future<void> _selectAddress(AddressEntity address) async {
    setState(() => _selectedId = address.id);
    try {
      await sl<SetDefaultAddressUseCase>().call(address.id);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("We couldn't save this address. Please try again.")),
      );
    }
  }

  String _loadErrorForUser(String raw, bool isUnauth) {
    if (isUnauth) {
      return 'Sign in to see and manage your delivery addresses.';
    }
    return "We couldn't load your addresses. Check your connection and try again.";
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        appBar: const AppHeader(showBackButton: true),
        body: const _GuestDeliveryLocationBody(),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: BlocListener<AddressListBloc, AddressListState>(
        listenWhen: (p, c) => c is AddressListLoaded && _selectedId == null,
        listener: (context, s) {
          if (s is! AddressListLoaded) return;
          if (_selectedId != null) return;
          AddressEntity? def;
          for (final a in s.addresses) {
            if (a.isDefault) {
              def = a;
              break;
            }
          }
          if (s.addresses.isNotEmpty) {
            setState(() {
              _selectedId = (def ?? s.addresses.first).id;
            });
          }
        },
        child: BlocBuilder<AddressListBloc, AddressListState>(
          builder: (context, state) {
          if (state is AddressListLoading || state is AddressListInitial) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is AddressListError) {
            final isUnauth = state.message.contains('Sign in');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _loadErrorForUser(state.message, isUnauth),
                      style: TextStyle(
                        color: AppTheme.mutedForegroundColor(context),
                        fontSize: 15,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (isUnauth) {
                          context.push('/login', extra: '/delivery-location');
                        } else {
                          context.read<AddressListBloc>().add(const AddressListLoadRequested());
                        }
                      },
                      child: Text(isUnauth ? 'Sign in' : 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final addresses = state is AddressListLoaded ? state.addresses : <AddressEntity>[];
          final filtered = _searchQuery.isEmpty
              ? addresses
              : addresses.where((a) {
                  final q = _searchQuery.toLowerCase();
                  return a.addressLine.toLowerCase().contains(q) ||
                      a.city.toLowerCase().contains(q) ||
                      a.name.toLowerCase().contains(q);
                }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Delivery Location',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose where you want your order delivered',
                        style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: FormHints.searchArea,
                      prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.mutedForegroundColor(context)),
                      filled: true,
                      fillColor: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add a new address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.foregroundColor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap Add New to enter your building, street, and flat details. The address you set as default is used for delivery updates and checkouts.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: AppTheme.mutedForegroundColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Addresses',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/addresses/add'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add New'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.location_off, size: 48, color: AppTheme.mutedForegroundColor(context)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? "You don't have any saved addresses yet"
                                : 'No addresses match your search',
                            style: TextStyle(color: AppTheme.mutedForegroundColor(context)),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => context.push('/addresses/add'),
                              child: const Text('Add address'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((address) => _addressCard(address)),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📦 Delivery Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${DeliveryConstants.deliveryInfoBulletsFor(context.read<RegionBloc>().state.region)}\n'
                          '• Contactless delivery available in select areas',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _addressCard(AddressEntity address) {
    final isSelected = _selectedId == address.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAddress(address),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor(context).withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor(context) : AppTheme.borderColor(context),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, size: 20, color: AppTheme.primaryColor(context)),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_typeIcon(address.type), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _typeLabel(address.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.mutedForegroundColor(context),
                                ),
                              ),
                              if (address.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryColor(context),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${address.addressLine}${address.addressLine2 != null ? ', ${address.addressLine2}' : ''}, ${address.city} ${address.pincode}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.mutedForegroundColor(context),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: ${address.mobile}',
                            style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppTheme.borderColor(context).withValues(alpha: 0.2)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: AppTheme.mutedForegroundColor(context)),
                                const SizedBox(width: 6),
                                Text(
                                  'Estimated delivery: ${DeliveryConstants.estimatedDelivery}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.mutedForegroundColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Myntra-style: current location or manual pin; sign-in only for saved addresses.
class _GuestDeliveryLocationBody extends StatefulWidget {
  const _GuestDeliveryLocationBody();

  @override
  State<_GuestDeliveryLocationBody> createState() => _GuestDeliveryLocationBodyState();
}

class _GuestDeliveryLocationBodyState extends State<_GuestDeliveryLocationBody> {
  bool _gpsBusy = false;
  String? _gpsError;

  Future<void> _onUseGps() async {
    if (!mounted) return;
    setState(() {
      _gpsBusy = true;
      _gpsError = null;
    });
    String? err;
    try {
      err = await resolveGuestLocationFromGpsAndApply(context);
    } catch (_) {
      err = "Something went wrong. Try again, or set your location manually from Change location.";
    }
    if (!mounted) return;
    setState(() {
      _gpsBusy = false;
      _gpsError = err;
    });
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated for delivery')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select location',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We detect your area using your phone location (like Myntra), or you can enter a pincode or ZIP manually. Shop and add to bag now — sign in at checkout to save a full address.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppTheme.mutedForegroundColor(context),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _gpsBusy ? null : _onUseGps,
            icon: _gpsBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded, size: 22),
            label: Text(_gpsBusy ? 'Getting your location…' : 'Use current location'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_gpsError != null) ...[
            const SizedBox(height: 8),
            Text(
              _gpsError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 20),
          BlocBuilder<RegionBloc, RegionState>(
            builder: (context, r) {
              return BlocBuilder<GuestDeliveryCubit, GuestDeliveryState>(
                builder: (context, g) {
                  final market = r.region;
                  String summary;
                  if (market == AppRegion.india) {
                    final p = g.indiaPincode;
                    if (p != null && p.length == 6) {
                      final c = g.indiaCityHint;
                      summary = c != null && c.isNotEmpty
                          ? 'Currently: $c · $p'
                          : 'Currently: $p';
                    } else {
                      summary = 'Pincode not set';
                    }
                  } else {
                    final z = g.usZip;
                    summary = (z != null && z.isNotEmpty) ? 'Currently: $z' : 'ZIP not set';
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pin_drop_outlined, color: AppTheme.primaryColor(context), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            summary,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.foregroundColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => showDeliverToLocationSheet(context),
            icon: const Icon(Icons.edit_location_outlined, size: 20),
            label: const Text('Change location'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => context.push('/login', extra: '/delivery-location'),
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text('Sign in to manage saved addresses'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppTheme.primaryColor(context).withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: BlocBuilder<RegionBloc, RegionState>(
              builder: (context, s) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📦 Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade900)),
                    const SizedBox(height: 8),
                    Text(
                      '${DeliveryConstants.deliveryInfoBulletsFor(s.region)}\n'
                      '• You can change location anytime from the home screen',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, height: 1.5),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
