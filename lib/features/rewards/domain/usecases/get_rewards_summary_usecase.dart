import '../entities/rewards_summary.dart';
import '../repositories/rewards_repository.dart';

class GetRewardsSummaryUseCase {
  GetRewardsSummaryUseCase(this._repository);

  final RewardsRepository _repository;

  Future<RewardsSummary> call() => _repository.getSummary();
}
