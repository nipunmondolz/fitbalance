import 'app_settings_storage_service.dart';

class MeasurementUnitConverter {
  MeasurementUnitConverter._();

  static const double _poundsPerKilogram = 2.2046226218;

  static double kilogramsToPounds(double kilograms) {
    return kilograms * _poundsPerKilogram;
  }

  static double poundsToKilograms(double pounds) {
    return pounds / _poundsPerKilogram;
  }

  static double displayWeightFromKilograms(
    double kilograms,
    MeasurementUnitMode mode,
  ) {
    return mode == MeasurementUnitMode.imperial
        ? kilogramsToPounds(kilograms)
        : kilograms;
  }

  static double inputWeightToKilograms(
    double inputWeight,
    MeasurementUnitMode mode,
  ) {
    return mode == MeasurementUnitMode.imperial
        ? poundsToKilograms(inputWeight)
        : inputWeight;
  }

  static String weightUnit(MeasurementUnitMode mode) {
    return mode == MeasurementUnitMode.imperial ? 'lb' : 'kg';
  }

  static String formatWeight(
    double kilograms,
    MeasurementUnitMode mode, {
    int fractionDigits = 1,
  }) {
    final value = displayWeightFromKilograms(kilograms, mode);
    return '${value.toStringAsFixed(fractionDigits)} ${weightUnit(mode)}';
  }

  static String formatSignedWeight(double kilograms, MeasurementUnitMode mode) {
    final value = displayWeightFromKilograms(kilograms, mode);
    final prefix = value > 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(1)} ${weightUnit(mode)}';
  }

  static String formatWeightRange(
    double minimumKilograms,
    double maximumKilograms,
    MeasurementUnitMode mode,
  ) {
    final minimum = displayWeightFromKilograms(minimumKilograms, mode);
    final maximum = displayWeightFromKilograms(maximumKilograms, mode);

    return '${minimum.toStringAsFixed(1)}–'
        '${maximum.toStringAsFixed(1)} ${weightUnit(mode)}';
  }

  static String formatHeight(double centimetres, MeasurementUnitMode mode) {
    if (mode == MeasurementUnitMode.metric) {
      return '${centimetres.toStringAsFixed(1)} cm';
    }

    final totalInches = (centimetres / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return '$feet ft $inches in';
  }

  static double minimumWeightInput(
    double minimumKilograms,
    MeasurementUnitMode mode,
  ) {
    return displayWeightFromKilograms(minimumKilograms, mode);
  }

  static double maximumWeightInput(
    double maximumKilograms,
    MeasurementUnitMode mode,
  ) {
    return displayWeightFromKilograms(maximumKilograms, mode);
  }
}
