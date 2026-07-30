import 'dart:math' as math;

class CalorieAssessmentResult {
  const CalorieAssessmentResult({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activity,
    required this.goalKind,
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.healthyWeightMinKg,
    required this.healthyWeightMaxKg,
    required this.targetCaloriesMin,
    required this.targetCaloriesMax,
  });

  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String goal;
  final String activity;
  final String goalKind;
  final double bmi;
  final double bmr;
  final double tdee;
  final double healthyWeightMinKg;
  final double healthyWeightMaxKg;
  final int targetCaloriesMin;
  final int targetCaloriesMax;
}

class CalorieTargetCalculator {
  const CalorieTargetCalculator._();

  static CalorieAssessmentResult calculate({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String goal,
    required String activity,
  }) {
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    final genderValue = gender.trim().toLowerCase();
    final usesFemaleFormula =
        genderValue == 'female' ||
        genderValue == 'woman' ||
        genderValue == 'নারী' ||
        genderValue == 'মহিলা';
    final adjustment = usesFemaleFormula ? -161.0 : 5.0;
    final bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + adjustment;
    final activityMultiplier = switch (activity.trim().toLowerCase()) {
      'light' => 1.375,
      'moderate' => 1.55,
      'high' => 1.725,
      _ => 1.2,
    };
    final tdee = bmr * activityMultiplier;
    final goalKind = _goalKind(goal);

    late final double targetMin;
    late final double targetMax;

    switch (goalKind) {
      case 'loss':
        targetMin = math.max(1200.0, tdee - 500.0).toDouble();
        targetMax = math.max(targetMin, tdee - 250.0).toDouble();
        break;
      case 'gain':
        targetMin = tdee + 300.0;
        targetMax = tdee + 500.0;
        break;
      default:
        targetMin = tdee - 100.0;
        targetMax = tdee + 100.0;
        break;
    }

    final heightSquared = heightM * heightM;

    return CalorieAssessmentResult(
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: goal,
      activity: activity,
      goalKind: goalKind,
      bmi: bmi,
      bmr: bmr,
      tdee: tdee,
      healthyWeightMinKg: 18.5 * heightSquared,
      healthyWeightMaxKg: 24.9 * heightSquared,
      targetCaloriesMin: targetMin.round(),
      targetCaloriesMax: targetMax.round(),
    );
  }

  static String _goalKind(String goal) {
    final value = goal.trim().toLowerCase();

    if (value.contains('gain') ||
        value.contains('বাড়') ||
        value.contains('বাড়')) {
      return 'gain';
    }

    if (value.contains('loss') ||
        value.contains('lose') ||
        value.contains('কম')) {
      return 'loss';
    }

    if (value.contains('fitness') ||
        value.contains('fit') ||
        value.contains('ফিট')) {
      return 'fitness';
    }

    return 'maintain';
  }
}
