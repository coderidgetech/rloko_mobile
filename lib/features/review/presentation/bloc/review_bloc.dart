import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/review_remote_datasource.dart';
import '../../data/dto/my_review_dto.dart';

// Events
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();
  @override
  List<Object?> get props => [];
}

class MyReviewsLoadRequested extends ReviewEvent {
  const MyReviewsLoadRequested();
}

class ReviewSubmitRequested extends ReviewEvent {
  const ReviewSubmitRequested({
    required this.productId,
    required this.rating,
    required this.title,
    required this.comment,
  });
  final String productId;
  final int rating;
  final String title;
  final String comment;
  @override
  List<Object?> get props => [productId, rating, title, comment];
}

// States
abstract class ReviewState extends Equatable {
  const ReviewState();
  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

class MyReviewsLoaded extends ReviewState {
  const MyReviewsLoaded({required this.reviews, required this.total});
  final List<MyReviewDto> reviews;
  final int total;
  @override
  List<Object?> get props => [reviews, total];
}

class ReviewSubmitSuccess extends ReviewState {
  const ReviewSubmitSuccess();
}

class ReviewError extends ReviewState {
  const ReviewError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// BLoC
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  ReviewBloc(this._dataSource) : super(const ReviewInitial()) {
    on<MyReviewsLoadRequested>(_onLoadMyReviews);
    on<ReviewSubmitRequested>(_onSubmit);
  }

  final ReviewRemoteDataSource _dataSource;

  Future<void> _onLoadMyReviews(
    MyReviewsLoadRequested event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewLoading());
    try {
      final result = await _dataSource.getMyReviews();
      emit(MyReviewsLoaded(reviews: result.reviews, total: result.total));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onSubmit(
    ReviewSubmitRequested event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewLoading());
    try {
      await _dataSource.submitReview(
        productId: event.productId,
        rating: event.rating,
        title: event.title,
        comment: event.comment,
      );
      emit(const ReviewSubmitSuccess());
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }
}
