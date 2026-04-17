import '../repositories/auth_repository.dart';

class SendLoginOtpUseCase {
  SendLoginOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String phone) => _repository.sendLoginOtp(phone);
}
