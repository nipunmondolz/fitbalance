import 'dart:async';
import 'dart:math' as math;

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

enum _ProgressChartMetric { calories, water, exercise, sleep, habits }

class _ChartBarData {
  const _ChartBarData({
    required this.label,
    required this.value,
    required this.valueText,
  });

  final String label;
  final double value;
  final String valueText;
}

class _ProgressDay {
  const _ProgressDay({
    required this.date,
    required this.dailyLogSummary,
    required this.habitCompletions,
    required this.dailyCheckIn,
  });

  final DateTime date;
  final DailyLogSummary dailyLogSummary;
  final List<bool> habitCompletions;
  final StoredDailyCheckIn? dailyCheckIn;

  int get completedHabitCount =>
      habitCompletions.where((isCompleted) => isCompleted).length;

  bool get hasSavedData =>
      dailyLogSummary.calories > 0 ||
      dailyLogSummary.waterGlasses > 0 ||
      dailyLogSummary.softDrinkMl > 0 ||
      dailyLogSummary.exerciseMinutes > 0 ||
      dailyLogSummary.sleepHours > 0 ||
      completedHabitCount > 0 ||
      dailyCheckIn != null;
}

class _ProgressScreenState extends State<ProgressScreen>
    with WidgetsBindingObserver {
  static const int _habitCount = 3;

  DailyLogSummary _dailyLogSummary = DailyLogSummary.empty;
  List<bool> _habitCompletions = List<bool>.filled(_habitCount, false);
  StoredDailyCheckIn? _dailyCheckIn;
  List<_ProgressDay> _sevenDayProgress = const [];
  _ProgressChartMetric _selectedChartMetric = _ProgressChartMetric.calories;

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

  List<_ProgressDay> get _loggedProgressDays => _sevenDayProgress
      .where((progressDay) => progressDay.hasSavedData)
      .toList(growable: false);

  double _loggedDayAverage(double Function(_ProgressDay progressDay) valueOf) {
    final loggedDays = _loggedProgressDays;

    if (loggedDays.isEmpty) {
      return 0;
    }

    final total = loggedDays.fold<double>(
      0,
      (sum, progressDay) => sum + valueOf(progressDay),
    );

    return total / loggedDays.length;
  }

  double get _averageCalories => _loggedDayAverage(
    (progressDay) => progressDay.dailyLogSummary.calories.toDouble(),
  );

  double get _averageWater => _loggedDayAverage(
    (progressDay) => progressDay.dailyLogSummary.waterGlasses.toDouble(),
  );

  double get _averageExercise => _loggedDayAverage(
    (progressDay) => progressDay.dailyLogSummary.exerciseMinutes.toDouble(),
  );

  double get _averageSleep => _loggedDayAverage(
    (progressDay) => progressDay.dailyLogSummary.sleepHours,
  );

  double get _habitConsistency {
    final loggedDays = _loggedProgressDays;

    if (loggedDays.isEmpty) {
      return 0;
    }

    final completedHabits = loggedDays.fold<int>(
      0,
      (sum, progressDay) => sum + progressDay.completedHabitCount,
    );
    final availableHabits = loggedDays.length * _habitCount;

    return availableHabits == 0 ? 0 : (completedHabits / availableHabits) * 100;
  }

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

  Future<_ProgressDay> _loadProgressDay(DateTime date) async {
    final dailyLogFuture = DailyLogStorageService.instance.loadSummaryForDate(
      date,
    );
    final habitFuture = HabitStorageService.instance.loadCompletionsForDate(
      date,
      _habitCount,
    );
    final checkInFuture = HabitStorageService.instance.loadCheckInForDate(date);

    final dailyLogSummary = await dailyLogFuture;
    final habitCompletions = await habitFuture;
    final dailyCheckIn = await checkInFuture;

    return _ProgressDay(
      date: date,
      dailyLogSummary: dailyLogSummary,
      habitCompletions: habitCompletions,
      dailyCheckIn: dailyCheckIn,
    );
  }

  Future<void> _loadProgress() async {
    final loadGeneration = ++_loadGeneration;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: index)),
      growable: false,
    );

    try {
      final sevenDayProgress = await Future.wait(dates.map(_loadProgressDay));

      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }

      final todayProgress = sevenDayProgress.first;

      setState(() {
        _dailyLogSummary = todayProgress.dailyLogSummary;
        _habitCompletions = todayProgress.habitCompletions;
        _dailyCheckIn = todayProgress.dailyCheckIn;
        _sevenDayProgress = sevenDayProgress;
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

  String _dateLabel(DateTime date, int index) {
    const monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const monthsBn = [
      'জানু',
      'ফেব',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টে',
      'অক্টো',
      'নভে',
      'ডিসে',
    ];

    final relativeLabel = switch (index) {
      0 => widget.isBangla ? 'আজ' : 'Today',
      1 => widget.isBangla ? 'গতকাল' : 'Yesterday',
      _ => null,
    };

    final month = widget.isBangla
        ? monthsBn[date.month - 1]
        : monthsEn[date.month - 1];
    final dateText = '${date.day} $month';

    return relativeLabel == null ? dateText : '$relativeLabel • $dateText';
  }

  String _chartMetricLabel(_ProgressChartMetric metric) {
    switch (metric) {
      case _ProgressChartMetric.calories:
        return widget.isBangla ? 'ক্যালরি' : 'Calories';
      case _ProgressChartMetric.water:
        return widget.isBangla ? 'পানি' : 'Water';
      case _ProgressChartMetric.exercise:
        return widget.isBangla ? 'ব্যায়াম' : 'Exercise';
      case _ProgressChartMetric.sleep:
        return widget.isBangla ? 'ঘুম' : 'Sleep';
      case _ProgressChartMetric.habits:
        return widget.isBangla ? 'অভ্যাস' : 'Habits';
    }
  }

  IconData _chartMetricIcon(_ProgressChartMetric metric) {
    switch (metric) {
      case _ProgressChartMetric.calories:
        return Icons.local_fire_department;
      case _ProgressChartMetric.water:
        return Icons.water_drop;
      case _ProgressChartMetric.exercise:
        return Icons.directions_run;
      case _ProgressChartMetric.sleep:
        return Icons.bedtime;
      case _ProgressChartMetric.habits:
        return Icons.check_circle_outline;
    }
  }

  double _chartMetricValue(
    _ProgressDay progressDay,
    _ProgressChartMetric metric,
  ) {
    switch (metric) {
      case _ProgressChartMetric.calories:
        return progressDay.dailyLogSummary.calories.toDouble();
      case _ProgressChartMetric.water:
        return progressDay.dailyLogSummary.waterGlasses.toDouble();
      case _ProgressChartMetric.exercise:
        return progressDay.dailyLogSummary.exerciseMinutes.toDouble();
      case _ProgressChartMetric.sleep:
        return progressDay.dailyLogSummary.sleepHours;
      case _ProgressChartMetric.habits:
        return progressDay.habitCompletions.isEmpty
            ? 0
            : (progressDay.completedHabitCount /
                      progressDay.habitCompletions.length) *
                  100;
    }
  }

  String _chartValueText(
    _ProgressDay progressDay,
    _ProgressChartMetric metric,
  ) {
    final value = _chartMetricValue(progressDay, metric);

    switch (metric) {
      case _ProgressChartMetric.calories:
      case _ProgressChartMetric.water:
      case _ProgressChartMetric.exercise:
        return value.round().toString();
      case _ProgressChartMetric.sleep:
        return value.toStringAsFixed(1);
      case _ProgressChartMetric.habits:
        return '${value.round()}%';
    }
  }

  String _chartAverageText(_ProgressChartMetric metric) {
    switch (metric) {
      case _ProgressChartMetric.calories:
        return '≈ ${_averageCalories.round()} kcal';
      case _ProgressChartMetric.water:
        return widget.isBangla
            ? '${_averageWater.toStringAsFixed(1)} গ্লাস'
            : '${_averageWater.toStringAsFixed(1)} glasses';
      case _ProgressChartMetric.exercise:
        return widget.isBangla
            ? '${_averageExercise.round()} মিনিট'
            : '${_averageExercise.round()} min';
      case _ProgressChartMetric.sleep:
        return widget.isBangla
            ? '${_averageSleep.toStringAsFixed(1)} ঘণ্টা'
            : '${_averageSleep.toStringAsFixed(1)} hours';
      case _ProgressChartMetric.habits:
        return '${_habitConsistency.round()}%';
    }
  }

  String _shortDayLabel(DateTime date) {
    const weekdaysBn = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
    const weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return widget.isBangla
        ? weekdaysBn[date.weekday - 1]
        : weekdaysEn[date.weekday - 1];
  }

  List<_ChartBarData> get _chartBars {
    return _sevenDayProgress.reversed
        .map((progressDay) {
          return _ChartBarData(
            label: _shortDayLabel(progressDay.date),
            value: _chartMetricValue(progressDay, _selectedChartMetric),
            valueText: _chartValueText(progressDay, _selectedChartMetric),
          );
        })
        .toList(growable: false);
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
              const SizedBox(height: 24),
              Text(
                widget.isBangla ? 'গত ৭ দিনের অগ্রগতি' : 'Last 7 days',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isBangla
                    ? 'সারাংশ, chart এবং প্রতিদিনের সংরক্ষিত তথ্য একসঙ্গে দেখুন।'
                    : 'Review averages, charts, and saved daily records together.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _SevenDayOverviewCard(
                isBangla: widget.isBangla,
                loggedDays: _loggedProgressDays.length,
                averageCalories: _averageCalories,
                averageWater: _averageWater,
                averageExercise: _averageExercise,
                averageSleep: _averageSleep,
                habitConsistency: _habitConsistency,
              ),
              const SizedBox(height: 14),
              _SevenDayChartCard(
                isBangla: widget.isBangla,
                selectedMetric: _selectedChartMetric,
                metricLabel: _chartMetricLabel(_selectedChartMetric),
                metricIcon: _chartMetricIcon(_selectedChartMetric),
                averageText: _chartAverageText(_selectedChartMetric),
                bars: _chartBars,
                onMetricSelected: (metric) {
                  setState(() {
                    _selectedChartMetric = metric;
                  });
                },
                metricLabelBuilder: _chartMetricLabel,
                metricIconBuilder: _chartMetricIcon,
              ),
              const SizedBox(height: 20),
              Text(
                widget.isBangla ? 'প্রতিদিনের বিস্তারিত' : 'Daily details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (_sevenDayProgress.isEmpty && !_isLoading)
                _EmptyHistoryCard(
                  message: widget.isBangla
                      ? 'এখনো কোনো history পাওয়া যায়নি।'
                      : 'No history is available yet.',
                )
              else
                ...List<Widget>.generate(_sevenDayProgress.length, (index) {
                  final progressDay = _sevenDayProgress[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SevenDayProgressCard(
                      isBangla: widget.isBangla,
                      dateLabel: _dateLabel(progressDay.date, index),
                      progressDay: progressDay,
                    ),
                  );
                }),
              const SizedBox(height: 4),
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
                            ? 'গড় হিসাব শুধু যেসব দিনে অন্তত একটি তথ্য সংরক্ষিত হয়েছে, সেই দিনগুলোর উপর ভিত্তি করে।'
                            : 'Averages are based only on days that contain at least one saved record.',
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

class _SevenDayOverviewCard extends StatelessWidget {
  const _SevenDayOverviewCard({
    required this.isBangla,
    required this.loggedDays,
    required this.averageCalories,
    required this.averageWater,
    required this.averageExercise,
    required this.averageSleep,
    required this.habitConsistency,
  });

  final bool isBangla;
  final int loggedDays;
  final double averageCalories;
  final double averageWater;
  final double averageExercise;
  final double averageSleep;
  final double habitConsistency;

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
              isBangla ? '৭ দিনের সারাংশ' : 'Seven-day overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBangla ? 'লগ করা দিনের গড়' : 'Averages for logged days',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 2.05,
              children: [
                _OverviewMetric(
                  icon: Icons.calendar_month_outlined,
                  value: '$loggedDays/7',
                  label: isBangla ? 'দিন লগ করা' : 'days logged',
                ),
                _OverviewMetric(
                  icon: Icons.local_fire_department,
                  value: '≈ ${averageCalories.round()}',
                  label: 'kcal',
                ),
                _OverviewMetric(
                  icon: Icons.water_drop,
                  value: averageWater.toStringAsFixed(1),
                  label: isBangla ? 'গ্লাস পানি' : 'glasses water',
                ),
                _OverviewMetric(
                  icon: Icons.directions_run,
                  value: '${averageExercise.round()}',
                  label: isBangla ? 'মিনিট ব্যায়াম' : 'exercise minutes',
                ),
                _OverviewMetric(
                  icon: Icons.bedtime,
                  value: averageSleep.toStringAsFixed(1),
                  label: isBangla ? 'ঘণ্টা ঘুম' : 'sleep hours',
                ),
                _OverviewMetric(
                  icon: Icons.check_circle_outline,
                  value: '${habitConsistency.round()}%',
                  label: isBangla
                      ? 'অভ্যাসের ধারাবাহিকতা'
                      : 'habit consistency',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
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
                maxLines: 2,
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

class _SevenDayChartCard extends StatelessWidget {
  const _SevenDayChartCard({
    required this.isBangla,
    required this.selectedMetric,
    required this.metricLabel,
    required this.metricIcon,
    required this.averageText,
    required this.bars,
    required this.onMetricSelected,
    required this.metricLabelBuilder,
    required this.metricIconBuilder,
  });

  final bool isBangla;
  final _ProgressChartMetric selectedMetric;
  final String metricLabel;
  final IconData metricIcon;
  final String averageText;
  final List<_ChartBarData> bars;
  final ValueChanged<_ProgressChartMetric> onMetricSelected;
  final String Function(_ProgressChartMetric metric) metricLabelBuilder;
  final IconData Function(_ProgressChartMetric metric) metricIconBuilder;

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
              isBangla ? '৭ দিনের chart' : 'Seven-day chart',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _ProgressChartMetric.values
                    .map((metric) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(metricIconBuilder(metric), size: 18),
                          label: Text(metricLabelBuilder(metric)),
                          selected: selectedMetric == metric,
                          onSelected: (_) => onMetricSelected(metric),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(metricIcon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    metricLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  averageText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isBangla
                  ? 'বাম দিকের bar সবচেয়ে পুরোনো দিন, ডান দিকের bar আজ।'
                  : 'The oldest day is on the left and today is on the right.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _SevenDayBarChart(bars: bars),
          ],
        ),
      ),
    );
  }
}

class _SevenDayBarChart extends StatelessWidget {
  const _SevenDayBarChart({required this.bars});

  final List<_ChartBarData> bars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    var maximumValue = 0.0;
    for (final bar in bars) {
      maximumValue = math.max(maximumValue, bar.value);
    }

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars
            .map((bar) {
              final heightFactor = maximumValue <= 0
                  ? 0.0
                  : (bar.value / maximumValue).clamp(0.0, 1.0).toDouble();
              final barHeight = bar.value <= 0
                  ? 6.0
                  : math.max(12.0, heightFactor * 108).toDouble();

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 22,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            bar.valueText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 108,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: 22,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: bar.value <= 0
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bar.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
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

class _SevenDayProgressCard extends StatelessWidget {
  const _SevenDayProgressCard({
    required this.isBangla,
    required this.dateLabel,
    required this.progressDay,
  });

  final bool isBangla;
  final String dateLabel;
  final _ProgressDay progressDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = progressDay.dailyLogSummary;
    final checkIn = progressDay.dailyCheckIn;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: progressDay.hasSavedData
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    progressDay.hasSavedData
                        ? (isBangla ? 'তথ্য আছে' : 'Saved')
                        : (isBangla ? 'তথ্য নেই' : 'No data'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: progressDay.hasSavedData
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.local_fire_department,
                        value: '${summary.calories}',
                        label: 'kcal',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.water_drop,
                        value: '${summary.waterGlasses}',
                        label: isBangla ? 'গ্লাস পানি' : 'glasses water',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.directions_run,
                        value: '${summary.exerciseMinutes}',
                        label: isBangla ? 'মিনিট ব্যায়াম' : 'exercise min',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.bedtime,
                        value: summary.sleepHours.toStringAsFixed(1),
                        label: isBangla ? 'ঘণ্টা ঘুম' : 'sleep hours',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.check_circle_outline,
                        value:
                            '${progressDay.completedHabitCount}/${progressDay.habitCompletions.length}',
                        label: isBangla ? 'অভ্যাস' : 'habits',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: checkIn == null
                            ? Icons.fact_check_outlined
                            : Icons.fact_check,
                        value: checkIn == null
                            ? '—'
                            : '${checkIn.energyLevel}/5',
                        label: isBangla ? 'চেক-ইন' : 'check-in',
                      ),
                    ),
                  ],
                );
              },
            ),
            if (summary.softDrinkMl > 0) ...[
              const SizedBox(height: 12),
              Text(
                isBangla
                    ? 'কোমল পানীয়: ${summary.softDrinkMl} ml'
                    : 'Soft drink: ${summary.softDrinkMl} ml',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({
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
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
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

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
