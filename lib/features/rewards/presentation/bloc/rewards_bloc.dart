import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/rewards_remote_datasource.dart';
import '../../domain/entities/rewards_summary.dart';
import '../../domain/entities/rewards_transaction.dart';

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
  RewardsBloc(this._dataSource) : super(const RewardsInitial()) {
    on<RewardsLoadRequested>(_onLoad);
    on<RewardsRedeemRequested>(_onRedeem);
  }

  final RewardsRemoteDataSource _dataSource;

  Future<void> _onLoad(RewardsLoadRequested event, Emitter<RewardsState> emit) async {
    emit(const RewardsLoading());
    try {
      final summary = await _dataSource.getSummary();
      final result = await _dataSource.getTransactions();
      emit(RewardsLoaded(
        summary: summary,
        transactions: result.transactions,
        total: result.total,
      ));
    } catch (e) {
      emit(RewardsError(e.toString()));
    }
  }

  Future<void> _onRedeem(RewardsRedeemRequested event, Emitter<RewardsState> emit) async {
    try {
      final result = await _dataSource.redeemPoints(event.points);
      final redeemedPoints = (result['redeemed_points'] as num?)?.toInt() ?? event.points;
      final discountUsd = (result['discount_usd'] as num?)?.toDouble() ?? 0;
      final newBalance = (result['new_balance'] as num?)?.toInt() ?? 0;
      emit(RewardsRedeemSuccess(
        redeemedPoints: redeemedPoints,
        discountUsd: discountUsd,
        newBalance: newBalance,
      ));
      // Reload after redeem
      add(const RewardsLoadRequested());
    } catch (e) {
      emit(RewardsError(e.toString()));
    }
  }
}
