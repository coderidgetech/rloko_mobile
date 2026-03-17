import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../app_region.dart';
import '../region_repository.dart';

part 'region_event.dart';
part 'region_state.dart';

class RegionBloc extends Bloc<RegionEvent, RegionState> {
  RegionBloc({
    required RegionRepository regionRepository,
    AppRegion? initialRegion,
  })  : _regionRepository = regionRepository,
        super(RegionState(region: initialRegion ?? AppRegion.unitedStates)) {
    on<RegionLoadRequested>(_onLoad);
    on<RegionSetRequested>(_onSet);
  }

  final RegionRepository _regionRepository;

  Future<void> _onLoad(RegionLoadRequested event, Emitter<RegionState> emit) async {
    final region = await _regionRepository.getRegion();
    emit(RegionState(region: region));
  }

  Future<void> _onSet(RegionSetRequested event, Emitter<RegionState> emit) async {
    await _regionRepository.setRegion(event.region);
    emit(RegionState(region: event.region));
  }
}
