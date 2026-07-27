import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/habit_storage_service.dart';

class TodayDashboardScreen extends StatefulWidget {
  const TodayDashboardScreen({
    required this.isBangla,
    required this.goal,
    required this.targetCaloriesMin,
    required this.targetCaloriesMax,
    required this.schedule,
    required this.activity,
    required this.sleep,
    required this.budget,
    required this.refreshListenable,
    super.key,
  });

  final bool isBangla;
  final String goal;
  final int targetCaloriesMin;
  final int targetCaloriesMax;
  final String schedule;
  final String activity;
  final String sleep;
  final String budget;
  final ValueListenable<int> refreshListenable;

  @override
  State<TodayDashboardScreen> createState() => _TodayDashboardScreenState();
}

class _TodayDashboardScreenState extends State<TodayDashboardScreen>
    with WidgetsBindingObserver {
  List<bool> _completedHabits = [false, false, false];
  StoredDailyCheckIn? _dailyCheckIn;
  int _summaryLoadGeneration = 0;

  bool get isBangla => widget.isBangla;
  String get goal => widget.goal;
  int get targetCaloriesMin => widget.targetCaloriesMin;
  int get targetCaloriesMax => widget.targetCaloriesMax;
  String get schedule => widget.schedule;
  String get activity => widget.activity;
  String get sleep => widget.sleep;
  String get budget => widget.budget;

  int get _completedHabitCount =>
      _completedHabits.where((isCompleted) => isCompleted).length;

  double get _habitProgress => _completedHabits.isEmpty
      ? 0.0
      : _completedHabitCount / _completedHabits.length;

  bool get _hasDailyCheckIn => _dailyCheckIn != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.refreshListenable.addListener(_handleRefreshRequest);
    unawaited(_loadLiveSummary());
  }

  @override
  void didUpdateWidget(covariant TodayDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable.removeListener(_handleRefreshRequest);
      widget.refreshListenable.addListener(_handleRefreshRequest);
      unawaited(_loadLiveSummary());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadLiveSummary());
    }
  }

  void _handleRefreshRequest() {
    unawaited(_loadLiveSummary());
  }

  Future<void> _loadLiveSummary() async {
    final loadGeneration = ++_summaryLoadGeneration;

    try {
      final completionsFuture = HabitStorageService.instance
          .loadTodayCompletions(_completedHabits.length);
      final checkInFuture = HabitStorageService.instance.loadTodayCheckIn();

      final savedCompletions = await completionsFuture;
      final savedCheckIn = await checkInFuture;

      if (!mounted || loadGeneration != _summaryLoadGeneration) {
        return;
      }

      setState(() {
        _completedHabits = savedCompletions;
        _dailyCheckIn = savedCheckIn;
      });
    } catch (_) {
      // Summary read ব্যর্থ হলে আগের visible state রাখা হবে।
    }
  }

  String _storedMoodName(int moodIndex) {
    switch (moodIndex) {
      case 0:
        return isBangla ? 'কঠিন দিন' : 'Difficult';
      case 1:
        return isBangla ? 'মোটামুটি' : 'Okay';
      case 2:
        return isBangla ? 'ভালো' : 'Good';
      case 3:
        return isBangla ? 'দারুণ' : 'Great';
      default:
        return isBangla ? 'অজানা' : 'Unknown';
    }
  }

  String get _checkInSummary {
    final checkIn = _dailyCheckIn;

    if (checkIn == null) {
      return isBangla
          ? 'আজ এখনো Daily Check-in করা হয়নি।'
          : 'No daily check-in has been saved yet.';
    }

    return isBangla
        ? 'মুড: ${_storedMoodName(checkIn.moodIndex)} • শক্তি: ${checkIn.energyLevel}/৫'
        : 'Mood: ${_storedMoodName(checkIn.moodIndex)} • Energy: ${checkIn.energyLevel}/5';
  }

  @override
  void dispose() {
    widget.refreshListenable.removeListener(_handleRefreshRequest);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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

  String _mealFocus() {
    switch (schedule) {
      case 'regular':
        return isBangla
            ? 'কাছাকাছি সময়ে ৩টি প্রধান খাবার গ্রহণ করুন এবং দীর্ঘ সময় না খেয়ে থাকা এড়িয়ে চলুন।'
            : 'Have 3 main meals at similar times and avoid long gaps without food.';
      case 'irregular':
        return isBangla
            ? 'আজকের কাজ অনুযায়ী ৩টি flexible meal window আগে থেকেই ঠিক করে রাখুন।'
            : 'Set 3 flexible meal windows in advance around today’s schedule.';
      default:
        return isBangla
            ? 'কাজের shift অনুযায়ী meal time ও বহনযোগ্য খাবার আগে থেকে পরিকল্পনা করুন।'
            : 'Plan meal times and portable foods around your work shift.';
    }
  }

  String _activityFocus() {
    switch (activity) {
      case 'light':
        return isBangla
            ? 'আজ প্রায় ৩০ মিনিট হাঁটা বা হালকা ব্যায়ামের চেষ্টা করুন।'
            : 'Aim for about 30 minutes of walking or light exercise today.';
      case 'moderate':
        return isBangla
            ? 'আজকের নিয়মিত activity বজায় রাখুন এবং recovery-এর জন্য সময় রাখুন।'
            : 'Maintain your regular activity today and allow time for recovery.';
      case 'high':
        return isBangla
            ? 'Training-এর সঙ্গে খাবার, পানি ও recovery-এর ভারসাম্য বজায় রাখুন।'
            : 'Balance today’s training with food, hydration, and recovery.';
      default:
        return isBangla
            ? 'আজ ২০–৩০ মিনিট হালকা হাঁটা দিয়ে সক্রিয় থাকার চেষ্টা করুন।'
            : 'Try to stay active with 20–30 minutes of light walking today.';
    }
  }

  String _sleepFocus() {
    switch (sleep) {
      case 'less_than_6':
        return isBangla
            ? 'আজ একটু আগে ঘুমাতে গিয়ে ঘুমের সময় ধীরে বাড়ানোর চেষ্টা করুন।'
            : 'Try going to bed a little earlier to gradually increase your sleep.';
      case '6_to_7':
        return isBangla
            ? 'নিয়মিত bedtime রাখুন এবং সম্ভব হলে ৭ ঘণ্টা বা বেশি ঘুমান।'
            : 'Keep a regular bedtime and aim for at least 7 hours when possible.';
      case '7_to_9':
        return isBangla
            ? 'বর্তমান ৭–৯ ঘণ্টার ঘুম এবং নিয়মিত sleep schedule বজায় রাখুন।'
            : 'Maintain your current 7–9 hours of sleep and regular schedule.';
      default:
        return isBangla
            ? 'নিয়মিত sleep schedule রাখুন এবং ঘুমের পর সতেজতা লক্ষ্য করুন।'
            : 'Keep a regular sleep schedule and notice how refreshed you feel.';
    }
  }

  String _budgetFocus() {
    switch (budget) {
      case 'budget_friendly':
        return isBangla
            ? 'ডাল, ডিম, ছোলা ও মৌসুমি সবজির মতো সহজলভ্য স্থানীয় খাবার বেছে নিন।'
            : 'Choose accessible local foods such as lentils, eggs, chickpeas, and seasonal vegetables.';
      case 'moderate':
        return isBangla
            ? 'স্থানীয় খাবারের সঙ্গে মাছ, মুরগি, দুধ বা দইয়ের মতো protein source রাখুন।'
            : 'Combine local foods with protein sources such as fish, chicken, milk, or yogurt.';
      default:
        return isBangla
            ? 'বিভিন্ন whole food বেছে নিয়ে portion ও খাবারের ভারসাম্য বজায় রাখুন।'
            : 'Choose varied whole foods while keeping portions balanced.';
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isBangla
                ? '$feature ফিচারটি পরবর্তী development ধাপে যোগ করা হবে'
                : '$feature will be added in a later development step',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('FitBalance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isBangla ? 'আজকের ড্যাশবোর্ড' : 'Today dashboard',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isBangla
                    ? 'আপনার লক্ষ্য অনুযায়ী আজকের স্বাস্থ্যকর অভ্যাসগুলো অনুসরণ করুন।'
                    : 'Follow today’s healthy habits based on your goal.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.flag_outlined,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBangla
                                ? 'আপনার নিশ্চিত করা লক্ষ্য'
                                : 'Your confirmed goal',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _goalLabel(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isBangla
                                ? 'দৈনিক calorie target'
                                : 'Daily calorie target',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$targetCaloriesMin–$targetCaloriesMax kcal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                          Expanded(
                            child: Text(
                              isBangla
                                  ? 'আজকের calorie progress'
                                  : 'Today’s calorie progress',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '0 kcal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: const LinearProgressIndicator(
                          value: 0.0,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isBangla
                            ? 'Target: $targetCaloriesMin–$targetCaloriesMax kcal'
                            : 'Target: $targetCaloriesMin–$targetCaloriesMax kcal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBangla
                            ? 'খাবার log করার পর এখানে দৈনিক progress দেখা যাবে।'
                            : 'Daily progress will appear here after meals are logged.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _TodayHabitSummaryCard(
                isBangla: isBangla,
                completedCount: _completedHabitCount,
                totalCount: _completedHabits.length,
                progress: _habitProgress,
                hasCheckIn: _hasDailyCheckIn,
                checkInSummary: _checkInSummary,
              ),
              const SizedBox(height: 24),
              Text(
                isBangla ? 'দ্রুত কাজ' : 'Quick actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.restaurant_menu,
                      label: isBangla ? 'খাবার' : 'Meal',
                      onTap: () => _showComingSoon(
                        context,
                        isBangla ? 'খাবার লগ' : 'Meal logging',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.directions_walk,
                      label: isBangla ? 'ব্যায়াম' : 'Activity',
                      onTap: () => _showComingSoon(
                        context,
                        isBangla ? 'ব্যায়াম লগ' : 'Activity logging',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.check_circle_outline,
                      label: isBangla ? 'অভ্যাস' : 'Habits',
                      onTap: () => _showComingSoon(
                        context,
                        isBangla ? 'অভ্যাস ট্র্যাকিং' : 'Habit tracking',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                isBangla ? 'আজকের মূল লক্ষ্য' : 'Today’s focus',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _FocusItem(
                icon: Icons.restaurant_outlined,
                title: isBangla ? 'খাবারের সময়' : 'Meal timing',
                description: _mealFocus(),
              ),
              const SizedBox(height: 12),
              _FocusItem(
                icon: Icons.fitness_center,
                title: isBangla ? 'শারীরিক সক্রিয়তা' : 'Physical activity',
                description: _activityFocus(),
              ),
              const SizedBox(height: 12),
              _FocusItem(
                icon: Icons.bedtime_outlined,
                title: isBangla ? 'ঘুম ও recovery' : 'Sleep and recovery',
                description: _sleepFocus(),
              ),
              const SizedBox(height: 12),
              _FocusItem(
                icon: Icons.account_balance_wallet_outlined,
                title: isBangla ? 'বাজেট অনুযায়ী খাবার' : 'Budget-based food',
                description: _budgetFocus(),
              ),
              const SizedBox(height: 20),
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
                            ? 'প্রতিদিনের ছোট ও ধারাবাহিক পরিবর্তনই দীর্ঘমেয়াদি অগ্রগতির ভিত্তি।'
                            : 'Small, consistent daily changes are the foundation of long-term progress.',
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

class _TodayHabitSummaryCard extends StatelessWidget {
  const _TodayHabitSummaryCard({
    required this.isBangla,
    required this.completedCount,
    required this.totalCount,
    required this.progress,
    required this.hasCheckIn,
    required this.checkInSummary,
  });

  final bool isBangla;
  final int completedCount;
  final int totalCount;
  final double progress;
  final bool hasCheckIn;
  final String checkInSummary;

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
                Expanded(
                  child: Text(
                    isBangla ? 'আজকের অভ্যাস' : "Today's habits",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  isBangla
                      ? '$completedCount / $totalCount সম্পন্ন'
                      : '$completedCount / $totalCount completed',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
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
                  hasCheckIn ? Icons.fact_check : Icons.fact_check_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBangla ? 'দৈনিক চেক-ইন' : 'Daily check-in',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        checkInSummary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusItem extends StatelessWidget {
  const _FocusItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
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
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 5),
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
