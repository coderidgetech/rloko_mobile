part of 'region_bloc.dart';

class RegionState extends Equatable {
  const RegionState({required this.region});
  final AppRegion region;
  @override
  List<Object?> get props => [region];
}
