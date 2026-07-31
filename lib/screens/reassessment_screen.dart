import 'package:flutter/material.dart';

import '../services/app_settings_storage_service.dart';
import '../services/calorie_target_calculator.dart';
import '../services/measurement_unit_converter.dart';

enum _ReassessmentHeightUnit { metric, imperial }

class ReassessmentScreen extends StatefulWidget {
  const ReassessmentScreen({
    required this.isBangla,
    required this.initialAge,
    required this.initialGender,
    required this.initialHeightCm,
    required this.initialWeightKg,
    required this.initialGoal,
    required this.initialActivity,
    required this.currentTargetCaloriesMin,
    required this.currentTargetCaloriesMax,
    required this.onSave,
    super.key,
  });

  final bool isBangla;
  final int initialAge;
  final String initialGender;
  final double initialHeightCm;
  final double initialWeightKg;
  final String initialGoal;
  final String initialActivity;
  final int currentTargetCaloriesMin;
  final int currentTargetCaloriesMax;
  final Future<void> Function(CalorieAssessmentResult result) onSave;

  @override
  State<ReassessmentScreen> createState() => _ReassessmentScreenState();
}

class _ReassessmentScreenState extends State<ReassessmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _ageController;
  late final TextEditingController _heightCmController;
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;
  late final TextEditingController _weightController;

  late String _gender;
  late String _goal;
  late String _activity;
  late MeasurementUnitMode _measurementUnit;
  late _ReassessmentHeightUnit _heightUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _measurementUnit = AppSettingsController.instance.currentMeasurementUnit;
    _heightUnit = _measurementUnit == MeasurementUnitMode.imperial
        ? _ReassessmentHeightUnit.imperial
        : _ReassessmentHeightUnit.metric;

    _ageController = TextEditingController(text: '${widget.initialAge}');
    _heightCmController = TextEditingController(
      text: widget.initialHeightCm.toStringAsFixed(1),
    );
    _weightController = TextEditingController(
      text: MeasurementUnitConverter.displayWeightFromKilograms(
        widget.initialWeightKg,
        _measurementUnit,
      ).toStringAsFixed(1),
    );

    final totalInches = (widget.initialHeightCm / 2.54).round();
    _feetController = TextEditingController(text: '${totalInches ~/ 12}');
    _inchesController = TextEditingController(text: '${totalInches % 12}');

    _gender = _normaliseGender(widget.initialGender);
    _goal = _normaliseGoal(widget.initialGoal);
    _activity = _normaliseActivity(widget.initialActivity);
  }

  String _normaliseNumber(String value) {
    const banglaDigits = '০১২৩৪৫৬৭৮৯';
    const englishDigits = '0123456789';

    var normalized = value.trim().replaceAll(',', '.');

    for (var index = 0; index < banglaDigits.length; index++) {
      normalized = normalized.replaceAll(
        banglaDigits[index],
        englishDigits[index],
      );
    }

    return normalized;
  }

  String _normaliseGender(String value) {
    switch (value.trim().toLowerCase()) {
      case 'female':
      case 'woman':
      case 'নারী':
      case 'মহিলা':
        return 'female';
      case 'other':
      case 'অন্যান্য':
        return 'other';
      case 'prefer_not_to_say':
        return 'prefer_not_to_say';
      default:
        return 'male';
    }
  }

  String _normaliseGoal(String value) {
    final normalised = value.trim().toLowerCase();

    if (normalised.contains('gain') ||
        normalised.contains('বাড়') ||
        normalised.contains('বাড়')) {
      return 'gain_weight';
    }
    if (normalised.contains('loss') ||
        normalised.contains('lose') ||
        normalised.contains('কম')) {
      return 'lose_weight';
    }
    if (normalised.contains('fitness') ||
        normalised.contains('fit') ||
        normalised.contains('ফিট')) {
      return 'improve_fitness';
    }

    return 'maintain_weight';
  }

  String _normaliseActivity(String value) {
    switch (value.trim().toLowerCase()) {
      case 'light':
        return 'light';
      case 'moderate':
      case 'medium':
        return 'moderate';
      case 'high':
        return 'high';
      default:
        return 'low';
    }
  }

  String _genderLabel(String value) {
    switch (value) {
      case 'female':
        return widget.isBangla ? 'নারী' : 'Female';
      case 'other':
        return widget.isBangla ? 'অন্যান্য' : 'Other';
      case 'prefer_not_to_say':
        return widget.isBangla ? 'বলতে অনিচ্ছুক' : 'Prefer not to say';
      default:
        return widget.isBangla ? 'পুরুষ' : 'Male';
    }
  }

  String _goalLabel(String value) {
    switch (value) {
      case 'lose_weight':
        return widget.isBangla ? 'ওজন কমানো' : 'Weight loss';
      case 'gain_weight':
        return widget.isBangla ? 'ওজন বাড়ানো' : 'Weight gain';
      case 'improve_fitness':
        return widget.isBangla
            ? 'ফিটনেস ও সুস্থতা উন্নত করা'
            : 'Improve fitness and wellness';
      default:
        return widget.isBangla ? 'বর্তমান ওজন বজায় রাখা' : 'Maintain weight';
    }
  }

  String _activityLabel(String value) {
    switch (value) {
      case 'light':
        return widget.isBangla
            ? 'সপ্তাহে ১–২ দিন ব্যায়াম'
            : 'Exercise 1–2 days a week';
      case 'moderate':
        return widget.isBangla
            ? 'সপ্তাহে ৩–৫ দিন ব্যায়াম'
            : 'Exercise 3–5 days a week';
      case 'high':
        return widget.isBangla
            ? 'সপ্তাহে ৬–৭ দিন ব্যায়াম'
            : 'Exercise 6–7 days a week';
      default:
        return widget.isBangla
            ? 'খুব কম বা কোনো ব্যায়াম নেই'
            : 'Little or no exercise';
    }
  }

  String? _validateAge(String? value) {
    final age = int.tryParse(_normaliseNumber(value ?? ''));

    if (age == null || age < 18 || age > 120) {
      return widget.isBangla
          ? '১৮ থেকে ১২০ বছরের মধ্যে সঠিক বয়স লিখুন।'
          : 'Enter a valid age between 18 and 120.';
    }

    return null;
  }

  String? _validateHeightCm(String? value) {
    final height = double.tryParse(_normaliseNumber(value ?? ''));

    if (height == null || height < 100 || height > 250) {
      return widget.isBangla
          ? '১০০ থেকে ২৫০ সেমির মধ্যে সঠিক উচ্চতা লিখুন।'
          : 'Enter a valid height between 100 and 250 cm.';
    }

    return null;
  }

  String? _validateFeet(String? value) {
    final feet = int.tryParse(_normaliseNumber(value ?? ''));

    if (feet == null || feet < 3 || feet > 8) {
      return widget.isBangla
          ? '৩ থেকে ৮-এর মধ্যে সঠিক ফুট লিখুন।'
          : 'Enter valid feet between 3 and 8.';
    }

    return null;
  }

  String? _validateInches(String? value) {
    final inches = int.tryParse(_normaliseNumber(value ?? ''));

    if (inches == null || inches < 0 || inches > 11) {
      return widget.isBangla
          ? '০ থেকে ১১-এর মধ্যে সঠিক ইঞ্চি লিখুন।'
          : 'Enter valid inches between 0 and 11.';
    }

    final feet = int.tryParse(_normaliseNumber(_feetController.text));

    if (feet != null) {
      final heightCm = ((feet * 12) + inches) * 2.54;

      if (heightCm < 100 || heightCm > 250) {
        return widget.isBangla
            ? 'মোট উচ্চতা ১০০ থেকে ২৫০ সেমির মধ্যে হতে হবে।'
            : 'Total height must be between 100 and 250 cm.';
      }
    }

    return null;
  }

  String? _validateWeight(String? value) {
    final weight = double.tryParse(_normaliseNumber(value ?? ''));
    final minimum = MeasurementUnitConverter.minimumWeightInput(
      25,
      _measurementUnit,
    );
    final maximum = MeasurementUnitConverter.maximumWeightInput(
      350,
      _measurementUnit,
    );
    final unit = MeasurementUnitConverter.weightUnit(_measurementUnit);

    if (weight == null || weight < minimum || weight > maximum) {
      return widget.isBangla
          ? '${minimum.toStringAsFixed(1)} থেকে ${maximum.toStringAsFixed(1)} $unit-এর মধ্যে সঠিক ওজন লিখুন।'
          : 'Enter a valid weight between ${minimum.toStringAsFixed(1)} and ${maximum.toStringAsFixed(1)} $unit.';
    }

    return null;
  }

  double _heightCm() {
    if (_heightUnit == _ReassessmentHeightUnit.metric) {
      return double.parse(_normaliseNumber(_heightCmController.text));
    }

    final feet = int.parse(_normaliseNumber(_feetController.text));
    final inches = int.parse(_normaliseNumber(_inchesController.text));
    return ((feet * 12) + inches) * 2.54;
  }

  void _changeHeightUnit(_ReassessmentHeightUnit unit) {
    if (_heightUnit == unit) {
      return;
    }

    if (unit == _ReassessmentHeightUnit.imperial) {
      final centimetres = double.tryParse(
        _normaliseNumber(_heightCmController.text),
      );

      if (centimetres != null && centimetres > 0) {
        final totalInches = (centimetres / 2.54).round();
        _feetController.text = '${totalInches ~/ 12}';
        _inchesController.text = '${totalInches % 12}';
      }
    } else {
      final feet = int.tryParse(_normaliseNumber(_feetController.text));
      final inches = int.tryParse(_normaliseNumber(_inchesController.text));

      if (feet != null && inches != null && inches >= 0 && inches <= 11) {
        final centimetres = ((feet * 12) + inches) * 2.54;
        _heightCmController.text = centimetres.toStringAsFixed(1);
      }
    }

    setState(() {
      _heightUnit = unit;
    });
  }

  CalorieAssessmentResult? _calculate() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return null;
    }

    final age = int.parse(_normaliseNumber(_ageController.text));
    final inputWeight = double.parse(_normaliseNumber(_weightController.text));
    final weightKg = MeasurementUnitConverter.inputWeightToKilograms(
      inputWeight,
      _measurementUnit,
    );

    return CalorieTargetCalculator.calculate(
      age: age,
      gender: _gender,
      heightCm: _heightCm(),
      weightKg: weightKg,
      goal: _goal,
      activity: _activity,
    );
  }

  Future<bool> _confirmResult(CalorieAssessmentResult result) async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            widget.isBangla
                ? 'নতুন ক্যালরি লক্ষ্য নিশ্চিত করুন'
                : 'Confirm the new calorie target',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReassessmentResultRow(
                label: widget.isBangla ? 'আগের লক্ষ্য' : 'Previous target',
                value:
                    '${widget.currentTargetCaloriesMin}–${widget.currentTargetCaloriesMax} kcal',
              ),
              const SizedBox(height: 10),
              _ReassessmentResultRow(
                label: widget.isBangla ? 'নতুন লক্ষ্য' : 'New target',
                value:
                    '${result.targetCaloriesMin}–${result.targetCaloriesMax} kcal',
              ),
              const SizedBox(height: 10),
              _ReassessmentResultRow(
                label: 'BMI',
                value: result.bmi.toStringAsFixed(1),
              ),
              const SizedBox(height: 10),
              _ReassessmentResultRow(
                label: widget.isBangla
                    ? 'ওজন বজায় রাখার হিসাব'
                    : 'ওজন বজায় রাখার হিসাব',
                value: '${result.tdee.round()} kcal',
              ),
              const SizedBox(height: 14),
              Text(
                widget.isBangla
                    ? 'সংরক্ষণ করলে আজ, দৈনিক লগ, অগ্রগতি ও প্রোফাইলে ক্যালরি লক্ষ্য হালনাগাদ হবে।'
                    : 'Saving updates the calorie target in Today, Daily Log, Progress, and Profile.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(widget.isBangla ? 'বাতিল' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(widget.isBangla ? 'সংরক্ষণ করুন' : 'Save'),
            ),
          ],
        );
      },
    );

    return shouldSave == true;
  }

  Future<void> _submit() async {
    final result = _calculate();

    if (result == null || !await _confirmResult(result) || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(result);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'পুনর্মূল্যায়ন সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'
                  : 'The reassessment could not be saved. Please try again.',
            ),
          ),
        );

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightCmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isBangla ? 'স্বাস্থ্য পুনর্মূল্যায়ন' : 'Reassessment',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                widget.isBangla
                    ? 'তথ্য পর্যালোচনা করে ক্যালরি লক্ষ্য হালনাগাদ করুন'
                    : 'Review your information and update the calorie target',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isBangla
                    ? 'অ্যাপের বর্তমান হিসাবপদ্ধতি অপরিবর্তিত রেখে বয়স, লিঙ্গ, উচ্চতা, ওজন, শারীরিক সক্রিয়তা ও লক্ষ্য থেকে নতুন আনুমানিক হিসাব তৈরি হবে।'
                    : 'A new estimate will be calculated from age, sex, height, weight, activity, and goal using the app’s existing formula.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validateAge,
                decoration: InputDecoration(
                  labelText: widget.isBangla ? 'বয়স' : 'Age',
                  suffixText: widget.isBangla ? 'বছর' : 'years',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: widget.isBangla ? 'লিঙ্গ' : 'Sex',
                  prefixIcon: const Icon(Icons.people_outline),
                  border: const OutlineInputBorder(),
                ),
                items: const ['male', 'female', 'other', 'prefer_not_to_say']
                    .map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(_genderLabel(value)),
                      );
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gender = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              SegmentedButton<_ReassessmentHeightUnit>(
                segments: [
                  ButtonSegment(
                    value: _ReassessmentHeightUnit.metric,
                    label: Text(widget.isBangla ? 'সেমি' : 'cm'),
                    icon: const Icon(Icons.straighten),
                  ),
                  ButtonSegment(
                    value: _ReassessmentHeightUnit.imperial,
                    label: Text(widget.isBangla ? 'ফুট/ইঞ্চি' : 'ft/in'),
                    icon: const Icon(Icons.height),
                  ),
                ],
                selected: {_heightUnit},
                onSelectionChanged: (selection) {
                  _changeHeightUnit(selection.first);
                },
              ),
              const SizedBox(height: 14),
              if (_heightUnit == _ReassessmentHeightUnit.metric)
                TextFormField(
                  controller: _heightCmController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateHeightCm,
                  decoration: InputDecoration(
                    labelText: widget.isBangla ? 'উচ্চতা' : 'Height',
                    suffixText: 'cm',
                    prefixIcon: const Icon(Icons.height),
                    border: const OutlineInputBorder(),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _feetController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _validateFeet,
                        decoration: InputDecoration(
                          labelText: widget.isBangla ? 'ফুট' : 'Feet',
                          suffixText: 'ft',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _inchesController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _validateInches,
                        decoration: InputDecoration(
                          labelText: widget.isBangla ? 'ইঞ্চি' : 'Inches',
                          suffixText: 'in',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: _validateWeight,
                decoration: InputDecoration(
                  labelText: widget.isBangla ? 'বর্তমান ওজন' : 'Current weight',
                  suffixText: MeasurementUnitConverter.weightUnit(
                    _measurementUnit,
                  ),
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _goal,
                decoration: InputDecoration(
                  labelText: widget.isBangla
                      ? 'স্বাস্থ্য লক্ষ্য'
                      : 'Health goal',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: const OutlineInputBorder(),
                ),
                items:
                    const [
                          'lose_weight',
                          'gain_weight',
                          'maintain_weight',
                          'improve_fitness',
                        ]
                        .map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(_goalLabel(value)),
                          );
                        })
                        .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _goal = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _activity,
                decoration: InputDecoration(
                  labelText: widget.isBangla
                      ? 'শারীরিক সক্রিয়তা'
                      : 'Physical activity',
                  prefixIcon: const Icon(Icons.directions_run),
                  border: const OutlineInputBorder(),
                ),
                items: const ['low', 'light', 'moderate', 'high']
                    .map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(_activityLabel(value)),
                      );
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _activity = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  widget.isBangla
                      ? 'এটি ১৮+ প্রাপ্তবয়স্কদের জন্য একটি সাধারণ আনুমানিক হিসাব; রোগনির্ণয় বা চিকিৎসা নির্দেশনা নয়।'
                      : 'This is a general estimate for adults aged 18+, not a diagnosis or medical prescription.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: Text(
                  widget.isBangla
                      ? 'হিসাব করে হালনাগাদ করুন'
                      : 'Calculate and update',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReassessmentResultRow extends StatelessWidget {
  const _ReassessmentResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
