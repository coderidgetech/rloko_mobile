class PaymentIntentEntity {
  const PaymentIntentEntity({
    required this.id,
    required this.clientSecret,
    required this.gateway,
    required this.amount,
    required this.currency,
  });

  final String id;
  final String clientSecret;
  final String gateway;
  final double amount;
  final String currency;
}
