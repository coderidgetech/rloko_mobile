part of 'region_bloc.dart';

sealed class RegionEvent extends Equatable {
  const RegionEvent();
  @override
  List<Object?> get props => [];
}

final class RegionLoadRequested extends RegionEvent {
  const RegionLoadRequested();
}

final class RegionSetRequested extends RegionEvent {
  const RegionSetRequested(this.region);
  final AppRegion region;
  @override
  List<Object?> get props => [region];
}
