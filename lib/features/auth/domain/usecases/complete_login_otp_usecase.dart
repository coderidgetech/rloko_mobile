import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class CompleteLoginOtpUseCase {
  CompleteLoginOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call(String phone, String code) =>
      _repository.completeLoginOtp(phone, code);
}
