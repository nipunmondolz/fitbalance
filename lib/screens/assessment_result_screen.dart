import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'plan_confirmation_screen.dart';

class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({
    required this.isBangla,
    required this.age,
    required this.gender,
    required this.heightInCm,
    required this.weightInKg,
    required this.goal,
    required this.schedule,
    required this.activity,
    required this.sleep,
    required this.budget,
    super.key,
  });

  final bool isBangla;
  final int age;
  final String gender;
  final double heightInCm;
  final double weightInKg;
  final String goal;
  final String schedule;
  final String activity;
  final String sleep;
  final String budget;

  double get _heightInMeters => heightInCm / 100;

  double get _bmi {
    return weightInKg / (_heightInMeters * _heightInMeters);
  }

  bool get _usesFemaleFormula {
    final value = gender.trim().toLowerCase();

    return value == 'female' ||
        value == 'woman' ||
        value == 'নারী' ||
        value == 'মহিলা';
  }

  double get _bmr {
    final adjustment = _usesFemaleFormula ? -161.0 : 5.0;

    return (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) + adjustment;
  }

  double get _activityMultiplier {
    switch (activity) {
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'high':
        return 1.725;
      default:
        return 1.2;
    }
  }

  double get _tdee => _bmr * _activityMultiplier;

  String get _goalKind {
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

  List<double> get _healthyWeightRange {
    final heightSquared = _heightInMeters * _heightInMeters;

    return [18.5 * heightSquared, 24.9 * heightSquared];
  }

  List<double> get _targetCalorieRange {
    switch (_goalKind) {
      case 'loss':
        final minimum = math.max(1200.0, _tdee - 500.0).toDouble();
        final maximum = math.max(minimum, _tdee - 250.0).toDouble();

        return [minimum, maximum];

      case 'gain':
        return [_tdee + 300.0, _tdee + 500.0];

      default:
        return [_tdee - 100.0, _tdee + 100.0];
    }
  }

  String _bmiStatus() {
    if (_bmi < 18.5) {
      return isBangla ? 'স্বাভাবিকের চেয়ে কম' : 'Below normal range';
    }

    if (_bmi < 25) {
      return isBangla ? 'স্বাস্থ্যকর সীমার মধ্যে' : 'Within healthy range';
    }

    if (_bmi < 30) {
      return isBangla ? 'স্বাভাবিকের চেয়ে বেশি' : 'Above normal range';
    }

    return isBangla ? 'স্থূলতার সীমার মধ্যে' : 'Within obesity range';
  }

  String _bmiExplanation() {
    if (_bmi < 18.5) {
      return isBangla
          ? 'ধীরে ও নিরাপদভাবে ওজন বাড়ানোর দিকে মনোযোগ প্রয়োজন।'
          : 'Focus on gradual and safe weight gain.';
    }

    if (_bmi < 25) {
      return isBangla
          ? 'বর্তমান ওজন স্বাস্থ্যকর adult screening সীমার মধ্যে।'
          : 'Your weight is within the healthy adult screening range.';
    }

    return isBangla
        ? 'ধীরে ও টেকসইভাবে ওজন নিয়ন্ত্রণে মনোযোগ প্রয়োজন।'
        : 'Focus on gradual and sustainable weight management.';
  }

  String _goalLabel() {
    switch (_goalKind) {
      case 'loss':
        return isBangla ? 'ওজন কমানো' : 'Weight loss';
      case 'gain':
        return isBangla ? 'ওজন বাড়ানো' : 'Weight gain';
      case 'fitness':
        return isBangla ? 'ফিটনেস উন্নত করা' : 'Improve fitness';
      default:
        return isBangla ? 'ওজন বজায় রাখা' : 'Maintain weight';
    }
  }

  String _goalExplanation() {
    switch (_goalKind) {
      case 'loss':
        return isBangla
            ? 'Maintenance estimate থেকে প্রতিদিন প্রায় ২৫০–৫০০ kcal কম ধরে এই range তৈরি হয়েছে।'
            : 'This range is about 250–500 kcal below the maintenance estimate.';

      case 'gain':
        return isBangla
            ? 'Maintenance estimate-এর সঙ্গে প্রতিদিন প্রায় ৩০০–৫০০ kcal যোগ করে এই range তৈরি হয়েছে।'
            : 'This range is about 300–500 kcal above the maintenance estimate.';

      default:
        return isBangla
            ? 'বর্তমান ওজন ও শক্তি বজায় রাখার জন্য maintenance estimate-এর কাছাকাছি range।'
            : 'A range close to maintenance for supporting current weight and energy.';
    }
  }

  String _scheduleLabel() {
    switch (schedule) {
      case 'regular':
        return isBangla ? 'নিয়মিত সময়সূচি' : 'Regular schedule';
      case 'irregular':
        return isBangla ? 'অনিয়মিত সময়সূচি' : 'Irregular schedule';
      default:
        return isBangla ? 'শিফট বা রাতের কাজ' : 'Shift or night work';
    }
  }

  String _activityLabel() {
    switch (activity) {
      case 'light':
        return isBangla
            ? 'সপ্তাহে ১–২ দিন ব্যায়াম'
            : 'Exercise 1–2 days a week';
      case 'moderate':
        return isBangla
            ? 'সপ্তাহে ৩–৫ দিন ব্যায়াম'
            : 'Exercise 3–5 days a week';
      case 'high':
        return isBangla
            ? 'সপ্তাহে ৬–৭ দিন ব্যায়াম'
            : 'Exercise 6–7 days a week';
      default:
        return isBangla
            ? 'খুব কম বা কোনো ব্যায়াম নেই'
            : 'Little or no exercise';
    }
  }

  String _sleepLabel() {
    switch (sleep) {
      case 'less_than_6':
        return isBangla ? '৬ ঘণ্টার কম' : 'Less than 6 hours';
      case '6_to_7':
        return isBangla ? '৬–৭ ঘণ্টা' : '6–7 hours';
      case '7_to_9':
        return isBangla ? '৭–৯ ঘণ্টা' : '7–9 hours';
      default:
        return isBangla ? '৯ ঘণ্টার বেশি' : 'More than 9 hours';
    }
  }

  String _budgetLabel() {
    switch (budget) {
      case 'budget_friendly':
        return isBangla ? 'সাশ্রয়ী পরিকল্পনা' : 'Budget-friendly';
      case 'moderate':
        return isBangla ? 'মাঝারি বাজেট' : 'Moderate budget';
      default:
        return isBangla ? 'বাজেট নমনীয়' : 'Flexible budget';
    }
  }

  void _continue(BuildContext context) {
    final targetRange = _targetCalorieRange;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlanConfirmationScreen(
          isBangla: isBangla,
          goal: goal,
          targetCaloriesMin: targetRange[0].round(),
          targetCaloriesMax: targetRange[1].round(),
          schedule: schedule,
          activity: activity,
          sleep: sleep,
          budget: budget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final healthyRange = _healthyWeightRange;
    final targetRange = _targetCalorieRange;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBangla ? 'মূল্যায়নের ফলাফল' : 'Assessment result'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isBangla
                          ? 'আপনার প্রাথমিক মূল্যায়ন প্রস্তুত'
                          : 'Your initial assessment is ready',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${isBangla ? 'নির্বাচিত লক্ষ্য' : 'Selected goal'}: '
                      '${_goalLabel()}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _ResultCard(
                icon: Icons.monitor_weight_outlined,
                title: 'BMI',
                value: _bmi.toStringAsFixed(1),
                description: '${_bmiStatus()}\n${_bmiExplanation()}',
              ),
              const SizedBox(height: 14),
              _ResultCard(
                icon: Icons.straighten,
                title: isBangla
                    ? 'স্বাস্থ্যকর ওজনের screening range'
                    : 'Healthy weight screening range',
                value:
                    '${healthyRange[0].toStringAsFixed(1)}–'
                    '${healthyRange[1].toStringAsFixed(1)} kg',
                description: isBangla
                    ? 'BMI ১৮.৫–২৪.৯ অনুসারে আনুমানিক range'
                    : 'Estimated range based on BMI 18.5–24.9',
              ),
              const SizedBox(height: 14),
              _ResultCard(
                icon: Icons.local_fire_department_outlined,
                title: isBangla
                    ? 'দৈনিক maintenance estimate'
                    : 'Daily maintenance estimate',
                value:
                    '${(_tdee - 100).round()}–'
                    '${(_tdee + 100).round()} kcal',
                description: isBangla
                    ? 'বর্তমান ওজন বজায় রাখার আনুমানিক দৈনিক energy range'
                    : 'Estimated daily energy range for maintaining current weight',
              ),
              const SizedBox(height: 14),
              _ResultCard(
                icon: Icons.flag_outlined,
                title: isBangla
                    ? 'আপনার লক্ষ্য অনুযায়ী calorie range'
                    : 'Goal-based calorie range',
                value:
                    '${targetRange[0].round()}–'
                    '${targetRange[1].round()} kcal',
                description: _goalExplanation(),
              ),
              const SizedBox(height: 28),
              Text(
                isBangla ? 'জীবনযাপনের সংক্ষিপ্তসার' : 'Lifestyle summary',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: isBangla ? 'আনুমানিক BMR' : 'Estimated BMR',
                        value: '${_bmr.round()} kcal',
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: isBangla ? 'সময়সূচি' : 'Schedule',
                        value: _scheduleLabel(),
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: isBangla ? 'শারীরিক সক্রিয়তা' : 'Activity',
                        value: _activityLabel(),
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: isBangla ? 'ঘুম' : 'Sleep',
                        value: _sleepLabel(),
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: isBangla ? 'খাবারের বাজেট' : 'Food budget',
                        value: _budgetLabel(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isBangla
                            ? 'এই ফলাফল ১৮+ বয়সী প্রাপ্তবয়স্কদের জন্য একটি সাধারণ estimate। এটি medical diagnosis নয়। গর্ভাবস্থা, স্তন্যদান, রোগ বা নিয়মিত ওষুধ থাকলে চিকিৎসকের পরামর্শ প্রয়োজন।'
                            : 'This is a general estimate for adults aged 18+. It is not a medical diagnosis. Seek professional guidance during pregnancy, breastfeeding, illness, or regular medication use.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => _continue(context),
                  child: Text(
                    isBangla ? 'এগিয়ে যান' : 'Continue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
