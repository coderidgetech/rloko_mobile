import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rewards_summary.dart';
import '../../domain/entities/rewards_transaction.dart';
import '../../domain/usecases/get_rewards_summary_usecase.dart';
import '../../domain/usecases/get_rewards_transactions_usecase.dart';
import '../../domain/usecases/redeem_rewards_usecase.dart';

// Events
abstract class RewardsEvent extends Equatable {
  const RewardsEvent();
  @override
  List<Object?> get props => [];
}

class RewardsLoadRequested extends RewardsEvent {
  const RewardsLoadRequested();
}

class RewardsRedeemRequested extends RewardsEvent {
  const RewardsRedeemRequested(this.points);
  final int points;
  @override
  List<Object?> get props => [points];
}

// States
abstract class RewardsState extends Equatable {
  const RewardsState();
  @override
  List<Object?> get props => [];
}

class RewardsInitial extends RewardsState {
  const RewardsInitial();
}

class RewardsLoading extends RewardsState {
  const RewardsLoading();
}

class RewardsLoaded extends RewardsState {
  const RewardsLoaded({
    required this.summary,
    required this.transactions,
    required this.total,
  });
  final RewardsSummary summary;
  final List<RewardsTransaction> transactions;
  final int total;
  @override
  List<Object?> get props => [summary, transactions, total];
}

class RewardsError extends RewardsState {
  const RewardsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class RewardsRedeemSuccess extends RewardsState {
  const RewardsRedeemSuccess({
    required this.redeemedPoints,
    required this.discountUsd,
    required this.newBalance,
  });
  final int redeemedPoints;
  final double discountUsd;
  final int newBalance;
  @override
  List<Object?> get props => [redeemedPoints, discountUsd, newBalance];
}

// BLoC
class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  RewardsBloc({
    required GetRewardsSummaryUseCase getSummary,
    required GetRewardsTransactionsUseCase getTransactions,
    required RedeemRewardsUseCase redeem,
  })  : _getSummary = getSummary,
        _getTransactions = getTransactions,
        _redeem = redeem,
        super(const RewardsInitial()) {
    on<RewardsLoadRequested>(_onLoad);
    on<RewardsRedeemRequested>(_onRedeem);
  }

  final GetRewardsSummaryUseCase _getSummary;
  final GetRewardsTransactionsUseCase _getTransactions;
  final RedeemRewardsUseCase _redeem;

  Future<void> _onLoad(
    RewardsLoadRequested event,
    Emitter<RewardsState> emit,
  ) async {
    emit(const RewardsLoading());
    try {
      final summary = await _getSummary();
      final result = await _getTransactions();
      emit(RewardsLoaded(
        summary: summary,
        transactions: result.transactions,
        total: result.total,
      ));
    } catch (e) {
      emit(RewardsError(e.toString()));
    }
  }

  Future<void> _onRedeem(
    RewardsRedeemRequested event,
    Emitter<RewardsState> emit,
  ) async {
    emit(const RewardsLoading());
    try {
      final result = await _redeem(event.points);
      final redeemedPoints =
          (result['redeemed_points'] as num?)?.toInt() ?? event.points;
      final discountUsd = (result['discount_usd'] as num?)?.toDouble() ?? 0;
      final newBalance = (result['new_balance'] as num?)?.toInt() ?? 0;
      emit(RewardsRedeemSuccess(
        redeemedPoints: redeemedPoints,
        discountUsd: discountUsd,
        newBalance: newBalance,
      ));
      // Reload after successful redeem
      add(const RewardsLoadRequested());
    } catch (e) {
      emit(RewardsError(e.toString()));
    }
  }
}
