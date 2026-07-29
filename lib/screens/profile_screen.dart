import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/body_metrics_storage_service.dart';
import '../services/profile_preferences_storage_service.dart';
import '../services/weight_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.isBangla,
    required this.goal,
    required this.schedule,
    required this.activity,
    required this.sleep,
    required this.budget,
    required this.refreshListenable,
    required this.onManageBodyInformation,
    required this.onSavePreferences,
    super.key,
  });

  final bool isBangla;
  final String goal;
  final String schedule;
  final String activity;
  final String sleep;
  final String budget;
  final ValueListenable<int> refreshListenable;
  final VoidCallback onManageBodyInformation;
  final Future<void> Function(StoredProfilePreferences preferences)
  onSavePreferences;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ProfileBmiCategory { underweight, healthy, overweight, obesity }

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  List<StoredWeightEntry> _weightEntries = const [];
  double? _targetWeightKg;
  double? _heightCm;
  bool _isLoading = true;
  bool _isSavingPreferences = false;
  int _loadGeneration = 0;

  StoredWeightEntry? get _latestWeight =>
      _weightEntries.isEmpty ? null : _weightEntries.last;

  double? get _bmi {
    final latestWeight = _latestWeight;
    final heightCm = _heightCm;

    if (latestWeight == null || heightCm == null || heightCm <= 0) {
      return null;
    }

    final heightM = heightCm / 100;
    return latestWeight.weightKg / (heightM * heightM);
  }

  _ProfileBmiCategory? get _bmiCategory {
    final bmi = _bmi;

    if (bmi == null) {
      return null;
    }

    if (bmi < 18.5) {
      return _ProfileBmiCategory.underweight;
    }
    if (bmi < 25) {
      return _ProfileBmiCategory.healthy;
    }
    if (bmi < 30) {
      return _ProfileBmiCategory.overweight;
    }
    return _ProfileBmiCategory.obesity;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.refreshListenable.addListener(_handleRefreshRequest);
    unawaited(_loadProfile());
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable.removeListener(_handleRefreshRequest);
      widget.refreshListenable.addListener(_handleRefreshRequest);
      unawaited(_loadProfile());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadProfile());
    }
  }

  void _handleRefreshRequest() {
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final loadGeneration = ++_loadGeneration;

    try {
      final weightEntriesFuture = WeightStorageService.instance.loadEntries();
      final targetWeightFuture = WeightStorageService.instance
          .loadTargetWeight();
      final heightFuture = BodyMetricsStorageService.instance.loadHeightCm();

      final weightEntries = await weightEntriesFuture;
      final targetWeightKg = await targetWeightFuture;
      final heightCm = await heightFuture;

      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }

      setState(() {
        _weightEntries = weightEntries;
        _targetWeightKg = targetWeightKg;
        _heightCm = heightCm;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showProfilePreferencesEditor() async {
    final updatedPreferences =
        await showModalBottomSheet<StoredProfilePreferences>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) {
            return _ProfilePreferencesEditorSheet(
              isBangla: widget.isBangla,
              initialPreferences: StoredProfilePreferences(
                goal: widget.goal,
                schedule: widget.schedule,
                activity: widget.activity,
                sleep: widget.sleep,
                budget: widget.budget,
              ),
            );
          },
        );

    if (updatedPreferences == null || !mounted) {
      return;
    }

    setState(() {
      _isSavingPreferences = true;
    });

    try {
      await widget.onSavePreferences(updatedPreferences);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'প্রোফাইলের পছন্দ সংরক্ষণ হয়েছে।'
                  : 'Profile preferences have been saved.',
            ),
          ),
        );
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
                  ? 'প্রোফাইলের পছন্দ সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'
                  : 'Profile preferences could not be saved. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPreferences = false;
        });
      }
    }
  }

  String _goalText() {
    final value = widget.goal.trim().toLowerCase();

    if (value.contains('gain') ||
        value.contains('বাড়') ||
        value.contains('বাড়')) {
      return widget.isBangla ? 'ওজন বাড়ানো' : 'Weight gain';
    }

    if (value.contains('loss') ||
        value.contains('lose') ||
        value.contains('কম')) {
      return widget.isBangla ? 'ওজন কমানো' : 'Weight loss';
    }

    if (value.contains('fitness') ||
        value.contains('fit') ||
        value.contains('ফিট')) {
      return widget.isBangla ? 'ফিটনেস উন্নত করা' : 'Improve fitness';
    }

    return widget.isBangla ? 'ওজন বজায় রাখা' : 'Maintain weight';
  }

  String _scheduleText() {
    switch (widget.schedule.trim().toLowerCase()) {
      case 'regular':
        return widget.isBangla ? 'নিয়মিত' : 'Regular';
      case 'irregular':
        return widget.isBangla ? 'অনিয়মিত' : 'Irregular';
      case 'shift_based':
      case 'shift':
        return widget.isBangla ? 'শিফটভিত্তিক' : 'Shift-based';
      default:
        return widget.isBangla ? 'নির্ধারিত নয়' : 'Not specified';
    }
  }

  String _activityText() {
    switch (widget.activity.trim().toLowerCase()) {
      case 'low':
      case 'light':
        return widget.isBangla ? 'কম' : 'Low';
      case 'moderate':
      case 'medium':
        return widget.isBangla ? 'মাঝারি' : 'Moderate';
      case 'high':
        return widget.isBangla ? 'বেশি' : 'High';
      default:
        return widget.isBangla ? 'নির্ধারিত নয়' : 'Not specified';
    }
  }

  String _sleepText() {
    switch (widget.sleep.trim().toLowerCase()) {
      case 'less_than_6':
        return widget.isBangla ? '৬ ঘণ্টার কম' : 'Less than 6 hours';
      case '6_to_7':
        return widget.isBangla ? '৬–৭ ঘণ্টা' : '6–7 hours';
      case '7_to_9':
        return widget.isBangla ? '৭–৯ ঘণ্টা' : '7–9 hours';
      case 'more_than_9':
        return widget.isBangla ? '৯ ঘণ্টার বেশি' : 'More than 9 hours';
      default:
        return widget.isBangla ? 'নির্ধারিত নয়' : 'Not specified';
    }
  }

  String _budgetText() {
    switch (widget.budget.trim().toLowerCase()) {
      case 'budget_friendly':
      case 'low':
        return widget.isBangla ? 'সাশ্রয়ী' : 'Budget-friendly';
      case 'moderate':
      case 'medium':
        return widget.isBangla ? 'মাঝারি' : 'Moderate';
      case 'flexible':
        return widget.isBangla ? 'নমনীয়' : 'Flexible';
      case 'premium':
      case 'high':
        return widget.isBangla ? 'উচ্চ বাজেট' : 'Higher budget';
      default:
        return widget.isBangla ? 'নির্ধারিত নয়' : 'Not specified';
    }
  }

  String _heightText() {
    final heightCm = _heightCm;

    if (heightCm == null) {
      return widget.isBangla ? 'যোগ করা হয়নি' : 'Not added';
    }

    final totalInches = (heightCm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;

    return '${heightCm.toStringAsFixed(1)} cm • $feet ft $inches in';
  }

  String _weightText(double? weightKg) {
    if (weightKg == null) {
      return widget.isBangla ? 'যোগ করা হয়নি' : 'Not added';
    }

    return '${weightKg.toStringAsFixed(1)} kg';
  }

  String _bmiCategoryText() {
    switch (_bmiCategory) {
      case _ProfileBmiCategory.underweight:
        return widget.isBangla ? 'কম ওজন' : 'Underweight';
      case _ProfileBmiCategory.healthy:
        return widget.isBangla ? 'স্বাস্থ্যকর range' : 'Healthy range';
      case _ProfileBmiCategory.overweight:
        return widget.isBangla ? 'অতিরিক্ত ওজন' : 'Overweight';
      case _ProfileBmiCategory.obesity:
        return widget.isBangla ? 'স্থূলতার range' : 'Obesity range';
      case null:
        return widget.isBangla ? 'হিসাব হয়নি' : 'Not calculated';
    }
  }

  String _bmiText() {
    final bmi = _bmi;
    return bmi == null ? '—' : bmi.toStringAsFixed(1);
  }

  @override
  void dispose() {
    widget.refreshListenable.removeListener(_handleRefreshRequest);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.isBangla ? 'প্রোফাইল' : 'Profile'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                widget.isBangla
                    ? 'আপনার স্বাস্থ্য প্রোফাইল'
                    : 'Your health profile',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isBangla
                    ? 'আপনার বর্তমান লক্ষ্য, শরীরের তথ্য এবং জীবনযাপনের পছন্দ এক জায়গায় দেখুন।'
                    : 'Review your current goal, body information, and lifestyle preferences in one place.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 18),
              _ProfileGoalCard(isBangla: widget.isBangla, goal: _goalText()),
              const SizedBox(height: 14),
              _ProfileBodyCard(
                isBangla: widget.isBangla,
                latestWeight: _weightText(_latestWeight?.weightKg),
                targetWeight: _weightText(_targetWeightKg),
                height: _heightText(),
                bmi: _bmiText(),
                bmiCategory: _bmiCategoryText(),
                onManage: widget.onManageBodyInformation,
              ),
              const SizedBox(height: 14),
              _ProfilePreferencesCard(
                isBangla: widget.isBangla,
                schedule: _scheduleText(),
                activity: _activityText(),
                sleep: _sleepText(),
                budget: _budgetText(),
                isSaving: _isSavingPreferences,
                onEdit: _showProfilePreferencesEditor,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
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
                        widget.isBangla
                            ? 'ওজন, লক্ষ্য ওজন বা উচ্চতা পরিবর্তন করলে Progress tab এবং এই Profile summary স্বয়ংক্রিয়ভাবে আপডেট হবে।'
                            : 'Changes to weight, target weight, or height update both the Progress tab and this profile summary.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePreferencesEditorSheet extends StatefulWidget {
  const _ProfilePreferencesEditorSheet({
    required this.isBangla,
    required this.initialPreferences,
  });

  final bool isBangla;
  final StoredProfilePreferences initialPreferences;

  @override
  State<_ProfilePreferencesEditorSheet> createState() =>
      _ProfilePreferencesEditorSheetState();
}

class _ProfilePreferencesEditorSheetState
    extends State<_ProfilePreferencesEditorSheet> {
  late String _goal;
  late String _schedule;
  late String _activity;
  late String _sleep;
  late String _budget;

  @override
  void initState() {
    super.initState();

    _goal = _normaliseGoal(widget.initialPreferences.goal);
    _schedule = _normaliseSchedule(widget.initialPreferences.schedule);
    _activity = _normaliseActivity(widget.initialPreferences.activity);
    _sleep = _normaliseSleep(widget.initialPreferences.sleep);
    _budget = _normaliseBudget(widget.initialPreferences.budget);
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

  String _normaliseSchedule(String value) {
    switch (value.trim().toLowerCase()) {
      case 'regular':
        return 'regular';
      case 'shift':
      case 'shift_based':
        return 'shift_based';
      default:
        return 'irregular';
    }
  }

  String _normaliseActivity(String value) {
    switch (value.trim().toLowerCase()) {
      case 'moderate':
      case 'medium':
        return 'moderate';
      case 'high':
        return 'high';
      default:
        return 'low';
    }
  }

  String _normaliseSleep(String value) {
    switch (value.trim().toLowerCase()) {
      case 'less_than_6':
      case '6_to_7':
      case '7_to_9':
      case 'more_than_9':
        return value.trim().toLowerCase();
      default:
        return '7_to_9';
    }
  }

  String _normaliseBudget(String value) {
    switch (value.trim().toLowerCase()) {
      case 'moderate':
      case 'medium':
        return 'moderate';
      case 'flexible':
        return 'flexible';
      case 'premium':
      case 'high':
        return 'premium';
      default:
        return 'budget_friendly';
    }
  }

  String _goalLabel(String value) {
    switch (value) {
      case 'lose_weight':
        return widget.isBangla ? 'ওজন কমানো' : 'Weight loss';
      case 'gain_weight':
        return widget.isBangla ? 'ওজন বাড়ানো' : 'Weight gain';
      case 'improve_fitness':
        return widget.isBangla ? 'ফিটনেস উন্নত করা' : 'Improve fitness';
      default:
        return widget.isBangla ? 'ওজন বজায় রাখা' : 'Maintain weight';
    }
  }

  String _scheduleLabel(String value) {
    switch (value) {
      case 'regular':
        return widget.isBangla ? 'নিয়মিত' : 'Regular';
      case 'shift_based':
        return widget.isBangla ? 'শিফটভিত্তিক' : 'Shift-based';
      default:
        return widget.isBangla ? 'অনিয়মিত' : 'Irregular';
    }
  }

  String _activityLabel(String value) {
    switch (value) {
      case 'moderate':
        return widget.isBangla ? 'মাঝারি' : 'Moderate';
      case 'high':
        return widget.isBangla ? 'বেশি' : 'High';
      default:
        return widget.isBangla ? 'কম' : 'Low';
    }
  }

  String _sleepLabel(String value) {
    switch (value) {
      case 'less_than_6':
        return widget.isBangla ? '৬ ঘণ্টার কম' : 'Less than 6 hours';
      case '6_to_7':
        return widget.isBangla ? '৬–৭ ঘণ্টা' : '6–7 hours';
      case 'more_than_9':
        return widget.isBangla ? '৯ ঘণ্টার বেশি' : 'More than 9 hours';
      default:
        return widget.isBangla ? '৭–৯ ঘণ্টা' : '7–9 hours';
    }
  }

  String _budgetLabel(String value) {
    switch (value) {
      case 'moderate':
        return widget.isBangla ? 'মাঝারি' : 'Moderate';
      case 'flexible':
        return widget.isBangla ? 'নমনীয়' : 'Flexible';
      case 'premium':
        return widget.isBangla ? 'উচ্চ বাজেট' : 'Higher budget';
      default:
        return widget.isBangla ? 'সাশ্রয়ী' : 'Budget-friendly';
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      StoredProfilePreferences(
        goal: _goal,
        schedule: _schedule,
        activity: _activity,
        sleep: _sleep,
        budget: _budget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isBangla
                  ? 'স্বাস্থ্য লক্ষ্য ও জীবনযাপনের পছন্দ'
                  : 'Health goal and lifestyle preferences',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isBangla
                  ? 'এই পরিবর্তনগুলো Profile এবং Today dashboard-এ ব্যবহার হবে।'
                  : 'These changes will be used in Profile and the Today dashboard.',
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _goal,
              decoration: InputDecoration(
                labelText: widget.isBangla ? 'স্বাস্থ্য লক্ষ্য' : 'Health goal',
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
            const SizedBox(height: 7),
            Text(
              widget.isBangla
                  ? 'লক্ষ্য পরিবর্তন করলে dashboard guidance বদলাবে। বর্তমান calorie target আগের assessment অনুযায়ী থাকবে।'
                  : 'Changing the goal updates dashboard guidance. The current calorie target remains based on the earlier assessment.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _schedule,
              decoration: InputDecoration(
                labelText: widget.isBangla ? 'দৈনিক সময়সূচি' : 'Daily schedule',
                border: const OutlineInputBorder(),
              ),
              items: const ['regular', 'irregular', 'shift_based']
                  .map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(_scheduleLabel(value)),
                    );
                  })
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _schedule = value;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _activity,
              decoration: InputDecoration(
                labelText: widget.isBangla ? 'কর্মচাঞ্চল্য' : 'Activity level',
                border: const OutlineInputBorder(),
              ),
              items: const ['low', 'moderate', 'high']
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
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _sleep,
              decoration: InputDecoration(
                labelText: widget.isBangla ? 'ঘুম' : 'Sleep',
                border: const OutlineInputBorder(),
              ),
              items: const ['less_than_6', '6_to_7', '7_to_9', 'more_than_9']
                  .map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(_sleepLabel(value)),
                    );
                  })
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sleep = value;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _budget,
              decoration: InputDecoration(
                labelText: widget.isBangla ? 'খাবারের বাজেট' : 'Food budget',
                border: const OutlineInputBorder(),
              ),
              items:
                  const ['budget_friendly', 'moderate', 'flexible', 'premium']
                      .map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(_budgetLabel(value)),
                        );
                      })
                      .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _budget = value;
                  });
                }
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                widget.isBangla ? 'পরিবর্তন সংরক্ষণ করুন' : 'Save changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileGoalCard extends StatelessWidget {
  const _ProfileGoalCard({required this.isBangla, required this.goal});

  final bool isBangla;
  final String goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.flag_outlined,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBangla
                        ? 'বর্তমান স্বাস্থ্য লক্ষ্য'
                        : 'Current health goal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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

