import 'package:flutter_test/flutter_test.dart';
import 'package:fitbalance/services/calorie_target_calculator.dart';

void main() {
  group('CalorieTargetCalculator', () {
    test('calculates the current male gain target formula', () {
      final result = CalorieTargetCalculator.calculate(
        age: 25,
        gender: 'male',
        heightCm: 170.2,
        weightKg: 65.0,
        goal: 'gain_weight',
        activity: 'low',
      );

      expect(result.goalKind, 'gain');
      expect(result.bmi, closeTo(22.4385219021, 0.0000001));
      expect(result.bmr, closeTo(1593.75, 0.0000001));
      expect(result.tdee, closeTo(1912.5, 0.0000001));
      expect(result.targetCaloriesMin, 2213);
      expect(result.targetCaloriesMax, 2413);
      expect(result.healthyWeightMinKg, closeTo(53.590874, 0.000001));
      expect(result.healthyWeightMaxKg, closeTo(72.1304196, 0.000001));
    });

    test('uses the current female formula and loss floor', () {
      final result = CalorieTargetCalculator.calculate(
        age: 80,
        gender: 'female',
        heightCm: 150.0,
        weightKg: 45.0,
        goal: 'weight loss',
        activity: 'low',
      );

      expect(result.goalKind, 'loss');
      expect(result.bmi, closeTo(20.0, 0.0000001));
      expect(result.bmr, closeTo(826.5, 0.0000001));
      expect(result.tdee, closeTo(991.8, 0.0000001));
      expect(result.targetCaloriesMin, 1200);
      expect(result.targetCaloriesMax, 1200);
    });

    test(
      'preserves the current non-female adjustment and activity mapping',
      () {
        final result = CalorieTargetCalculator.calculate(
          age: 30,
          gender: 'other',
          heightCm: 175.0,
          weightKg: 70.0,
          goal: 'improve_fitness',
          activity: 'moderate',
        );

        expect(result.goalKind, 'fitness');
        expect(result.bmr, closeTo(1648.75, 0.0000001));
        expect(result.tdee, closeTo(2555.5625, 0.0000001));
        expect(result.targetCaloriesMin, 2456);
        expect(result.targetCaloriesMax, 2656);
      },
    );
  });
}
