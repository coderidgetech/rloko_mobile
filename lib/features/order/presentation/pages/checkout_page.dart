import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/currency_constants.dart';
import '../../../../core/constants/stripe_constants.dart';
import '../../../../core/constants/delivery_constants.dart';
import '../../../../core/constants/form_hints.dart';
import '../../../../core/constants/shipping.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/region/app_region.dart';
import '../../../../core/region/currency_scope.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/payment_method_picker.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../address/domain/entities/address_entity.dart';
import '../../../address/domain/usecases/address_usecases.dart';
import '../../../address/presentation/pages/address_form_page.dart';
import '../../../promotion/domain/usecases/validate_promotion_usecase.dart';
import '../../../shipping/domain/entities/calculate_shipping_params.dart';
import '../../../shipping/domain/entities/shipping_method_entity.dart';
import '../../../shipping/domain/usecases/calculate_shipping_usecase.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../domain/utils/order_mappers.dart';
import '../stripe_checkout.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    this.initialPaymentMethod,
    this.initialCouponCode,
    this.initialCouponDiscount,
  });

  final String? initialPaymentMethod;
  final String? initialCouponCode;
  final double? initialCouponDiscount;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<AddressEntity> _addresses = [];
  bool _addressesLoading = true;
  String? _selectedAddressId;
  String _promoCode = '';
  final _promoController = TextEditingController();
  bool _couponValidating = false;
  double? _appliedDiscount; // in USD
  String? _appliedCouponCode;
  String? _couponError;
  final Set<String> _giftItemKeys = {}; // '${productId}-${size}'
  bool _placing = false;
  String? _error;
  bool _retriedAddressesAfterAuth = false;
  List<ShippingMethodEntity> _shippingMethods = [];
  String? _selectedShippingMethodId;
  double? _quotedShipping;
  String _quotedShippingCurrency = 'USD';
  bool _shippingQuoteLoading = false;
  String? _shippingError;
  int _quoteFetchGen = 0;
  late String _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    final fromCart = widget.initialPaymentMethod?.trim();
    if (fromCart == 'card' || fromCart == 'upi' || fromCart == 'cod') {
      final pm = fromCart!;
      if ((pm == 'card' || pm == 'upi') && kStripePublishableKey.isEmpty) {
        _selectedPaymentMethod = 'cod';
      } else {
        _selectedPaymentMethod = pm;
      }
    } else {
      _selectedPaymentMethod =
          kStripePublishableKey.isNotEmpty ? 'card' : 'cod';
    }
    if (widget.initialCouponCode != null && widget.initialCouponDiscount != null) {
      _appliedCouponCode = widget.initialCouponCode;
      _promoCode = widget.initialCouponCode!;
      _promoController.text = widget.initialCouponCode!;
      _appliedDiscount = widget.initialCouponDiscount;
    }
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
      if (kDebugMode) {
        debugPrint('[CheckoutPage] Loaded ${list.length} addresses');
      }
      if (mounted) {
        setState(() {
          _addresses = list;
          _selectedAddressId =
              list.where((a) => a.isDefault).firstOrNull?.id ??
              list.firstOrNull?.id;
          _addressesLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _refreshShippingQuote();
        });
      }
    } catch (e, st) {
      final message = e is ApiException
          ? e.message
          : (getApiException(e)?.message ?? e.toString());
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

  /// Show address form in a bottom sheet (add or edit). Returns true if saved.
  Future<bool?> _showAddressFormSheet({
    String? addressId,
    AddressEntity? initialAddress,
  }) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: AddressFormPage(
            addressId: addressId,
            initialAddress: initialAddress,
          ),
        ),
      ),
    );
  }

  /// Show address picker sheet: list of addresses + Add new. Calls [onSelect] when an address is chosen.
  void _showAddressPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Delivery address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  ..._addresses.map((a) {
                    final selected = _selectedAddressId == a.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedAddressId = a.id);
                            Navigator.pop(ctx);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _refreshShippingQuote();
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primaryColor(
                                      context,
                                    ).withValues(alpha: 0.08)
                                  : AppTheme.backgroundColor(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primaryColor(context)
                                    : AppTheme.foregroundColor(
                                        context,
                                      ).withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${a.addressLine}, ${a.city}, ${a.pincode}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.foregroundColor(
                                            context,
                                          ).withValues(alpha: 0.7),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        a.mobile,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.foregroundColor(
                                            context,
                                          ).withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final result = await _showAddressFormSheet(
                                      addressId: a.id,
                                    );
                                    if (result == true && mounted) {
                                      await _loadAddresses();
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    }
                                  },
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: AppTheme.foregroundColor(
                                      context,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final result = await _showAddressFormSheet();
                        if (result == true && mounted) await _loadAddresses();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(
                            context,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 22,
                              color: AppTheme.primaryColor(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add new address',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _cartSubtotalUsd(Iterable<CartItemEntity> items, AppRegion region) {
    const usdToInr = kUsdToInrDisplay;
    return items.fold(0.0, (s, i) {
      if (region == AppRegion.india && i.priceInr != null) {
        return s + (i.priceInr! * i.quantity) / usdToInr;
      }
      return s + i.price * i.quantity;
    });
  }

  double _cartWeightLb(Iterable<CartItemEntity> items) {
    return items.fold(0.0, (s, i) => s + i.quantity * kDefaultItemWeightLb);
  }

  Future<void> _refreshShippingQuote() async {
    final myGen = ++_quoteFetchGen;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded || cartState.cart.items.isEmpty) return;
    if (_selectedAddressId == null || _addresses.isEmpty) {
      if (mounted) {
        setState(() {
          _quotedShipping = null;
          _shippingQuoteLoading = false;
          _shippingError = null;
        });
      }
      return;
    }
    final region = CurrencyScope.of(context).region;
    final sub = _cartSubtotalUsd(cartState.cart.items, region);
    final w = _cartWeightLb(cartState.cart.items);
    final weight = w > 0 ? w : kDefaultItemWeightLb;
    final addr = _addresses.firstWhere((a) => a.id == _selectedAddressId);
    final ship = addressToShipping(addr, auth.user.email);
    if (mounted) setState(() { _shippingQuoteLoading = true; _shippingError = null; });
    try {
      final methods = await sl<CalculateShippingUseCase>().call(
        CalculateShippingParams(
          country: ship.country,
          state: ship.state,
          city: ship.city,
          address: ship.address,
          postalCode: ship.zipCode,
          firstName: ship.firstName,
          lastName: ship.lastName,
          email: ship.email,
          phone: ship.phone,
          subtotal: sub,
          weight: weight,
        ),
      );
      if (!mounted) return;
      if (myGen != _quoteFetchGen) return;
      if (methods.isNotEmpty) {
        final defaultMethod = _selectedShippingMethodId != null &&
                methods.any((m) => m.id == _selectedShippingMethodId)
            ? methods.firstWhere((m) => m.id == _selectedShippingMethodId)
            : methods.first;
        setState(() {
          _shippingMethods = methods;
          _selectedShippingMethodId = defaultMethod.id;
          _quotedShipping = defaultMethod.baseCost;
          _quotedShippingCurrency = defaultMethod.currency;
          _shippingQuoteLoading = false;
        });
      } else {
        setState(() {
          _shippingMethods = [];
          _selectedShippingMethodId = null;
          _quotedShipping = null;
          _shippingQuoteLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CheckoutPage] shipping quote: $e');
      if (mounted && myGen == _quoteFetchGen) {
        setState(() {
          _quotedShipping = null;
          _shippingQuoteLoading = false;
          _shippingError = 'Could not fetch shipping rates. Tap to retry.';
        });
      }
    }
  }

  static const double _giftChargePerItemUsd = 0.60; // ~₹50

  Future<void> _placeOrder() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (!mounted) return;
    if (connectivity.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No internet connection. Please check your network and try again.',
          ),
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/login', extra: '/checkout');
      return;
    }
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded || cartState.cart.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }
    if (_selectedAddressId == null || _addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }
    // Use orElse so a stale _selectedAddressId (address deleted since selection)
    // falls back gracefully instead of throwing StateError.
    AddressEntity? selectedAddress;
    try {
      selectedAddress = _addresses.firstWhere((a) => a.id == _selectedAddressId);
    } catch (_) {}
    if (selectedAddress == null) {
      if (mounted) setState(() => _selectedAddressId = _addresses.first.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please re-select a delivery address')),
      );
      return;
    }
    final promo = _promoCode.trim().isEmpty ? null : _promoCode.trim();

    if (_selectedPaymentMethod == 'card' || _selectedPaymentMethod == 'upi') {
      setState(() {
        _placing = true;
        _error = null;
      });
      await runStripeCheckout(
        context: context,
        authState: authState,
        cartItems: cartState.cart.items,
        selectedAddress: selectedAddress,
        orderPaymentMethod: _selectedPaymentMethod,
        promotionCode: promo,
        giftItemKeys: _giftItemKeys,
      );
      if (mounted) {
        setState(() => _placing = false);
      }
      return;
    }

    final orderItems = cartItemsToOrderItems(cartState.cart.items, giftItemKeys: _giftItemKeys);
    final shipping = addressToShipping(selectedAddress, authState.user.email);
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final order = await sl<CreateOrderUseCase>().call(
        items: orderItems,
        shippingInfo: shipping,
        paymentMethod: _selectedPaymentMethod,
        promotionCode: promo,
      );
      if (kDebugMode) {
        debugPrint('[CheckoutPage] Order placed: id=${order.id}');
      }
      if (!mounted) return;
      context.read<CartBloc>().add(const CartClearRequested());
      context.go('/order-confirmation/${order.id}');
    } catch (e, st) {
      final message = e is ApiException
          ? e.message
          : (getApiException(e)?.message ?? e.toString());
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

  Future<void> _openPaymentMethodPicker() async {
    final next = await showPaymentMethodPicker(
      context,
      selected: _selectedPaymentMethod,
    );
    if (next != null && mounted) {
      setState(() => _selectedPaymentMethod = next);
    }
  }

  @override
  void dispose() {
    FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final cartState = context.read<CartBloc>().state;
    final region = CurrencyScope.of(context).region;
    final subtotal = cartState is CartLoaded
        ? _cartSubtotalUsd(cartState.cart.items, region)
        : 0.0;
    setState(() {
      _couponValidating = true;
      _couponError = null;
    });
    try {
      final result = await sl<ValidatePromotionUseCase>().call(code, subtotal);
      if (!mounted) return;
      if (result.valid && result.discount != null && result.discount! > 0) {
        setState(() {
          _appliedCouponCode = code;
          _appliedDiscount = result.discount;
          _promoCode = code;
          _couponError = null;
          _couponValidating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon "$code" applied!')),
        );
      } else {
        setState(() {
          _couponError = 'Invalid or expired coupon code';
          _appliedDiscount = null;
          _appliedCouponCode = null;
          _couponValidating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _couponError = 'Could not validate coupon. Try again.';
        _couponValidating = false;
      });
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
                onPressed: () => context.pop(),
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
                      Icons.shopping_bag_outlined,
                      size: 56,
                      color: AppTheme.mutedForegroundColor(context),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ready to checkout?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in for faster checkout, order history and rewards — or continue as a guest.',
                      style: TextStyle(color: AppTheme.mutedForegroundColor(context), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.push('/login', extra: '/checkout'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Sign in to checkout', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push('/checkout/guest'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Continue as Guest', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => context.push('/signup'),
                      child: Text(
                        "Don't have an account? Sign up",
                        style: TextStyle(color: AppTheme.mutedForegroundColor(context), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return BlocListener<CartBloc, CartState>(
          listenWhen: (p, c) => c is CartLoaded,
          listener: (context, state) {
            if (state is CartLoaded && state.cart.items.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _refreshShippingQuote();
              });
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor(context),
            body: BlocBuilder<CartBloc, CartState>(
              buildWhen: (prev, curr) =>
                  curr.runtimeType != prev.runtimeType ||
                  (curr is CartLoaded &&
                      prev is CartLoaded &&
                      curr.cart != prev.cart) ||
                  curr is CartItemUpdateFailed,
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
                            onPressed: () => context.read<CartBloc>().add(
                              const CartLoadRequested(),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (cartState is! CartLoaded || cartState.cart.items.isEmpty) {
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
                final region = CurrencyScope.of(context).region;
                // C1: Always use USD for subtotal math; convert for display only.
                final subtotalUsd = _cartSubtotalUsd(cart.items, region);
                final subtotalInr = subtotalUsd * kUsdToInrDisplay;
                // Shipping is always in the method's own currency; normalise to USD for totals.
                final shippingUsd = _quotedShipping == null
                    ? 0.0
                    : _quotedShippingCurrency == 'INR'
                        ? _quotedShipping! / kUsdToInrDisplay
                        : _quotedShipping!;
                final giftCount = _giftItemKeys.isEmpty
                    ? 0
                    : cart.items.where((i) => _giftItemKeys.contains('${i.productId}-${i.size}')).length;
                final giftChargeUsd = giftCount * _giftChargePerItemUsd;
                final giftText = giftCount == 0
                    ? null
                    : region == AppRegion.india
                        ? '+₹${(giftChargeUsd * kUsdToInrDisplay).round()}'
                        : '+\$${giftChargeUsd.toStringAsFixed(2)}';
                final discountUsd = _appliedDiscount ?? 0.0;
                final discountText = _appliedDiscount == null
                    ? null
                    : region == AppRegion.india
                        ? '-${CurrencyScope.of(context).formatPrice(_appliedDiscount!, _appliedDiscount! * kUsdToInrDisplay)}'
                        : '-\$${_appliedDiscount!.toStringAsFixed(2)}';
                // Total in USD; convert for display when region is India.
                final totalUsd = (subtotalUsd + shippingUsd + giftChargeUsd - discountUsd).clamp(0.0, double.infinity);
                final subtotalText = region == AppRegion.india
                    ? CurrencyScope.of(context).formatPrice(subtotalUsd, subtotalInr)
                    : CurrencyScope.of(context).formatPrice(subtotalUsd, null);
                final shippingDisplayCost = _quotedShipping == null
                    ? null
                    : (_quotedShippingCurrency == 'USD' && region == AppRegion.india
                        ? _quotedShipping! * kUsdToInrDisplay
                        : _quotedShipping!);
                final shippingText = _shippingQuoteLoading
                    ? '...'
                    : _quotedShipping == null
                    ? 'Add address to estimate'
                    : shippingDisplayCost == 0
                    ? 'Free'
                    : (region == AppRegion.india && _quotedShippingCurrency == 'USD')
                    ? CurrencyScope.of(context).formatPrice(_quotedShipping!, _quotedShipping! * kUsdToInrDisplay)
                    : (_quotedShippingCurrency == 'USD'
                          ? '\$${_quotedShipping!.toStringAsFixed(2)}'
                          : '₹${_quotedShipping!.round()}');
                final totalText = region == AppRegion.india
                    ? CurrencyScope.of(context).formatPrice(totalUsd, totalUsd * kUsdToInrDisplay)
                    : CurrencyScope.of(context).formatPrice(totalUsd, null);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDeliveryHeader(context),
                    Expanded(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 80 + MediaQuery.paddingOf(context).bottom),
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
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(color: AppTheme.destructive, fontSize: 13),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _loadAddresses,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Delivery address – one compact card + Change (Myntra-style)
                                if (_addressesLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                else if (_addresses.isEmpty)
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        final result =
                                            await _showAddressFormSheet();
                                        if (result == true && mounted) {
                                          await _loadAddresses();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor(
                                            context,
                                          ).withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.primaryColor(
                                              context,
                                            ).withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 24,
                                              color: AppTheme.primaryColor(
                                                context,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Add delivery address',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppTheme.foregroundColor(
                                                            context,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Tap to add where you want your order delivered',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppTheme.foregroundColor(
                                                            context,
                                                          ).withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right,
                                              color: AppTheme.foregroundColor(
                                                context,
                                              ).withValues(alpha: 0.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Builder(builder: (context) {
                                    // M6: extract selectedAddr once to avoid repeated firstWhere calls.
                                    final selectedAddr = _selectedAddressId != null
                                        ? _addresses.firstWhereOrNull((a) => a.id == _selectedAddressId)
                                        : null;
                                    return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showAddressPickerSheet,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.backgroundColor(
                                            context,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.foregroundColor(
                                              context,
                                            ).withValues(alpha: 0.12),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 22,
                                              color: AppTheme.primaryColor(
                                                context,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    selectedAddr?.name ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    selectedAddr?.addressLine ?? '',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppTheme.foregroundColor(
                                                            context,
                                                          ).withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    selectedAddr?.mobile ?? '',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppTheme.foregroundColor(
                                                            context,
                                                          ).withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  _showAddressPickerSheet,
                                              child: const Text('Change'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                  }),
                                if (_shippingMethods.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Delivery option',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor(context),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: RadioGroup<String>(
                                      groupValue: _selectedShippingMethodId ?? '',
                                      onChanged: (v) {
                                        final method = _shippingMethods.firstWhere(
                                          (m) => m.id == v,
                                          orElse: () => _shippingMethods.first,
                                        );
                                        setState(() {
                                          _selectedShippingMethodId = method.id;
                                          _quotedShipping = method.baseCost;
                                          _quotedShippingCurrency = method.currency;
                                        });
                                      },
                                      child: Column(
                                      children: List.generate(_shippingMethods.length, (i) {
                                        final m = _shippingMethods[i];
                                        final selected = m.id == _selectedShippingMethodId;
                                        final region = CurrencyScope.of(context).region;
                                        final costDisplay = m.baseCost == 0
                                            ? 'Free'
                                            : m.currency == 'USD' && region == AppRegion.india
                                                ? '₹${(m.baseCost * kUsdToInrDisplay).round()}'
                                                : m.currency == 'USD'
                                                    ? '\$${m.baseCost.toStringAsFixed(2)}'
                                                    : '₹${m.baseCost.round()}';
                                        final showDivider = i < _shippingMethods.length - 1;
                                        return Column(
                                          children: [
                                            InkWell(
                                              onTap: () => setState(() {
                                                _selectedShippingMethodId = m.id;
                                                _quotedShipping = m.baseCost;
                                                _quotedShippingCurrency = m.currency;
                                              }),
                                              borderRadius: BorderRadius.circular(i == 0 ? 16 : 0),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Row(
                                                  children: [
                                                    Radio<String>(
                                                      value: m.id,
                                                      activeColor: AppTheme.primaryColor(context),
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            m.name,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                                            ),
                                                          ),
                                                          if (m.carrier.isNotEmpty)
                                                            Text(
                                                              '${m.carrier} · ${m.estimatedDays} days',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: AppTheme.foregroundColor(context).withValues(alpha: 0.5),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      costDisplay,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: m.baseCost == 0
                                                            ? Colors.green.shade600
                                                            : AppTheme.foregroundColor(context),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (showDivider)
                                              Divider(
                                                height: 1,
                                                indent: 16,
                                                color: AppTheme.foregroundColor(context).withValues(alpha: 0.08),
                                              ),
                                          ],
                                        );
                                      }),
                                    ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    DeliveryConstants.standardDeliveryDays,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.foregroundColor(
                                        context,
                                      ).withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                                // M4: Shipping error with retry
                                if (_shippingError != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _shippingError!,
                                            style: const TextStyle(
                                              color: AppTheme.destructive,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _refreshShippingQuote,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Promo code (optional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_appliedCouponCode != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Code "$_appliedCouponCode" applied',
                                            style: TextStyle(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Semantics(
                                          label: 'Remove coupon',
                                          button: true,
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              _appliedCouponCode = null;
                                              _appliedDiscount = null;
                                              _promoCode = '';
                                              _promoController.clear();
                                            }),
                                            child: Icon(Icons.close, size: 18, color: Colors.green.shade700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _promoController,
                                              textCapitalization: TextCapitalization.characters,
                                              decoration: InputDecoration(
                                                hintText: FormHints.promoCode,
                                                filled: true,
                                                fillColor: AppTheme.backgroundColor(context),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                errorText: _couponError,
                                              ),
                                              onChanged: (v) => setState(() => _promoCode = v),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton(
                                            onPressed: _couponValidating ? null : _applyPromoCode,
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: _couponValidating
                                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                : const Text('Apply'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Gift wrapping',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Builder(builder: (context) {
                                  // H5: Region-aware gift wrap label
                                  final giftLabelRegion = CurrencyScope.of(context).region;
                                  final giftLabel = giftLabelRegion == AppRegion.india
                                      ? 'Mark items as gifts (+₹${(_giftChargePerItemUsd * kUsdToInrDisplay).round()} per item)'
                                      : 'Mark items as gifts (+\$${_giftChargePerItemUsd.toStringAsFixed(2)} per item)';
                                  return Text(
                                    giftLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Column(
                                    children: List.generate(cart.items.length, (i) {
                                      final item = cart.items[i];
                                      final key = '${item.productId}-${item.size}';
                                      final isGift = _giftItemKeys.contains(key);
                                      final showDivider = i < cart.items.length - 1;
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            child: Row(
                                              children: [
                                                if (item.image.isNotEmpty)
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: CachedNetworkImage(
                                                      imageUrl: safeImageUrl(item.image),
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (_, __, ___) => Container(
                                                        width: 40,
                                                        height: 40,
                                                        color: AppTheme.mutedColor(context),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.mutedColor(context),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Icon(Icons.image, size: 20),
                                                  ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.productName,
                                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(
                                                        'Size: ${item.size}',
                                                        style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.card_giftcard_outlined, size: 16, color: isGift ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.4)),
                                                    const SizedBox(width: 4),
                                                    Semantics(
                                                      label: 'Gift wrap ${item.productName}',
                                                      toggled: isGift,
                                                      child: Switch(
                                                        value: isGift,
                                                        onChanged: (v) => setState(() {
                                                          if (v) {
                                                            _giftItemKeys.add(key);
                                                          } else {
                                                            _giftItemKeys.remove(key);
                                                          }
                                                        }),
                                                        activeThumbColor: AppTheme.primaryColor(context),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (showDivider)
                                            Divider(
                                              height: 1,
                                              indent: 16,
                                              color: AppTheme.foregroundColor(context).withValues(alpha: 0.08),
                                            ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Payment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Material(
                                  color: AppTheme.backgroundColor(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    onTap: _openPaymentMethodPicker,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.foregroundColor(
                                            context,
                                          ).withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            paymentMethodLeadingIcon(
                                              _selectedPaymentMethod,
                                            ),
                                            color: AppTheme.primaryColor(
                                              context,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Builder(builder: (context) {
                                              // M7: extract to avoid calling paymentMethodDetailLine twice
                                              final pmDetail = paymentMethodDetailLine(_selectedPaymentMethod);
                                              return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  paymentMethodLabel(
                                                    _selectedPaymentMethod,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (pmDetail != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    pmDetail,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppTheme.foregroundColor(
                                                            context,
                                                          ).withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                            }),
                                          ),
                                          Text(
                                            'Change',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Order summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.foregroundColor(
                                        context,
                                      ).withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Subtotal',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.foregroundColor(
                                                context,
                                              ).withValues(alpha: 0.6),
                                            ),
                                          ),
                                          Text(
                                            subtotalText,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Shipping',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.foregroundColor(
                                                context,
                                              ).withValues(alpha: 0.6),
                                            ),
                                          ),
                                          Text(
                                            shippingText,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.foregroundColor(
                                                context,
                                              ).withValues(alpha: 0.86),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (giftText != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Gift wrapping ($giftCount item${giftCount == 1 ? '' : 's'})',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                                              ),
                                            ),
                                            Text(
                                              giftText,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (discountText != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Coupon discount',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                            Text(
                                              discountText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Divider(
                                        height: 1,
                                        color: AppTheme.foregroundColor(
                                          context,
                                        ).withValues(alpha: 0.12),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total (approx)',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            totalText,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
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
                              padding: EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                16 + MediaQuery.paddingOf(context).bottom,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor(context),
                                border: Border(
                                  top: BorderSide(
                                    color: AppTheme.foregroundColor(
                                      context,
                                    ).withValues(alpha: 0.12),
                                  ),
                                ),
                              ),
                              // M1: Removed SafeArea wrapper — manual bottom padding already accounts for safe area inset.
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!_addressesLoading && _addresses.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.info_outline, size: 14, color: AppTheme.mutedForegroundColor(context)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Add a delivery address to place your order',
                                            style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed:
                                          _placing ||
                                              _addresses.isEmpty ||
                                              _selectedAddressId == null
                                          ? null
                                          : _placeOrder,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                      ),
                                      // H6: Dynamic label for card/UPI vs COD
                                      child: _placing
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : Text(
                                              (_selectedPaymentMethod == 'card' || _selectedPaymentMethod == 'upi')
                                                  ? 'Continue to payment'
                                                  : 'Place order',
                                            ),
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }

  Widget _buildDeliveryHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.chevron_left, size: 24),
              ),
            ),
          ),
          const Text(
            'Checkout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
