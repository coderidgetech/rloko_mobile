part of 'promotion_cubit.dart';

abstract class PromotionState extends Equatable {
  const PromotionState();

  @override
  List<Object?> get props => [];
}

class PromotionInitial extends PromotionState {}

class PromotionLoading extends PromotionState {}

class PromotionLoaded extends PromotionState {
  const PromotionLoaded(this.promotions);

  final List<PromotionEntity> promotions;

  @override
  List<Object?> get props => [promotions];
}

class PromotionError extends PromotionState {
  const PromotionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
