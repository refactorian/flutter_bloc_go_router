import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/local_storage_service.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool enableNotifications;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.enableNotifications = true,
  });

  SettingsState copyWith({ThemeMode? themeMode, bool? enableNotifications}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  @override
  List<Object?> get props => [themeMode, enableNotifications];
}

class SettingsCubit extends Cubit<SettingsState> {
  final LocalStorageService? storageService;

  SettingsCubit({this.storageService}) : super(const SettingsState()) {
    _loadPersistedSettings();
  }

  void _loadPersistedSettings() {
    if (storageService == null) return;
    final savedMode = storageService!.getThemeMode();
    emit(state.copyWith(themeMode: savedMode));
  }

  Future<void> toggleThemeMode(ThemeMode mode) async {
    await storageService?.setThemeMode(mode);
    if (!isClosed) {
      emit(state.copyWith(themeMode: mode));
    }
  }

  void toggleNotifications(bool enabled) {
    emit(state.copyWith(enableNotifications: enabled));
  }
}
