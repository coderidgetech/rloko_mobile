import '../entities/payment_intent_entity.dart';

abstract class PaymentRepository {
  Future<PaymentIntentEntity> createPaymentIntent({
    required String orderId,
    required double amount,
    required String currency,
    String gateway = 'stripe',
    String paymentMethod = 'card',
  });
}
