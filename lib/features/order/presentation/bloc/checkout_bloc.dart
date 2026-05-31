import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/dio_client.dart';
import '../../../address/domain/entities/address_entity.dart';
import '../../../address/domain/usecases/address_usecases.dart';
import '../../../promotion/domain/repositories/promotion_repository.dart';
import '../../../promotion/domain/usecases/validate_promotion_usecase.dart';
import '../../../shipping/domain/entities/calculate_shipping_params.dart';
import '../../../shipping/domain/entities/shipping_method_entity.dart';
import '../../../shipping/domain/usecases/calculate_shipping_usecase.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/order_usecases.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

/// Load the user's saved addresses and compute an initial shipping quote.
class CheckoutAddressesLoadRequested extends CheckoutEvent {
  const CheckoutAddressesLoadRequested({
    this.cartSubtotal = 0.0,
    this.cartWeightLb,
  });

  /// Cart subtotal in USD — used to request a shipping quote after addresses load.
  final double cartSubtotal;

  /// Total weight in lbs — used for the initial shipping quote.
  final double? cartWeightLb;

  @override
  List<Object?> get props => [cartSubtotal, cartWeightLb];
}

/// User picked a different delivery address. Triggers a new shipping quote.
class CheckoutAddressSelected extends CheckoutEvent {
  const CheckoutAddressSelected({
    required this.addressId,
    this.cartSubtotal = 0.0,
    this.cartWeightLb,
    this.userEmail = '',
  });

  final String addressId;
  final double cartSubtotal;
  final double? cartWeightLb;
  final String userEmail;

  @override
  List<Object?> get props => [addressId, cartSubtotal, cartWeightLb, userEmail];
}

/// User picked a shipping method from the quoted list.
class CheckoutShippingMethodSelected extends CheckoutEvent {
  const CheckoutShippingMethodSelected(this.methodId);

  final String methodId;

  @override
  List<Object?> get props => [methodId];
}

/// User applied a promo/coupon code.
class CheckoutPromoApplied extends CheckoutEvent {
  const CheckoutPromoApplied({required this.code, required this.cartSubtotal});

  final String code;
  final double cartSubtotal;

  @override
  List<Object?> get props => [code, cartSubtotal];
}

/// User cleared/removed the applied promo code.
class CheckoutPromoCleared extends CheckoutEvent {
  const CheckoutPromoCleared();
}

/// User changed the payment method (e.g. 'cod', 'card', 'upi').
class CheckoutPaymentMethodChanged extends CheckoutEvent {
  const CheckoutPaymentMethodChanged(this.method);

  final String method;

  @override
  List<Object?> get props => [method];
}

/// User tapped "Place order" for COD flow.
///
/// For card/UPI the page handles Stripe directly; this event is for COD only.
class CheckoutOrderPlaced extends CheckoutEvent {
  const CheckoutOrderPlaced({
    required this.items,
    required this.shippingInfo,
    required this.paymentMethod,
    this.promotionCode,
    this.paymentInfo,
  });

  final List<OrderItemEntity> items;
  final ShippingInfoEntity shippingInfo;
  final String paymentMethod;
  final String? promotionCode;
  final Map<String, dynamic>? paymentInfo;

  @override
  List<Object?> get props =>
      [items, shippingInfo, paymentMethod, promotionCode];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

/// Main "ready" state that drives the checkout UI.
class CheckoutReady extends CheckoutState {
  const CheckoutReady({
    required this.addresses,
    this.selectedAddressId,
    this.shippingMethods = const [],
    this.selectedShippingMethodId,
    this.quotedShipping = const [],
    this.appliedCouponCode,
    this.couponDiscount,
    this.promoError,
    this.paymentMethod = 'cod',
    this.placing = false,
    this.error,
  });

  final List<AddressEntity> addresses;
  final String? selectedAddressId;
  final List<ShippingMethodEntity> shippingMethods;
  final String? selectedShippingMethodId;

  /// All quoted shipping options returned from the last CalculateShipping call.
  final List<ShippingMethodEntity> quotedShipping;

