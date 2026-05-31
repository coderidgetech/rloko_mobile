import '../../domain/entities/redeem_result.dart';
import '../../domain/entities/rewards_summary.dart';
import '../../domain/entities/rewards_transaction.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../datasources/rewards_remote_datasource.dart';

class RewardsRepositoryImpl implements RewardsRepository {
  RewardsRepositoryImpl(this._dataSource);

  final RewardsRemoteDataSource _dataSource;

  @override
  Future<RewardsSummary> getSummary() => _dataSource.getSummary();

  @override
  Future<({List<RewardsTransaction> transactions, int total})> getTransactions({
    int limit = 20,
    int skip = 0,
  }) =>
      _dataSource.getTransactions(limit: limit, skip: skip);

  @override
  Future<RedeemResult> redeemPoints(int points) =>
      _dataSource.redeemPoints(points);
}
