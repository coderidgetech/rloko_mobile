import 'package:equatable/equatable.dart';

/// Thrown when API returns an error. Message is user-friendly; do not expose stack traces in UI.
class ApiException extends Equatable implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];
}
