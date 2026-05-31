import '../entities/payment_intent_entity.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentIntentUseCase {
  CreatePaymentIntentUseCase(this._repository);

  final PaymentRepository _repository;

  Future<PaymentIntentEntity> call({
    required String orderId,
    required double amount,
    required String currency,
    String paymentMethod = 'card',
  }) =>
      _repository.createPaymentIntent(
        orderId: orderId,
        amount: amount,
        currency: currency,
        gateway: 'stripe',
        paymentMethod: paymentMethod,
      );
}
