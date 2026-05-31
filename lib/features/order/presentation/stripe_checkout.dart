import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/stripe_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../cart/domain/entities/cart_item_entity.dart';
import '../../cart/presentation/bloc/cart_bloc.dart';
import '../../address/domain/entities/address_entity.dart';
import '../../payment/domain/usecases/create_payment_intent_usecase.dart';
import '../domain/entities/order_entity.dart';
import '../domain/usecases/order_usecases.dart';

/// Matches web: POST /orders with `payment_method` `card` or `upi`, then POST /payments/intent, then Stripe sheet.
Future<void> runStripeCheckout({
  required BuildContext context,
  required AuthAuthenticated authState,
  required List<CartItemEntity> cartItems,
  required AddressEntity selectedAddress,
  required String orderPaymentMethod,
  String? promotionCode,
}) async {
  assert(
    orderPaymentMethod == 'card' || orderPaymentMethod == 'upi',
    'orderPaymentMethod must be card or upi',
  );

  if (kStripePublishableKey.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Online payments are not configured. Please use Cash on Delivery.',
        ),
      ),
    );
    return;
  }

  // Capture before async gaps so cart clear + navigation always fire even if
  // the calling widget unmounts while the payment sheet is open.
  final cartBloc = context.read<CartBloc>();
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final shipping = _addressToShipping(selectedAddress, authState.user.email);
  final orderItems = _cartToOrderItems(cartItems);

  try {
    final order = await sl<CreateOrderUseCase>().call(
      items: orderItems,
      shippingInfo: shipping,
      paymentMethod: orderPaymentMethod,
      promotionCode: promotionCode,
    );
    if (kDebugMode) {
      debugPrint(
        '[StripeCheckout] order id=${order.id} payment_method=$orderPaymentMethod',
      );
    }

    final payCurrency = _stripeCurrencyForCountry(shipping.country);
    final intent = await sl<CreatePaymentIntentUseCase>().call(
      orderId: order.id,
      amount: order.total,
      currency: payCurrency,
      paymentMethod: orderPaymentMethod,
    );
    if (kDebugMode) {
      debugPrint('[StripeCheckout] PaymentIntent id=${intent.id}');
    }

    final billingName =
        '${shipping.firstName} ${shipping.lastName}'.trim();
    final billing = BillingDetails(
      name: billingName.isEmpty ? null : billingName,
      email: shipping.email.trim().isEmpty ? null : shipping.email.trim(),
      phone: shipping.phone.trim().isEmpty ? null : shipping.phone.trim(),
      address: Address(
        city: shipping.city.trim().isEmpty ? null : shipping.city.trim(),
        country: _stripeCountryCodeForShipping(shipping.country),
        line1: shipping.address.trim().isEmpty ? null : shipping.address.trim(),
        line2: null,
        postalCode:
            shipping.zipCode.trim().isEmpty ? null : shipping.zipCode.trim(),
        state: shipping.state.trim().isEmpty ? null : shipping.state.trim(),
      ),
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: intent.clientSecret,
        merchantDisplayName: 'Rloco',
        style: ThemeMode.system,
        billingDetails: billing,
        billingDetailsCollectionConfiguration:
            const BillingDetailsCollectionConfiguration(
          name: CollectionMode.never,
          email: CollectionMode.never,
          phone: CollectionMode.never,
          address: AddressCollectionMode.never,
          attachDefaultsToPaymentMethod: true,
        ),
        paymentMethodOrder: orderPaymentMethod == 'upi'
            ? <String>['upi']
            : <String>['card'],
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    // Use pre-captured references — safe regardless of widget mount state.
    cartBloc.add(const CartClearRequested());
    router.go('/order-confirmation/${order.id}');
  } on StripeException catch (e) {
    if (e.error.code == FailureCode.Canceled) return;
    final msg = e.error.localizedMessage ?? e.error.message ?? 'Payment failed';
    messenger.showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.destructive),
    );
  } catch (e, st) {
    final message = e is ApiException
        ? e.message
        : (getApiException(e)?.message ?? e.toString());
    if (kDebugMode) {
      debugPrint('[StripeCheckout] $message\n$st');
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.destructive),
    );
  }
}

ShippingInfoEntity _addressToShipping(AddressEntity a, String userEmail) {
  final parts = a.name.trim().split(RegExp(r'\s+'));
  final firstName = parts.isNotEmpty ? parts.first : a.name;
  final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
  final addressLine =
      a.addressLine +
      (a.addressLine2 != null && a.addressLine2!.isNotEmpty
          ? ', ${a.addressLine2}'
          : '');
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
      .map(
        (e) => OrderItemEntity(
          productId: e.productId,
          productName: e.productName,
          image: e.image,
          price: e.price,
          size: e.size,
          quantity: e.quantity,
        ),
      )
      .toList();
}

String _stripeCurrencyForCountry(String country) {
  final c = country.trim().toLowerCase();
  if (c == 'in' || c == 'india' || c.contains('india')) {
    return 'inr';
  }
  return 'usd';
}

/// Two-letter ISO for Stripe [Address.country].
String _stripeCountryCodeForShipping(String country) {
  final c = country.trim().toLowerCase();
  if (c == 'in' || c == 'india' || c.contains('india')) return 'IN';
  if (c == 'us' || c == 'usa' || c.contains('united states')) return 'US';
  if (country.trim().length == 2) return country.trim().toUpperCase();
  return 'IN';
}
