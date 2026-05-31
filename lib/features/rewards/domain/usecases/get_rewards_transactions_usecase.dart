import '../entities/rewards_transaction.dart';
import '../repositories/rewards_repository.dart';

class GetRewardsTransactionsUseCase {
  GetRewardsTransactionsUseCase(this._repository);

  final RewardsRepository _repository;

  Future<({List<RewardsTransaction> transactions, int total})> call({
    int limit = 20,
    int skip = 0,
  }) =>
      _repository.getTransactions(limit: limit, skip: skip);
}
