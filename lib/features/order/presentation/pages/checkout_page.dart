import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/delivery_constants.dart';
import '../../../../core/constants/form_hints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../address/domain/entities/address_entity.dart';
import '../../../address/domain/usecases/address_usecases.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/order_usecases.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<AddressEntity> _addresses = [];
  bool _addressesLoading = true;
  String? _selectedAddressId;
  String _promoCode = '';
  bool _placing = false;
  String? _error;
  bool _retriedAddressesAfterAuth = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  /// Retry loading addresses when we're authenticated (e.g. just returned from login).
  void _retryAddressesIfAuthenticated() {
    if (_retriedAddressesAfterAuth) return;
    if (_error != null || (_addresses.isEmpty && !_addressesLoading)) {
      _retriedAddressesAfterAuth = true;
      _loadAddresses();
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _addressesLoading = true;
      _error = null;
    });
    try {
      final list = await sl<ListAddressesUseCase>().call();
      if (kDebugMode) debugPrint('[CheckoutPage] Loaded ${list.length} addresses');
      if (mounted) {
        setState(() {
          _addresses = list;
          _selectedAddressId =
              list.where((a) => a.isDefault).firstOrNull?.id ?? list.firstOrNull?.id;
          _addressesLoading = false;
        });
      }
    } catch (e, st) {
      final message = e is ApiException ? e.message : (getApiException(e)?.message ?? e.toString());
      if (kDebugMode) {
        debugPrint('[CheckoutPage] _loadAddresses failed: $message\n$st');
      }
      if (mounted) {
        setState(() {
          _addressesLoading = false;
          _error = message;
        });
      }
    }
  }

  ShippingInfoEntity _addressToShipping(
    AddressEntity a,
    String userEmail,
  ) {
    final parts = a.name.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : a.name;
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
    final addressLine =
        a.addressLine + (a.addressLine2 != null && a.addressLine2!.isNotEmpty ? ', ${a.addressLine2}' : '');
    return ShippingInfoEntity(
      firstName: firstName,
      lastName: lastName,
      email: userEmail,
      phone: a.mobile,
      address: addressLine,
      city: a.city,
      state: a.state,
      zipCode: a.pincode,
      country: a.country,
    );
  }

  List<OrderItemEntity> _cartToOrderItems(List<CartItemEntity> items) {
    return items
        .map((e) => OrderItemEntity(
              productId: e.productId,
              productName: e.productName,
              image: e.image,
              price: e.price,
              size: e.size,
              quantity: e.quantity,
            ))
        .toList();
  }

  Future<void> _placeOrder() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/login', extra: '/checkout');
      return;
    }
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded || cartState.cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    if (_selectedAddressId == null || _addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }
    final selectedAddress =
        _addresses.firstWhere((a) => a.id == _selectedAddressId);
    final shipping =
        _addressToShipping(selectedAddress, authState.user.email);
    final orderItems = _cartToOrderItems(cartState.cart.items);

    setState(() {
      _placing = true;
      _error = null;
    });

    try {
      final order = await sl<CreateOrderUseCase>().call(
        items: orderItems,
        shippingInfo: shipping,
        paymentMethod: 'cod',
        promotionCode:
            _promoCode.trim().isEmpty ? null : _promoCode.trim(),
      );
      if (kDebugMode) debugPrint('[CheckoutPage] Order placed: id=${order.id}');
      if (!mounted) return;
      context.read<CartBloc>().add(const CartClearRequested());
      context.go('/order-confirmation/${order.id}');
    } catch (e, st) {
      final message = e is ApiException ? e.message : (getApiException(e)?.message ?? e.toString());
      if (kDebugMode) {
        debugPrint('[CheckoutPage] _placeOrder failed: $message\n$st');
      }
      if (mounted) {
        setState(() {
          _placing = false;
          _error = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.destructive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // After returning from login, retry loading addresses once so token is used
        if (authState is AuthAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _retryAddressesIfAuthenticated();
          });
        }
        if (authState is! AuthAuthenticated) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor(context),
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/cart');
                  }
                },
              ),
              title: const Text('Checkout'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: AppTheme.mutedForegroundColor(context),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign in to checkout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You need to be signed in to place an order.',
                      style: TextStyle(
                        color: AppTheme.mutedForegroundColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () =>
                          context.push('/login', extra: '/checkout'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor(context),
          body: BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              if (cartState is CartLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (cartState is CartError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cartState.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.mutedForegroundColor(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context
                              .read<CartBloc>()
                              .add(const CartLoadRequested()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (cartState is! CartLoaded ||
                  cartState.cart.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Your cart is empty'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go('/cart'),
                        child: const Text('Go to cart'),
                      ),
                    ],
                  ),
                );
              }

              final cart = cartState.cart;
              final subtotal =
                  cart.items.fold(0.0, (s, i) => s + i.price * i.quantity);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDeliveryHeader(context),
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.destructive.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_error!, style: const TextStyle(color: AppTheme.destructive)),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // React MobileAddressSelection: MapPin + "Select Delivery Address", subtitle
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primaryColor(context)),
                            const SizedBox(width: 8),
                            const Text(
                              'Select Delivery Address',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose where you want your order delivered',
                          style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 16),
                        if (_addressesLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (_addresses.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'No saved addresses. Add one to continue.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      await context.push('/addresses/add');
                                      if (mounted) _loadAddresses();
                                    },
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text('Add address'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                        else
                          ..._addresses.map((a) {
                            final selected = _selectedAddressId == a.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => setState(() => _selectedAddressId = a.id),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selected ? AppTheme.primaryColor(context).withValues(alpha: 0.05) : AppTheme.backgroundColor(context),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.12),
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    a.type.toUpperCase() == 'HOME' ? Icons.home_outlined : (a.type.toUpperCase() == 'OFFICE' || a.type.toUpperCase() == 'WORK' ? Icons.work_outline : Icons.location_on_outlined),
                                                    size: 16,
                                                    color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    a.type.toUpperCase(),
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                                                  ),
                                                  if (a.isDefault) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(999),
                                                      ),
                                                      child: Text('DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor(context))),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                              const SizedBox(height: 4),
                                              Text(
                                                a.addressLine + (a.addressLine2 != null && a.addressLine2!.isNotEmpty ? ', ${a.addressLine2}' : ''),
                                                style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${a.city}, ${a.state} ${a.pincode}',
                                                style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(a.country, style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7))),
                                              const SizedBox(height: 2),
                                              Text(a.mobile, style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7))),
                                              if (selected) ...[
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.only(top: 12),
                                                  decoration: BoxDecoration(
                                                    border: Border(top: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12))),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextButton.icon(
                                                          onPressed: () async {
                                                            await context.push('/addresses/edit/${a.id}');
                                                            if (mounted) _loadAddresses();
                                                          },
                                                          icon: const Icon(Icons.edit_outlined, size: 14),
                                                          label: const Text('Edit'),
                                                          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor(context)),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: TextButton.icon(
                                                          onPressed: () async {
                                                            final confirm = await showDialog<bool>(
                                                              context: context,
                                                              builder: (ctx) => AlertDialog(
                                                                title: const Text('Delete address?'),
                                                                content: const Text('This address will be removed.'),
                                                                actions: [
                                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                                  FilledButton(
                                                                    onPressed: () => Navigator.pop(ctx, true),
                                                                    style: FilledButton.styleFrom(backgroundColor: AppTheme.destructive),
                                                                    child: const Text('Delete'),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                            if (confirm == true && mounted) {
                                                              await sl<DeleteAddressUseCase>().call(a.id);
                                                              _loadAddresses();
                                                            }
                                                          },
                                                          icon: const Icon(Icons.delete_outline, size: 14),
                                                          label: const Text('Delete'),
                                                          style: TextButton.styleFrom(foregroundColor: AppTheme.destructive),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected ? AppTheme.primaryColor(context) : Colors.transparent,
                                            border: Border.all(
                                              color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                                              width: 2,
                                            ),
                                          ),
                                          child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        if (_addresses.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          // Match React MobileAddressSelectionPage: full-width Add New Address, w-full py-4 rounded-2xl
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  await context.push('/addresses/add');
                                  if (mounted) _loadAddresses();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor(context).withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.primaryColor(context).withValues(alpha: 0.3), width: 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, size: 20, color: AppTheme.primaryColor(context)),
                                      const SizedBox(width: 8),
                                      Text('Add New Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryColor(context))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Delivery info box – match React
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📦 Delivery Information',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DeliveryConstants.deliveryInfoBullets,
                                  style: TextStyle(fontSize: 12, color: const Color(0xFF1E3A8A).withValues(alpha: 0.9), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Text('Promo code (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: FormHints.promoCode,
                            filled: true,
                            fillColor: AppTheme.backgroundColor(context),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (v) => _promoCode = v,
                        ),
                        const SizedBox(height: 24),
                        const Text('Order summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtotal', style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))), Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))]),
                              const SizedBox(height: 8),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Shipping', style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))), Text(DeliveryConstants.calculatedAtCheckout, style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)))]),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                              const SizedBox(height: 12),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total (approx)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sticky bottom: React "Continue to Payment" style - Place order
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor(context),
                        border: Border(top: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12))),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _placing || _addresses.isEmpty || _selectedAddressId == null ? null : _placeOrder,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: _placing
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Place order'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDeliveryHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(top: topPadding, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        border: Border(bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/cart');
                }
              },
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.chevron_left, size: 24),
              ),
            ),
          ),
          const Text(
            'Delivery Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
