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
import '../domain/utils/order_mappers.dart';

/// Matches web: POST /orders with `payment_method` `card` or `upi`, then POST /payments/intent, then Stripe sheet.
Future<void> runStripeCheckout({
  required BuildContext context,
  required AuthAuthenticated authState,
  required List<CartItemEntity> cartItems,
  required AddressEntity selectedAddress,
  required String orderPaymentMethod,
  String? promotionCode,
  Set<String> giftItemKeys = const {},
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

  final shipping = addressToShipping(selectedAddress, authState.user.email);
  final orderItems = cartItemsToOrderItems(cartItems, giftItemKeys: giftItemKeys);

  OrderEntity? order;
  try {
    order = await sl<CreateOrderUseCase>().call(
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

    final payCurrency = stripeCurrencyForCountry(shipping.country);
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
        country: stripeCountryCodeForShipping(shipping.country),
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
    if (e.error.code == FailureCode.Canceled) {
      // User cancelled — void the order silently.
      if (order != null) {
        try {
          await sl<CancelOrderUseCase>().call(order.id, reason: 'payment_cancelled');
        } catch (_) {}
      }
      return;
    }
    // Payment failed — cancel the order and show error.
    if (order != null) {
      try {
        await sl<CancelOrderUseCase>().call(order.id, reason: 'payment_failed');
      } catch (_) {}
    }
    final msg = e.error.localizedMessage ?? e.error.message ?? 'Payment failed';
    messenger.showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.destructive),
    );
  } catch (e, st) {
    if (order != null) {
      try {
        await sl<CancelOrderUseCase>().call(order.id, reason: 'payment_error');
      } catch (_) {}
    }
    final message = e is ApiException
        ? e.message
        : (getApiException(e)?.message ?? e.toString());
    if (kDebugMode) debugPrint('[StripeCheckout] Unhandled error: $e\n$st');
    // TODO(E7): Add FirebaseCrashlytics.instance.recordError(e, st) when crashlytics is configured
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.destructive),
    );
  }
}
