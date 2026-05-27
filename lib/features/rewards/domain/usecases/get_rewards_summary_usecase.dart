import '../entities/rewards_summary.dart';
import '../../data/datasources/rewards_remote_datasource.dart';

class GetRewardsSummaryUseCase {
  GetRewardsSummaryUseCase(this._ds);

  final RewardsRemoteDataSource _ds;

  Future<RewardsSummary> call() => _ds.getSummary();
}
