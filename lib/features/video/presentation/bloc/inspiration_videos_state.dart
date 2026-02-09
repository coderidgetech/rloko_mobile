part of 'inspiration_videos_bloc.dart';

sealed class InspirationVideosState extends Equatable {
  const InspirationVideosState();

  @override
  List<Object?> get props => [];
}

final class InspirationVideosInitial extends InspirationVideosState {
  const InspirationVideosInitial();
}

final class InspirationVideosLoading extends InspirationVideosState {
  const InspirationVideosLoading();
}

final class InspirationVideosLoaded extends InspirationVideosState {
  const InspirationVideosLoaded(this.videos);

  final List<InspirationVideoEntity> videos;

  @override
  List<Object?> get props => [videos];
}

final class InspirationVideosError extends InspirationVideosState {
  const InspirationVideosError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
