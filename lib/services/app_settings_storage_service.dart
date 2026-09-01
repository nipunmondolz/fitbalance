import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearanceMode { system, light, dark }

enum MeasurementUnitMode { metric, imperial }

class AppSettingsStorageService {
  AppSettingsStorageService._();

  static final AppSettingsStorageService instance =
      AppSettingsStorageService._();

  static const String _appearanceModeKey = 'app_appearance_mode_v1';
  static const String _measurementUnitKey = 'app_measurement_unit_v1';

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

  Future<MeasurementUnitMode> loadMeasurementUnit() async {
    final savedValue = await _preferences.getString(_measurementUnitKey);

    return savedValue == 'imperial'
        ? MeasurementUnitMode.imperial
        : MeasurementUnitMode.metric;
  }

  Future<void> saveMeasurementUnit(MeasurementUnitMode mode) async {
    await _preferences.setString(_measurementUnitKey, mode.name);
  }
}

class AppSettingsController {
  AppSettingsController._();

  static final AppSettingsController instance = AppSettingsController._();

  final ValueNotifier<AppAppearanceMode> _appearanceMode =
      ValueNotifier<AppAppearanceMode>(AppAppearanceMode.system);
  final ValueNotifier<MeasurementUnitMode> _measurementUnit =
      ValueNotifier<MeasurementUnitMode>(MeasurementUnitMode.metric);

  bool _isInitialised = false;

  ValueListenable<AppAppearanceMode> get appearanceModeListenable =>
      _appearanceMode;

  ValueListenable<MeasurementUnitMode> get measurementUnitListenable =>
      _measurementUnit;

  AppAppearanceMode get currentAppearanceMode => _appearanceMode.value;

  MeasurementUnitMode get currentMeasurementUnit => _measurementUnit.value;

  Future<void> initialise() async {
    if (_isInitialised) {
      return;
    }

    final appearanceFuture = AppSettingsStorageService.instance
        .loadAppearanceMode();
    final measurementFuture = AppSettingsStorageService.instance
        .loadMeasurementUnit();

    final appearanceMode = await appearanceFuture;
    final measurementUnit = await measurementFuture;

    _appearanceMode.value = appearanceMode;
    _measurementUnit.value = measurementUnit;
    _isInitialised = true;
  }

  Future<void> updateAppearanceMode(AppAppearanceMode mode) async {
    if (mode == _appearanceMode.value) {
      return;
    }

    await AppSettingsStorageService.instance.saveAppearanceMode(mode);
    _appearanceMode.value = mode;
  }

  Future<void> updateMeasurementUnit(MeasurementUnitMode mode) async {
    if (mode == _measurementUnit.value) {
      return;
    }

    await AppSettingsStorageService.instance.saveMeasurementUnit(mode);
    _measurementUnit.value = mode;
  }

  void resetToDefaultsAfterDataClear() {
    _appearanceMode.value = AppAppearanceMode.system;
    _measurementUnit.value = MeasurementUnitMode.metric;
  }
}
