import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearanceMode { system, light, dark }

class AppSettingsStorageService {
  AppSettingsStorageService._();

  static final AppSettingsStorageService instance =
      AppSettingsStorageService._();

  static const String _appearanceModeKey = 'app_appearance_mode_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<AppAppearanceMode> loadAppearanceMode() async {
    final savedValue = await _preferences.getString(_appearanceModeKey);

    switch (savedValue) {
      case 'light':
        return AppAppearanceMode.light;
      case 'dark':
        return AppAppearanceMode.dark;
      default:
        return AppAppearanceMode.system;
    }
  }

  Future<void> saveAppearanceMode(AppAppearanceMode mode) async {
    await _preferences.setString(_appearanceModeKey, mode.name);
  }
}

class AppSettingsController {
  AppSettingsController._();

  static final AppSettingsController instance = AppSettingsController._();

  final ValueNotifier<AppAppearanceMode> _appearanceMode =
      ValueNotifier<AppAppearanceMode>(AppAppearanceMode.system);

  bool _isInitialised = false;

  ValueListenable<AppAppearanceMode> get appearanceModeListenable =>
      _appearanceMode;

  AppAppearanceMode get currentAppearanceMode => _appearanceMode.value;

  Future<void> initialise() async {
    if (_isInitialised) {
      return;
    }

    final savedMode = await AppSettingsStorageService.instance
        .loadAppearanceMode();
    _appearanceMode.value = savedMode;
    _isInitialised = true;
  }

  Future<void> updateAppearanceMode(AppAppearanceMode mode) async {
    if (mode == _appearanceMode.value) {
      return;
    }

    await AppSettingsStorageService.instance.saveAppearanceMode(mode);
    _appearanceMode.value = mode;
  }
}
