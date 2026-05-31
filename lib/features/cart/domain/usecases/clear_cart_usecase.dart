import '../repositories/cart_repository.dart';

class ClearCartUseCase {
  ClearCartUseCase(this._repo);
  final CartRepository _repo;
  Future<void> call() => _repo.clearCart();
}
