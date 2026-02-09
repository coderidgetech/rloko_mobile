import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/site_config.dart';
import '../../domain/usecases/get_site_config_usecase.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  ConfigBloc(this._getConfig) : super(const ConfigInitial()) {
    on<ConfigLoadRequested>(_onLoad);
  }

  final GetSiteConfigUseCase _getConfig;

  Future<void> _onLoad(ConfigLoadRequested event, Emitter<ConfigState> emit) async {
    emit(const ConfigLoading());
    try {
      final config = await _getConfig();
      emit(ConfigLoaded(config));
    } catch (_) {
      emit(ConfigLoaded(SiteConfig.defaultConfig));
    }
  }
}
