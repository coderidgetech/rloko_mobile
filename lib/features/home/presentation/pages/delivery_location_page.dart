import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/delivery_constants.dart';
import '../../../../core/constants/form_hints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../address/domain/entities/address_entity.dart';
import '../../../address/domain/usecases/address_usecases.dart';
import '../../../address/presentation/bloc/address_list_bloc.dart';

/// Delivery location – uses addresses API (AddressListBloc); design matches React MobileDeliveryLocationPage.
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
    context.read<AddressListBloc>().add(const AddressListLoadRequested());
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
        context.go('/account');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not set address: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: true),
      body: BlocBuilder<AddressListBloc, AddressListState>(
        builder: (context, state) {
          if (state is AddressListLoading) {
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
                      state.message,
                      style: TextStyle(color: AppTheme.mutedForeground),
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
                        style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
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
                      prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.mutedForeground),
                      filled: true,
                      fillColor: AppTheme.foreground.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.2)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location feature coming soon')),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primary.withValues(alpha: 0.05),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.my_location, size: 20, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Use Current Location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Enable location to detect your address',
                                    style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 20, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                          foregroundColor: AppTheme.primary,
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
                          Icon(Icons.location_off, size: 48, color: AppTheme.mutedForeground),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty ? 'No saved addresses' : 'No matches',
                            style: TextStyle(color: AppTheme.mutedForeground),
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
                          '• ${DeliveryConstants.standardDeliveryDays}\n'
                          '• Express delivery available in select areas\n'
                          '• Free shipping on orders over ₹2000\n'
                          '• Contactless delivery available',
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
              color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, size: 20, color: AppTheme.primary),
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
                                address.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                              if (address.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary,
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
                              color: AppTheme.mutedForeground,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: ${address.mobile}',
                            style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppTheme.border.withValues(alpha: 0.2)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: AppTheme.mutedForeground),
                                const SizedBox(width: 6),
                                Text(
                                  'Estimated delivery: ${DeliveryConstants.estimatedDelivery}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.mutedForeground,
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
