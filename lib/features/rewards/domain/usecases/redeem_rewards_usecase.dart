import '../entities/redeem_result.dart';
import '../repositories/rewards_repository.dart';

class RedeemRewardsUseCase {
  RedeemRewardsUseCase(this._repository);

  final RewardsRepository _repository;

  Future<RedeemResult> call(int points) => _repository.redeemPoints(points);
}
