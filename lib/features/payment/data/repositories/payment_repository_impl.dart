import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/payment_intent_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._dataSource);

  final PaymentRemoteDataSource _dataSource;

  @override
  Future<PaymentIntentEntity> createPaymentIntent({
    required String orderId,
    required double amount,
    required String currency,
    String gateway = 'stripe',
    String paymentMethod = 'card',
  }) async {
    try {
      return await _dataSource.createPaymentIntent(
        orderId: orderId,
        amount: amount,
        currency: currency,
        gateway: gateway,
        paymentMethod: paymentMethod,
      );
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
