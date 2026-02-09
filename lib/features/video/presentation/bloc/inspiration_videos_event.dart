part of 'inspiration_videos_bloc.dart';

sealed class InspirationVideosEvent extends Equatable {
  const InspirationVideosEvent();

  @override
  List<Object?> get props => [];
}

final class InspirationVideosLoadRequested extends InspirationVideosEvent {
  const InspirationVideosLoadRequested({this.limit = 20});
  final int limit;

  @override
  List<Object?> get props => [limit];
}
