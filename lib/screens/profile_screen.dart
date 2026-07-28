import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/body_metrics_storage_service.dart';
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
  });

  final bool isBangla;
  final String schedule;
  final String activity;
  final String sleep;
  final String budget;

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
