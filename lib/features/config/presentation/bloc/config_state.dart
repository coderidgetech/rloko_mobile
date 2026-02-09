part of 'config_bloc.dart';

sealed class ConfigState extends Equatable {
  const ConfigState();

  @override
  List<Object?> get props => [];
}

class ConfigInitial extends ConfigState {
  const ConfigInitial();
}

class ConfigLoading extends ConfigState {
  const ConfigLoading();
}

class ConfigLoaded extends ConfigState {
  const ConfigLoaded(this.config);
  final SiteConfig config;

  @override
  List<Object?> get props => [config];
}