  final String? appliedCouponCode;
  final double? couponDiscount;
  final String? promoError;
  final String paymentMethod;
  final bool placing;
  final String? error;

  CheckoutReady copyWith({
    List<AddressEntity>? addresses,
    Object? selectedAddressId = _sentinel,
    List<ShippingMethodEntity>? shippingMethods,
    Object? selectedShippingMethodId = _sentinel,
    List<ShippingMethodEntity>? quotedShipping,
    Object? appliedCouponCode = _sentinel,
    Object? couponDiscount = _sentinel,
    Object? promoError = _sentinel,
    String? paymentMethod,
    bool? placing,
    Object? error = _sentinel,
  }) {
    return CheckoutReady(
      addresses: addresses ?? this.addresses,
      selectedAddressId: selectedAddressId == _sentinel
          ? this.selectedAddressId
          : selectedAddressId as String?,
      shippingMethods: shippingMethods ?? this.shippingMethods,
      selectedShippingMethodId: selectedShippingMethodId == _sentinel
          ? this.selectedShippingMethodId
          : selectedShippingMethodId as String?,
      quotedShipping: quotedShipping ?? this.quotedShipping,
      appliedCouponCode: appliedCouponCode == _sentinel
          ? this.appliedCouponCode
          : appliedCouponCode as String?,
      couponDiscount: couponDiscount == _sentinel
          ? this.couponDiscount
          : couponDiscount as double?,
      promoError:
          promoError == _sentinel ? this.promoError : promoError as String?,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      placing: placing ?? this.placing,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => [
        addresses,
        selectedAddressId,
        shippingMethods,
        selectedShippingMethodId,
        quotedShipping,
        appliedCouponCode,
        couponDiscount,
        promoError,
        paymentMethod,
        placing,
        error,
      ];
}

/// Order placed successfully — carry the new order ID so the page can navigate.
class CheckoutOrderSuccess extends CheckoutState {
  const CheckoutOrderSuccess(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// Fatal / top-level error (e.g. failed to load addresses).
class CheckoutError extends CheckoutState {
  const CheckoutError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// Private sentinel so copyWith can distinguish null from "not provided".
const Object _sentinel = Object();

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc({
    required ListAddressesUseCase listAddressesUseCase,
    required CalculateShippingUseCase calculateShippingUseCase,
    required ValidatePromotionUseCase validatePromotionUseCase,
    required CreateOrderUseCase createOrderUseCase,
  })  : _listAddresses = listAddressesUseCase,
        _calculateShipping = calculateShippingUseCase,
        _validatePromotion = validatePromotionUseCase,
        _createOrder = createOrderUseCase,
        super(const CheckoutInitial()) {
    on<CheckoutAddressesLoadRequested>(_onAddressesLoadRequested);
    on<CheckoutAddressSelected>(_onAddressSelected);
    on<CheckoutShippingMethodSelected>(_onShippingMethodSelected);
    on<CheckoutPromoApplied>(_onPromoApplied);
    on<CheckoutPromoCleared>(_onPromoCleared);
    on<CheckoutPaymentMethodChanged>(_onPaymentMethodChanged);
    on<CheckoutOrderPlaced>(_onOrderPlaced);
  }

  final ListAddressesUseCase _listAddresses;
  final CalculateShippingUseCase _calculateShipping;
  final ValidatePromotionUseCase _validatePromotion;
  final CreateOrderUseCase _createOrder;

  // -------------------------------------------------------------------------
  // Handlers
  // -------------------------------------------------------------------------

  Future<void> _onAddressesLoadRequested(
    CheckoutAddressesLoadRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    final current = state;
    // Preserve existing Ready state fields (payment method, promo, etc.) while
    // we reload addresses so the UI doesn't flicker back to blank.
    if (current is CheckoutReady) {
      emit(current.copyWith(error: null));
    } else {
      emit(const CheckoutLoading());
    }

    try {
      final addresses = await _listAddresses.call();
      if (kDebugMode) {
        debugPrint('[CheckoutBloc] Loaded ${addresses.length} addresses');
      }

      final defaultId =
          addresses.where((a) => a.isDefault).firstOrNull?.id ??
          addresses.firstOrNull?.id;

      final base = current is CheckoutReady
          ? current.copyWith(
              addresses: addresses,
              selectedAddressId: defaultId,
              error: null,
            )
          : CheckoutReady(
              addresses: addresses,
              selectedAddressId: defaultId,
            );

      emit(base);

      // Fetch a shipping quote for the default address if we have one.
      if (defaultId != null && addresses.isNotEmpty) {
        await _fetchShippingQuote(
          emit: emit,
          addresses: addresses,
          selectedAddressId: defaultId,
          cartSubtotal: event.cartSubtotal,
          cartWeightLb: event.cartWeightLb,
          userEmail: '',
        );
      }
    } catch (e, st) {
      final message = _extractMessage(e);
      if (kDebugMode) {
        debugPrint('[CheckoutBloc] _onAddressesLoadRequested failed: $message\n$st');
      }
      emit(CheckoutError(message));
    }
  }

  Future<void> _onAddressSelected(
    CheckoutAddressSelected event,
    Emitter<CheckoutState> emit,
  ) async {
    final current = state;
    if (current is! CheckoutReady) return;

    emit(current.copyWith(
      selectedAddressId: event.addressId,
      error: null,
    ));

    await _fetchShippingQuote(
      emit: emit,
      addresses: current.addresses,
      selectedAddressId: event.addressId,
      cartSubtotal: event.cartSubtotal,
      cartWeightLb: event.cartWeightLb,
      userEmail: event.userEmail,
    );
  }

  void _onShippingMethodSelected(
    CheckoutShippingMethodSelected event,
    Emitter<CheckoutState> emit,
  ) {
    final current = state;
    if (current is! CheckoutReady) return;

    final method = current.quotedShipping
        .where((m) => m.id == event.methodId)
        .firstOrNull;

    if (method == null) return;

    emit(current.copyWith(
      selectedShippingMethodId: event.methodId,
      shippingMethods: current.quotedShipping,
    ));
  }

  Future<void> _onPromoApplied(
    CheckoutPromoApplied event,
    Emitter<CheckoutState> emit,
  ) async {
    final current = state;
    if (current is! CheckoutReady) return;

    final code = event.code.trim().toUpperCase();
    if (code.isEmpty) return;

    // Show inline "validating" state without losing other fields.
    emit(current.copyWith(promoError: null));

    try {
      final ValidatePromotionResult result =
          await _validatePromotion.call(code, event.cartSubtotal);

      if (kDebugMode) {
        debugPrint(
          '[CheckoutBloc] Promo "$code" valid=${result.valid} '
          'discount=${result.discount}',
        );
      }

      final latest = state;
      if (latest is! CheckoutReady) return;

      if (result.valid && result.discount != null && result.discount! > 0) {
        emit(latest.copyWith(
          appliedCouponCode: code,
          couponDiscount: result.discount,
          promoError: null,
        ));
      } else {
        emit(latest.copyWith(
          appliedCouponCode: null,
          couponDiscount: null,
          promoError: 'Invalid or expired coupon code',
        ));
      }
    } catch (e, st) {
      final message = _extractMessage(e);
      if (kDebugMode) {
        debugPrint('[CheckoutBloc] _onPromoApplied failed: $message\n$st');
      }
      final latest = state;
      if (latest is CheckoutReady) {
        emit(latest.copyWith(promoError: message));
      }
    }
  }

  void _onPromoCleared(
    CheckoutPromoCleared event,
    Emitter<CheckoutState> emit,
  ) {
    final current = state;
    if (current is! CheckoutReady) return;

    emit(current.copyWith(
      appliedCouponCode: null,
      couponDiscount: null,
      promoError: null,
    ));
  }

  void _onPaymentMethodChanged(
    CheckoutPaymentMethodChanged event,
    Emitter<CheckoutState> emit,
  ) {
    final current = state;
    if (current is! CheckoutReady) return;

    emit(current.copyWith(paymentMethod: event.method));
  }

  Future<void> _onOrderPlaced(
    CheckoutOrderPlaced event,
    Emitter<CheckoutState> emit,
  ) async {
    final current = state;
    if (current is! CheckoutReady) return;

    emit(current.copyWith(placing: true, error: null));

    try {
      final order = await _createOrder.call(
        items: event.items,
        shippingInfo: event.shippingInfo,
        paymentMethod: event.paymentMethod,
        paymentInfo: event.paymentInfo,
        promotionCode: event.promotionCode,
      );

      if (kDebugMode) {
        debugPrint('[CheckoutBloc] Order placed: id=${order.id}');
      }

      emit(CheckoutOrderSuccess(order.id));
    } catch (e, st) {
      final message = _extractMessage(e);
      if (kDebugMode) {
        debugPrint('[CheckoutBloc] _onOrderPlaced failed: $message\n$st');
      }
      final latest = state;
      if (latest is CheckoutReady) {
        emit(latest.copyWith(placing: false, error: message));
      } else {
        // In case state was already mutated, fall back to a fresh error state.
        emit(current.copyWith(placing: false, error: message));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Fetch shipping rates for [selectedAddressId] and update the current
  /// [CheckoutReady] state with the result.
  Future<void> _fetchShippingQuote({
    required Emitter<CheckoutState> emit,
    required List<AddressEntity> addresses,
    required String selectedAddressId,
    required double cartSubtotal,
    double? cartWeightLb,
    String userEmail = '',
  }) async {
    final current = state;
    if (current is! CheckoutReady) return;

    AddressEntity? addr;
    try {
      addr = addresses.firstWhere((a) => a.id == selectedAddressId);
    } catch (_) {
      return;
    }

    final params = _buildShippingParams(
      addr,
      userEmail: userEmail,
      cartSubtotal: cartSubtotal,
      cartWeightLb: cartWeightLb,
    );

    try {
      final methods = await _calculateShipping.call(params);

      if (kDebugMode) {
        debugPrint(
          '[CheckoutBloc] Got ${methods.length} shipping method(s) '
          'for address ${addr.id}',
        );
      }

      final latest = state;
      if (latest is! CheckoutReady) return;

      if (methods.isNotEmpty) {
        // Keep the previously selected method when it is still available.
        final keepId = latest.selectedShippingMethodId != null &&
                methods.any((m) => m.id == latest.selectedShippingMethodId)
            ? latest.selectedShippingMethodId
            : methods.first.id;

        emit(latest.copyWith(
          quotedShipping: methods,
          shippingMethods: methods,
          selectedShippingMethodId: keepId,
        ));
      } else {
        emit(latest.copyWith(
          quotedShipping: [],
          shippingMethods: [],
          selectedShippingMethodId: null,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CheckoutBloc] shipping quote failed: $e');
      }
      // Non-fatal — silently clear the quote so the UI can fall back to a
      // flat rate or show an "unavailable" message.
      final latest = state;
      if (latest is CheckoutReady) {
        emit(latest.copyWith(
          quotedShipping: [],
          shippingMethods: [],
          selectedShippingMethodId: null,
        ));
      }
    }
  }

  CalculateShippingParams _buildShippingParams(
    AddressEntity addr, {
    required String userEmail,
    required double cartSubtotal,
    double? cartWeightLb,
  }) {
    final parts = addr.name.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : addr.name;
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
    final addressLine = addr.addressLine +
        (addr.addressLine2 != null && addr.addressLine2!.isNotEmpty
            ? ', ${addr.addressLine2}'
            : '');

    return CalculateShippingParams(
      country: addr.country,
      state: addr.state,
      city: addr.city,
      address: addressLine,
      postalCode: addr.pincode,
      firstName: firstName,
      lastName: lastName,
      email: userEmail.isNotEmpty ? userEmail : null,
      phone: addr.mobile,
      subtotal: cartSubtotal,
      weight: (cartWeightLb != null && cartWeightLb > 0) ? cartWeightLb : null,
    );
  }

  static String _extractMessage(Object e) {
    final api = getApiException(e);
    if (api != null) return api.message;
    return e.toString();
  }
}
