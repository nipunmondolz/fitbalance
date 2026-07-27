import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/daily_log_storage_service.dart';
import '../services/habit_storage_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    required this.isBangla,
    required this.targetCaloriesMin,
    required this.targetCaloriesMax,
    required this.refreshListenable,
    super.key,
  });

  final bool isBangla;
  final int targetCaloriesMin;
  final int targetCaloriesMax;
  final ValueListenable<int> refreshListenable;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with WidgetsBindingObserver {
  DailyLogSummary _dailyLogSummary = DailyLogSummary.empty;
  List<bool> _habitCompletions = [false, false, false];
  StoredDailyCheckIn? _dailyCheckIn;

  bool _isLoading = true;
  int _loadGeneration = 0;

  int get _completedHabitCount =>
      _habitCompletions.where((isCompleted) => isCompleted).length;

  double get _habitProgress => _habitCompletions.isEmpty
      ? 0
      : _completedHabitCount / _habitCompletions.length;

  double get _calorieProgress => widget.targetCaloriesMax <= 0
      ? 0
      : (_dailyLogSummary.calories / widget.targetCaloriesMax)
            .clamp(0.0, 1.0)
            .toDouble();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.refreshListenable.addListener(_handleRefreshRequest);
    unawaited(_loadProgress());
  }

  @override
  void didUpdateWidget(covariant ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable.removeListener(_handleRefreshRequest);
      widget.refreshListenable.addListener(_handleRefreshRequest);
      unawaited(_loadProgress());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadProgress());
    }
  }

  void _handleRefreshRequest() {
    unawaited(_loadProgress());
  }

  Future<void> _loadProgress() async {
    final loadGeneration = ++_loadGeneration;

    try {
      final dailyLogFuture = DailyLogStorageService.instance.loadTodaySummary();
      final habitFuture = HabitStorageService.instance.loadTodayCompletions(
        _habitCompletions.length,
      );
      final checkInFuture = HabitStorageService.instance.loadTodayCheckIn();

      final dailyLogSummary = await dailyLogFuture;
      final habitCompletions = await habitFuture;
      final dailyCheckIn = await checkInFuture;

      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }

      setState(() {
        _dailyLogSummary = dailyLogSummary;
        _habitCompletions = habitCompletions;
        _dailyCheckIn = dailyCheckIn;
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

  String _moodName(int moodIndex) {
    switch (moodIndex) {
      case 0:
        return widget.isBangla ? 'কঠিন দিন' : 'Difficult';
      case 1:
        return widget.isBangla ? 'মোটামুটি' : 'Okay';
      case 2:
        return widget.isBangla ? 'ভালো' : 'Good';
      case 3:
        return widget.isBangla ? 'দারুণ' : 'Great';
      default:
        return widget.isBangla ? 'অজানা' : 'Unknown';
    }
  }

  String get _checkInText {
    final checkIn = _dailyCheckIn;

    if (checkIn == null) {
      return widget.isBangla
          ? 'আজ এখনো Daily Check-in করা হয়নি।'
          : 'No daily check-in has been saved yet.';
    }

    return widget.isBangla
        ? 'মুড: ${_moodName(checkIn.moodIndex)} • শক্তি: ${checkIn.energyLevel}/৫'
        : 'Mood: ${_moodName(checkIn.moodIndex)} • Energy: ${checkIn.energyLevel}/5';
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
        title: Text(widget.isBangla ? 'অগ্রগতি' : 'Progress'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProgress,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                widget.isBangla ? 'আজকের অগ্রগতি' : "Today's progress",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isBangla
                    ? 'আজকের সংরক্ষিত খাবার, পানি, ব্যায়াম, ঘুম ও অভ্যাসের সারাংশ।'
                    : 'A summary of today’s saved food, hydration, exercise, sleep, and habits.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 18),
              _ProgressSectionCard(
                title: widget.isBangla ? 'ক্যালরি অগ্রগতি' : 'Calorie progress',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '≈ ${_dailyLogSummary.calories} kcal',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${(_calorieProgress * 100).round()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _calorieProgress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      widget.isBangla
                          ? 'লক্ষ্য: ${widget.targetCaloriesMin}–${widget.targetCaloriesMax} kcal'
                          : 'Target: ${widget.targetCaloriesMin}–${widget.targetCaloriesMax} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ProgressSectionCard(
                title: widget.isBangla
                    ? 'আজকের স্বাস্থ্য সারাংশ'
                    : 'Today’s health summary',
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.15,
                  children: [
                    _ProgressMetric(
                      icon: Icons.water_drop,
                      value: '${_dailyLogSummary.waterGlasses}',
                      label: widget.isBangla ? 'গ্লাস পানি' : 'glasses water',
                    ),
                    _ProgressMetric(
                      icon: Icons.local_drink,
                      value: '${_dailyLogSummary.softDrinkMl} ml',
                      label: widget.isBangla ? 'কোমল পানীয়' : 'soft drink',
                    ),
                    _ProgressMetric(
                      icon: Icons.directions_run,
                      value: '${_dailyLogSummary.exerciseMinutes}',
                      label: widget.isBangla
                          ? 'মিনিট ব্যায়াম'
                          : 'exercise minutes',
                    ),
                    _ProgressMetric(
                      icon: Icons.bedtime,
                      value: _dailyLogSummary.sleepHours.toStringAsFixed(1),
                      label: widget.isBangla ? 'ঘণ্টা ঘুম' : 'sleep hours',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ProgressSectionCard(
                title: widget.isBangla
                    ? 'অভ্যাস ও চেক-ইন'
                    : 'Habits and check-in',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.isBangla
                                ? '$_completedHabitCount / ${_habitCompletions.length} অভ্যাস সম্পন্ন'
                                : '$_completedHabitCount / ${_habitCompletions.length} habits completed',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(_habitProgress * 100).round()}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _habitProgress,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _dailyCheckIn == null
                              ? Icons.fact_check_outlined
                              : Icons.fact_check,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _checkInText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      Icons.insights_outlined,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isBangla
                            ? 'এই ধাপে আজকের তথ্য দেখানো হচ্ছে। পরবর্তী ধাপে ৭ দিনের history ও chart যোগ হবে।'
                            : 'This step shows today’s data. Seven-day history and charts will be added next.',
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

class _ProgressSectionCard extends StatelessWidget {
  const _ProgressSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