class _ProfileBodyCard extends StatelessWidget {
  const _ProfileBodyCard({
    required this.isBangla,
    required this.latestWeight,
    required this.targetWeight,
    required this.height,
    required this.bmi,
    required this.bmiCategory,
    required this.onManage,
  });

  final bool isBangla;
  final String latestWeight;
  final String targetWeight;
  final String height;
  final String bmi;
  final String bmiCategory;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility_new_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  isBangla ? 'শরীরের তথ্য' : 'Body information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileInfoRow(
              icon: Icons.monitor_weight_outlined,
              label: isBangla ? 'সর্বশেষ ওজন' : 'Latest weight',
              value: latestWeight,
            ),
            _ProfileInfoRow(
              icon: Icons.flag_outlined,
              label: isBangla ? 'লক্ষ্য ওজন' : 'Target weight',
              value: targetWeight,
            ),
            _ProfileInfoRow(
              icon: Icons.height,
              label: isBangla ? 'উচ্চতা' : 'Height',
              value: height,
            ),
            _ProfileInfoRow(
              icon: Icons.health_and_safety_outlined,
              label: 'BMI',
              value: '$bmi • $bmiCategory',
              showDivider: false,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                isBangla
                    ? 'শরীরের তথ্য পরিবর্তন করুন'
                    : 'Manage body information',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePreferencesCard extends StatelessWidget {
  const _ProfilePreferencesCard({
    required this.isBangla,
    required this.schedule,
    required this.activity,
    required this.sleep,
    required this.budget,
    required this.isSaving,
    required this.onEdit,
  });

  final bool isBangla;
  final String schedule;
  final String activity;
  final String sleep;
  final String budget;
  final bool isSaving;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  isBangla ? 'জীবনযাপনের পছন্দ' : 'Lifestyle preferences',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileInfoRow(
              icon: Icons.schedule_outlined,
              label: isBangla ? 'দৈনিক সময়সূচি' : 'Daily schedule',
              value: schedule,
            ),
            _ProfileInfoRow(
              icon: Icons.directions_run,
              label: isBangla ? 'কর্মচাঞ্চল্য' : 'Activity level',
              value: activity,
            ),
            _ProfileInfoRow(
              icon: Icons.bedtime_outlined,
              label: isBangla ? 'ঘুম' : 'Sleep',
              value: sleep,
            ),
            _ProfileInfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: isBangla ? 'খাবারের বাজেট' : 'Food budget',
              value: budget,
              showDivider: false,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isSaving ? null : onEdit,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit_outlined),
              label: Text(
                isBangla
                    ? 'স্বাস্থ্য লক্ষ্য ও পছন্দ পরিবর্তন করুন'
                    : 'Edit health goal and preferences',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 21, color: colorScheme.primary),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: colorScheme.outlineVariant),
      ],
    );
  }
}
