import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/inspiration_video_entity.dart';
import '../../domain/usecases/get_inspiration_videos_usecase.dart';

part 'inspiration_videos_event.dart';
part 'inspiration_videos_state.dart';

class InspirationVideosBloc extends Bloc<InspirationVideosEvent, InspirationVideosState> {
  InspirationVideosBloc({
    required GetInspirationVideosUseCase getInspirationVideosUseCase,
  })  : _getInspirationVideosUseCase = getInspirationVideosUseCase,
        super(const InspirationVideosInitial()) {
    on<InspirationVideosLoadRequested>(_onLoad);
  }

  final GetInspirationVideosUseCase _getInspirationVideosUseCase;

  Future<void> _onLoad(
    InspirationVideosLoadRequested event,
    Emitter<InspirationVideosState> emit,
  ) async {
    emit(const InspirationVideosLoading());
    try {
      final list = await _getInspirationVideosUseCase(limit: event.limit);
      emit(InspirationVideosLoaded(list));
    } catch (e) {
      emit(InspirationVideosError(e.toString()));
    }
  }
}
