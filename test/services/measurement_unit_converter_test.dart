import 'package:flutter_test/flutter_test.dart';
import 'package:fitbalance/services/app_settings_storage_service.dart';
import 'package:fitbalance/services/measurement_unit_converter.dart';

void main() {
  group('MeasurementUnitConverter', () {
    test('converts kilograms and pounds in both directions', () {
      final pounds = MeasurementUnitConverter.kilogramsToPounds(65.0);

      expect(pounds, closeTo(143.300470417, 0.0000001));
      expect(
        MeasurementUnitConverter.poundsToKilograms(pounds),
        closeTo(65.0, 0.0000001),
      );
    });

    test('formats weight for metric and imperial modes', () {
      expect(
        MeasurementUnitConverter.formatWeight(65.0, MeasurementUnitMode.metric),
        '65.0 kg',
      );
      expect(
        MeasurementUnitConverter.formatWeight(
          65.0,
          MeasurementUnitMode.imperial,
        ),
        '143.3 lb',
      );
      expect(
        MeasurementUnitConverter.formatSignedWeight(
          -1.5,
          MeasurementUnitMode.imperial,
        ),
        '-3.3 lb',
      );
    });

    test('formats height using the current nearest-inch rule', () {
      expect(
        MeasurementUnitConverter.formatHeight(
          170.2,
          MeasurementUnitMode.metric,
        ),
        '170.2 cm',
      );
      expect(
        MeasurementUnitConverter.formatHeight(
          170.2,
          MeasurementUnitMode.imperial,
        ),
        '5 ft 7 in',
      );
    });

    test(
      'keeps metric input unchanged and converts imperial input to kilograms',
      () {
        expect(
          MeasurementUnitConverter.inputWeightToKilograms(
            65.0,
            MeasurementUnitMode.metric,
          ),
          65.0,
        );
        expect(
          MeasurementUnitConverter.inputWeightToKilograms(
            143.300470417,
            MeasurementUnitMode.imperial,
          ),
          closeTo(65.0, 0.0000001),
        );
      },
    );

    test('formats a converted weight range consistently', () {
      expect(
        MeasurementUnitConverter.formatWeightRange(
          60.0,
          70.0,
          MeasurementUnitMode.metric,
        ),
        '60.0–70.0 kg',
      );
      expect(
        MeasurementUnitConverter.formatWeightRange(
          60.0,
          70.0,
          MeasurementUnitMode.imperial,
        ),
        '132.3–154.3 lb',
      );
    });
  });
}
