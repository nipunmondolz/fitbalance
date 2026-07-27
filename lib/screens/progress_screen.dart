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
                widget.isBangla ? 'গত ৭ দিনের ইতিহাস' : 'Last 7 days',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isBangla
                    ? 'ডিভাইসে সংরক্ষিত প্রতিদিনের তথ্য এখানে দেখা যাবে।'
                    : 'Daily records saved on this device appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
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
                            ? '৭ দিনের history এখন প্রস্তুত। পরবর্তী ধাপে lightweight chart ও average summary যোগ হবে।'
                            : 'Seven-day history is now ready. Lightweight charts and average summaries will be added next.',
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
