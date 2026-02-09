import 'package:equatable/equatable.dart';

import '../network/api_exception.dart';

/// Re-expose API errors for domain/presentation.
class AppException extends Equatable implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  factory AppException.fromApi(ApiException e) =>
      AppException(e.message, code: e.code);

  @override
  List<Object?> get props => [message, code];
}
