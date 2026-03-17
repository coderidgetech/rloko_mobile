import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/delivery_constants.dart';
import '../../../../core/constants/form_hints.dart';
import '../../../../core/constants/stripe_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../payment/domain/usecases/create_payment_intent_usecase.dart';
import '../../../promotion/domain/usecases/validate_promotion_usecase.dart';
import '../../../../core/region/app_region.dart';
import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../bloc/cart_bloc.dart';
import '../../../address/domain/entities/address_entity.dart';
import '../../../address/domain/usecases/address_usecases.dart';
import '../../../address/presentation/pages/address_form_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/usecases/order_usecases.dart';
import '../../../product/presentation/widgets/empty_state.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _couponController = TextEditingController();
  String? _appliedCouponCode;
  double? _appliedCouponDiscount;
  String? _appliedCouponLabel;
  bool _showCouponInput = false;
  bool _applyingCoupon = false;

  // Checkout (single-page cart + checkout)
  List<AddressEntity> _addresses = [];
  bool _addressesLoading = true;
  String? _selectedAddressId;
  String _selectedPaymentMethod = 'cod';
  bool _placing = false;
  String? _error;
  bool _retriedAddressesAfterAuth = false;

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartLoadRequested());
    _loadAddresses();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

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
      if (kDebugMode) debugPrint('[CartPage] Loaded ${list.length} addresses');
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
      if (kDebugMode) debugPrint('[CartPage] _loadAddresses failed: $message\n$st');
      if (mounted) {
        setState(() {
          _addressesLoading = false;
          _error = message;
        });
      }
    }
  }

  Future<bool?> _showAddressFormSheet({String? addressId, AddressEntity? initialAddress}) async {
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

  void _showAddressPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
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
                  const Text('Delivery address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
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
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primaryColor(context).withValues(alpha: 0.08)
                                  : AppTheme.backgroundColor(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primaryColor(context)
                                    : AppTheme.foregroundColor(context).withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${a.addressLine}, ${a.city}, ${a.pincode}',
                                        style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(a.mobile, style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final result = await _showAddressFormSheet(addressId: a.id);
                                    if (result == true && mounted) {
                                      await _loadAddresses();
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    }
                                  },
                                  icon: Icon(Icons.edit_outlined, size: 20, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
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
                          color: AppTheme.primaryColor(context).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryColor(context).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 22, color: AppTheme.primaryColor(context)),
                            const SizedBox(width: 8),
                            Text('Add new address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primaryColor(context))),
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

  static String _paymentMethodLabel(String id) {
    switch (id) {
      case 'cod':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit / Debit Card';
      case 'upi':
        return 'UPI';
      default:
        return id;
    }
  }

  void _showPaymentPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
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
                    const Text('Payment method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    _PaymentOption(
                      id: 'cod',
                      label: _paymentMethodLabel('cod'),
                      subtitle: 'Pay when you receive your order',
                      icon: Icons.money_outlined,
                      selected: _selectedPaymentMethod == 'cod',
                      onTap: () {
                        setState(() => _selectedPaymentMethod = 'cod');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 8),
                    _PaymentOption(
                      id: 'card',
                      label: _paymentMethodLabel('card'),
                      subtitle: 'Pay securely via Stripe',
                      icon: Icons.credit_card_outlined,
                      selected: _selectedPaymentMethod == 'card',
                      enabled: kStripePublishableKey.isNotEmpty,
                      onTap: () {
                        setState(() => _selectedPaymentMethod = 'card');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 8),
                    _PaymentOption(
                      id: 'upi',
                      label: _paymentMethodLabel('upi'),
                      subtitle: 'Coming soon',
                      icon: Icons.phone_android_outlined,
                      selected: false,
                      enabled: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ShippingInfoEntity _addressToShipping(AddressEntity a, String userEmail) {
    final parts = a.name.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : a.name;
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
    final addressLine = a.addressLine + (a.addressLine2 != null && a.addressLine2!.isNotEmpty ? ', ${a.addressLine2}' : '');
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
      context.push('/login', extra: '/cart');
      return;
    }
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded || cartState.cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }
    if (_selectedAddressId == null || _addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a delivery address')));
      return;
    }

    if (_selectedPaymentMethod == 'card') {
      await _placeOrderWithStripe(authState, cartState);
    } else {
      await _placeOrderCod(authState, cartState);
    }
  }

  Future<void> _placeOrderCod(AuthAuthenticated authState, CartLoaded cartState) async {
    final selectedAddress = _addresses.firstWhere((a) => a.id == _selectedAddressId);
    final shipping = _addressToShipping(selectedAddress, authState.user.email);
    final orderItems = _cartToOrderItems(cartState.cart.items);
    final promoCode = _appliedCouponCode?.trim().isNotEmpty == true ? _appliedCouponCode!.trim() : null;

    setState(() {
      _placing = true;
      _error = null;
    });

    try {
      final order = await sl<CreateOrderUseCase>().call(
        items: orderItems,
        shippingInfo: shipping,
        paymentMethod: 'cod',
        promotionCode: promoCode,
      );
      if (kDebugMode) debugPrint('[CartPage] COD order placed: id=${order.id}');
      if (!mounted) return;
      context.read<CartBloc>().add(const CartClearRequested());
      context.go('/order-confirmation/${order.id}');
    } catch (e, st) {
      final message = e is ApiException ? e.message : (getApiException(e)?.message ?? e.toString());
      if (kDebugMode) debugPrint('[CartPage] _placeOrderCod failed: $message\n$st');
      if (mounted) {
        setState(() {
          _placing = false;
          _error = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppTheme.destructive),
        );
      }
    }
  }

  Future<void> _placeOrderWithStripe(AuthAuthenticated authState, CartLoaded cartState) async {
    if (kStripePublishableKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card payments are not configured. Please use Cash on Delivery.')),
      );
      return;
    }

    final selectedAddress = _addresses.firstWhere((a) => a.id == _selectedAddressId);
    final shipping = _addressToShipping(selectedAddress, authState.user.email);
    final orderItems = _cartToOrderItems(cartState.cart.items);
    final promoCode = _appliedCouponCode?.trim().isNotEmpty == true ? _appliedCouponCode!.trim() : null;

    final subtotal = cartState.cart.items.fold(0.0, (s, i) => s + i.price * i.quantity);
    final discount = _appliedCouponDiscount ?? 0.0;
    final total = subtotal - discount;

    setState(() {
      _placing = true;
      _error = null;
    });

    try {
      // Step 1: Create the order first so we have an order ID for the payment intent
      final order = await sl<CreateOrderUseCase>().call(
        items: orderItems,
        shippingInfo: shipping,
        paymentMethod: 'stripe',
        promotionCode: promoCode,
      );
      if (kDebugMode) debugPrint('[CartPage] Stripe order created: id=${order.id}');

      // Step 2: Create a PaymentIntent on the backend
      final currencyCode = CurrencyScope.maybeOf(context)?.region.currencyCode ?? 'USD';
      final intent = await sl<CreatePaymentIntentUseCase>().call(
        orderId: order.id,
        amount: total,
        currency: currencyCode,
      );
      if (kDebugMode) debugPrint('[CartPage] PaymentIntent created: id=${intent.id}');

      // Step 3: Initialize Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'Rloco',
          style: ThemeMode.system,
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
          ),
        ),
      );

      // Step 4: Present Payment Sheet (native Stripe UI)
      await Stripe.instance.presentPaymentSheet();

      // Payment confirmed
      if (kDebugMode) debugPrint('[CartPage] Stripe payment confirmed for order ${order.id}');
      if (!mounted) return;
      context.read<CartBloc>().add(const CartClearRequested());
      context.go('/order-confirmation/${order.id}');
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() {
        _placing = false;
        _error = null;
      });
      // User cancelled — silent dismiss; do not show error
      if (e.error.code == FailureCode.Canceled) return;
      final msg = e.error.localizedMessage ?? e.error.message ?? 'Payment failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.destructive),
      );
    } catch (e, st) {
      final message = e is ApiException ? e.message : (getApiException(e)?.message ?? e.toString());
      if (kDebugMode) debugPrint('[CartPage] _placeOrderWithStripe failed: $message\n$st');
      if (mounted) {
        setState(() {
          _placing = false;
          _error = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppTheme.destructive),
        );
      }
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _applyingCoupon = true);
    try {
      final cartState = context.read<CartBloc>().state;
      final subtotal = cartState is CartLoaded
          ? cartState.cart.items.fold(0.0, (s, i) => s + i.price * i.quantity)
          : 0.0;
      final result = await sl<ValidatePromotionUseCase>().call(code, subtotal);
      if (!mounted) return;
      if (result.valid && result.discount != null) {
        final promo = result.promotion;
        final label = promo != null
            ? (promo.type == 'percentage'
                ? '$code applied (${promo.value.toStringAsFixed(0)}% off)'
                : '$code applied (\$${result.discount!.toStringAsFixed(2)} off)')
            : '$code applied';
        setState(() {
          _appliedCouponCode = code;
          _appliedCouponDiscount = result.discount;
          _appliedCouponLabel = label;
          _showCouponInput = false;
          _applyingCoupon = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(label)),
        );
      } else {
        setState(() => _applyingCoupon = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or expired coupon code')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _applyingCoupon = false);
      final msg = getApiException(e)?.message ?? 'Failed to validate coupon';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _appliedCouponDiscount = null;
      _appliedCouponLabel = null;
      _couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coupon removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _retryAddressesIfAuthenticated();
          });
        }
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor(context),
          appBar: const AppHeader(showBackButton: false),
          bottomNavigationBar: const BottomNav(currentIndex: 4),
          body: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoading) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (state is CartError) {
                final isUnauth = state.message.contains('Sign in');
                return EmptyState(
                  title: isUnauth ? 'Sign in to view cart' : 'Could not load cart',
                  subtitle: state.message,
                  icon: Icons.shopping_bag_outlined,
                  actionLabel: isUnauth ? 'Sign in' : 'Retry',
                  onAction: () {
                    if (isUnauth) {
                      context.push('/login', extra: '/cart');
                    } else {
                      context.read<CartBloc>().add(const CartLoadRequested());
                    }
                  },
                );
              }
              if (state is CartLoaded) {
                if (state.cart.items.isEmpty) {
                  return EmptyState(
                    title: 'Your cart is empty',
                    subtitle: 'Start shopping and add items to your cart',
                    icon: Icons.shopping_bag_outlined,
                    actionLabel: 'Start Shopping',
                    onAction: () => context.go('/'),
                  );
                }
                return _CartContent(
                  items: state.cart.items,
                  appliedCouponCode: _appliedCouponCode,
                  appliedCouponDiscount: _appliedCouponDiscount,
                  appliedCouponLabel: _appliedCouponLabel,
                  showCouponInput: _showCouponInput,
                  applyingCoupon: _applyingCoupon,
                  couponController: _couponController,
                  onShowCouponInput: () => setState(() => _showCouponInput = true),
                  onApplyCoupon: _applyCoupon,
                  onRemoveCoupon: _removeCoupon,
                  addresses: _addresses,
                  selectedAddressId: _selectedAddressId,
                  addressesLoading: _addressesLoading,
                  placing: _placing,
                  error: _error,
                  isAuthenticated: authState is AuthAuthenticated,
                  onShowAddressPicker: _showAddressPickerSheet,
                  onAddAddress: () async {
                    final result = await _showAddressFormSheet();
                    if (result == true && mounted) await _loadAddresses();
                  },
                  selectedPaymentMethod: _selectedPaymentMethod,
                  paymentMethodLabel: _paymentMethodLabel(_selectedPaymentMethod),
                  onShowPaymentPicker: _showPaymentPickerSheet,
                  onPlaceOrder: _placeOrder,
                );
              }
              return EmptyState(
                title: 'Your cart is empty',
                icon: Icons.shopping_bag_outlined,
                actionLabel: 'Start Shopping',
                onAction: () => context.go('/'),
              );
            },
          ),
        );
      },
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({
    required this.items,
    required this.appliedCouponCode,
    required this.appliedCouponDiscount,
    this.appliedCouponLabel,
    required this.showCouponInput,
    required this.applyingCoupon,
    required this.couponController,
    required this.onShowCouponInput,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
    required this.addresses,
    required this.selectedAddressId,
    required this.addressesLoading,
    required this.placing,
    required this.error,
    required this.isAuthenticated,
    required this.onShowAddressPicker,
    required this.onAddAddress,
    required this.selectedPaymentMethod,
    required this.paymentMethodLabel,
    required this.onShowPaymentPicker,
    required this.onPlaceOrder,
  });

  final List<CartItemEntity> items;
  final String? appliedCouponCode;
  final double? appliedCouponDiscount;
  final String? appliedCouponLabel;
  final bool showCouponInput;
  final bool applyingCoupon;
  final TextEditingController couponController;
  final VoidCallback onShowCouponInput;
  final VoidCallback onApplyCoupon;
  final VoidCallback onRemoveCoupon;
  final List<AddressEntity> addresses;
  final String? selectedAddressId;
  final bool addressesLoading;
  final bool placing;
  final String? error;
  final bool isAuthenticated;
  final VoidCallback onShowAddressPicker;
  final VoidCallback onAddAddress;
  final String selectedPaymentMethod;
  final String paymentMethodLabel;
  final VoidCallback onShowPaymentPicker;
  final VoidCallback onPlaceOrder;

  double get _subtotal =>
      items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  double get _discount => appliedCouponDiscount ?? 0.0;
  double get _total => _subtotal - _discount;
  bool get _canPlaceOrder =>
      isAuthenticated &&
      addresses.isNotEmpty &&
      selectedAddressId != null &&
      !placing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return _CartItemTile(
                      item: item,
                      onMoveToWishlist: () {
                        context.read<CartBloc>().add(
                            CartRemoveItemRequested(item.productId, item.size));
                        context.read<WishlistBloc>().add(WishlistAddItemRequested(
                              item.productId,
                              productName: item.productName,
                              productImage: item.image,
                              productPrice: item.price,
                            ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Moved to wishlist')),
                        );
                      },
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
            // Coupon section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                  ),
                ),
                child: appliedCouponCode != null
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer,
                                size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                appliedCouponLabel ?? '$appliedCouponCode Applied',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: onRemoveCoupon,
                              child: Text(
                                'Remove',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red.shade600),
                              ),
                            ),
                          ],
                        ),
                      )
                    : showCouponInput
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: couponController,
                                  decoration: InputDecoration(
                                    hintText: FormHints.promoCode,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  onSubmitted: (_) => onApplyCoupon(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: applyingCoupon ? null : onApplyCoupon,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor(context),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: applyingCoupon
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text('Apply'),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: onShowCouponInput,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.local_offer,
                                      size: 18,
                                      color: AppTheme.foregroundColor(context)
                                          .withValues(alpha: 0.6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Apply Coupon',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.foregroundColor(context),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 18,
                                      color: AppTheme.foregroundColor(context)
                                          .withValues(alpha: 0.4)),
                                ],
                              ),
                            ),
                          ),
              ),
            ),
            // Delivery section (cart + checkout on one page)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primaryColor(context)),
                        const SizedBox(width: 8),
                        const Text('Delivery Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.destructive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(error!, style: const TextStyle(fontSize: 13, color: AppTheme.destructive)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (addressesLoading)
                      const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator(strokeWidth: 2)))
                    else if (addresses.isEmpty)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onAddAddress,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 22, color: AppTheme.primaryColor(context)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Add delivery address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.foregroundColor(context))),
                                      const SizedBox(height: 2),
                                      Text('Tap to add where you want your order delivered', style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onShowAddressPicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      addresses.firstWhere((a) => a.id == selectedAddressId).name,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      addresses.firstWhere((a) => a.id == selectedAddressId).addressLine,
                                      style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      addresses.firstWhere((a) => a.id == selectedAddressId).mobile,
                                      style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: onShowAddressPicker,
                                child: Text('Change', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor(context))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      DeliveryConstants.standardDeliveryDays,
                      style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
            // Payment section (Myntra-style: select on same page)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment_outlined, size: 20, color: AppTheme.primaryColor(context)),
                        const SizedBox(width: 8),
                        const Text('Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onShowPaymentPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                selectedPaymentMethod == 'cod' ? Icons.money_outlined : Icons.credit_card_outlined,
                                size: 22,
                                color: AppTheme.primaryColor(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    paymentMethodLabel,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  if (selectedPaymentMethod == 'cod')
                                    Text(
                                      'Pay when you receive your order',
                                      style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: onShowPaymentPicker,
                              child: Text('Change', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor(context))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 200),
            ),
          ],
        ),
        // Fixed bottom: price summary + Place order / Sign in
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                      Text(CurrencyScope.of(context).formatPrice(_subtotal, null), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  if (_discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
                        Text('-${CurrencyScope.of(context).formatPrice(_discount, null)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Divider(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(CurrencyScope.of(context).formatPrice(_total, null), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryColor(context))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: isAuthenticated
                        ? FilledButton(
                            onPressed: _canPlaceOrder ? onPlaceOrder : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor(context),
                              foregroundColor: AppTheme.primaryForegroundColor(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              elevation: 2,
                            ),
                            child: placing
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('Place order • ${CurrencyScope.of(context).formatPrice(_total, null)}'),
                          )
                        : FilledButton(
                            onPressed: () => context.push('/login', extra: '/cart'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor(context),
                              foregroundColor: AppTheme.primaryForegroundColor(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              elevation: 2,
                            ),
                            child: const Text('Sign in to place order'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Single cart row: image w-24 h-32 rounded-xl, name, size, price, quantity +/- , Heart, Trash (match React: py-4 border-b border-border/30)
class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onMoveToWishlist,
  });

  final CartItemEntity item;
  final VoidCallback onMoveToWishlist;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image w-24 h-32 = 96x128, rounded-xl
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 128,
              child: item.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: safeImageUrl(item.image),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: AppTheme.mutedColor(context),
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (_, __, ___) => Container(
                          color: AppTheme.mutedColor(context),
                          child: const Icon(Icons.image)),
                    )
                  : Container(
                      color: AppTheme.mutedColor(context),
                      child: const Icon(Icons.image),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${item.size}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyScope.of(context).formatPrice(item.price, item.priceInr),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor(context)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Quantity: minus, count, plus (rounded-full buttons)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          shape: const CircleBorder(),
                          side: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        onPressed: item.quantity > 1
                            ? () => context.read<CartBloc>().add(
                                CartUpdateItemRequested(
                                    item.productId, item.size, item.quantity - 1))
                            : null,
                        child: const Icon(Icons.remove, size: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          shape: const CircleBorder(),
                          side: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        onPressed: () => context.read<CartBloc>().add(
                            CartUpdateItemRequested(
                                item.productId, item.size, item.quantity + 1)),
                        child: const Icon(Icons.add, size: 14),
                      ),
                    ),
                    const Spacer(),
                    // Move to wishlist (Heart) and Remove (Trash)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Material(
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onMoveToWishlist,
                          customBorder: const CircleBorder(),
                          child: Center(
                              child: Icon(Icons.favorite_border,
                                  size: 14,
                                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Material(
                        color: const Color(0xFFFEF2F2),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () {
                            context.read<CartBloc>().add(
                                CartRemoveItemRequested(item.productId, item.size));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from cart')),
                            );
                          },
                          customBorder: const CircleBorder(),
                          child: const Center(
                              child: Icon(Icons.delete_outline,
                                  size: 14, color: Color(0xFFEF4444))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One payment option row in the payment method bottom sheet.
class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor(context).withValues(alpha: 0.08)
                : AppTheme.backgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor(context)
                  : AppTheme.foregroundColor(context).withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.15)).withValues(alpha: enabled ? 1 : 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: selected ? AppTheme.primaryForegroundColor(context) : AppTheme.foregroundColor(context).withValues(alpha: enabled ? 0.8 : 0.4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foregroundColor(context).withValues(alpha: enabled ? 1 : 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.foregroundColor(context).withValues(alpha: enabled ? 0.6 : 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 22, color: AppTheme.primaryColor(context))
              else if (!enabled)
                Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
