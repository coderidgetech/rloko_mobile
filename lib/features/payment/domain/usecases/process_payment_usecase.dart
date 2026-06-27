import '../repositories/payment_repository.dart';

/// Confirms a succeeded Stripe payment with the backend so the order is marked paid
/// (mirrors the web app's POST /payments/process). Must be called after the Stripe
/// payment sheet completes, otherwise the order stays pending and is cancelled by
/// the abandoned-order sweeper.
class ProcessPaymentUseCase {
  ProcessPaymentUseCase(this._repository);

  final PaymentRepository _repository;

  Future<void> call({required String paymentIntentId}) =>
      _repository.processPayment(paymentIntentId: paymentIntentId, gateway: 'stripe');
}
