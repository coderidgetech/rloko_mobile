import '../entities/redeem_result.dart';
import '../entities/rewards_summary.dart';
import '../entities/rewards_transaction.dart';

abstract class RewardsRepository {
  Future<RewardsSummary> getSummary();

  Future<({List<RewardsTransaction> transactions, int total})> getTransactions({
    int limit = 20,
    int skip = 0,
  });

  Future<RedeemResult> redeemPoints(int points);
}
