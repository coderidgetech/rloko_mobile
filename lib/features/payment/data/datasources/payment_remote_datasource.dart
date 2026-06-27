import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/payment_intent_entity.dart';

class PaymentRemoteDataSource {
  PaymentRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<PaymentIntentEntity> createPaymentIntent({
    required String orderId,
    required double amount,
    required String currency,
    String gateway = 'stripe',
    String paymentMethod = 'card',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payments/intent',
      data: {
        'order_id': orderId,
        'amount': amount,
        'currency': currency.toLowerCase(),
        'gateway': gateway,
        'payment_method': paymentMethod,
      },
    );
    final data = response.data;
    if (kDebugMode) debugPrint('[PaymentRemoteDataSource] intent response: $data');
    if (data == null) throw Exception('Invalid response from payment intent');

    final clientSecret = data['client_secret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('No client_secret returned from payment intent');
    }

    return PaymentIntentEntity(
      id: (data['id'] as String?) ?? '',
      clientSecret: clientSecret,
      gateway: (data['gateway'] as String?) ?? gateway,
      amount: (data['amount'] as num?)?.toDouble() ?? amount,
      currency: (data['currency'] as String?) ?? currency,
    );
  }

  /// Confirms a succeeded payment with the backend so the order is marked paid.
  /// Without this (and absent a reachable Stripe webhook) the order stays pending
  /// and gets cancelled by the abandoned-order sweeper.
  Future<void> processPayment({
    required String paymentIntentId,
    String gateway = 'stripe',
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/payments/process',
      data: {
        'payment_intent_id': paymentIntentId,
        'gateway': gateway,
      },
    );
  }
}
