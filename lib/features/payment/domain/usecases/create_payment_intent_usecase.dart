import '../../../payment/data/datasources/payment_remote_datasource.dart';
import '../entities/payment_intent_entity.dart';

class CreatePaymentIntentUseCase {
  CreatePaymentIntentUseCase(this._dataSource);

  final PaymentRemoteDataSource _dataSource;

  Future<PaymentIntentEntity> call({
    required String orderId,
    required double amount,
    required String currency,
    String paymentMethod = 'card',
  }) =>
      _dataSource.createPaymentIntent(
        orderId: orderId,
        amount: amount,
        currency: currency,
        gateway: 'stripe',
        paymentMethod: paymentMethod,
      );
}
