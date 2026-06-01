import 'package:equatable/equatable.dart';

class ValidatePromotionResult extends Equatable {
  const ValidatePromotionResult({
    required this.discount,
    required this.code,
    required this.isValid,
    this.message,
  });

  final double discount;
  final String code;
  final bool isValid;
  final String? message;

  @override
  List<Object?> get props => [discount, code, isValid, message];
}
