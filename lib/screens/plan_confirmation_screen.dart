import 'package:flutter/material.dart';

import 'dashboard_navigation_screen.dart';

class PlanConfirmationScreen extends StatelessWidget {
  const PlanConfirmationScreen({
    required this.isBangla,
    required this.goal,
    required this.targetCaloriesMin,
    required this.targetCaloriesMax,
    required this.schedule,
    required this.activity,
    required this.sleep,
    required this.budget,
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

  String _goalStrategy() {
    switch (_goalKind) {
      case 'loss':
        return isBangla
            ? 'ধীরে ও টেকসইভাবে calorie deficit বজায় রাখা'
            : 'Maintain a gradual and sustainable calorie deficit';
      case 'gain':
        return isBangla
            ? 'ধীরে ও নিয়ন্ত্রিতভাবে calorie surplus বজায় রাখা'
            : 'Maintain a gradual and controlled calorie surplus';
      case 'fitness':
        return isBangla
            ? 'শক্তি, সহনশীলতা ও নিয়মিত অভ্যাস উন্নত করা'
            : 'Improve strength, endurance, and consistency';
      default:
        return isBangla
            ? 'স্থিতিশীল ওজন ও স্বাস্থ্যকর অভ্যাস বজায় রাখা'
            : 'Maintain stable weight and healthy habits';
    }
  }

  String _mealPlan() {
    switch (schedule) {
      case 'regular':
        return isBangla
            ? 'প্রতিদিন কাছাকাছি সময়ে ৩টি প্রধান খাবার এবং প্রয়োজন অনুযায়ী ১টি পরিকল্পিত snack রাখুন।'
            : 'Have 3 main meals at similar times each day, with 1 planned snack when needed.';
      case 'irregular':
        return isBangla
            ? 'দিনের কাজ অনুযায়ী ৩টি flexible meal window ঠিক করুন এবং দীর্ঘ সময় না খেয়ে থাকা এড়িয়ে চলুন।'
            : 'Set 3 flexible meal windows around your day and avoid long gaps without food.';
      default:
        return isBangla
            ? 'কাজের shift অনুযায়ী আগে থেকেই meal window ও বহনযোগ্য খাবার পরিকল্পনা করুন।'
            : 'Plan meal windows and portable foods around your work shifts.';
    }
  }

  String _activityPlan() {
    switch (activity) {
      case 'light':
        return isBangla
            ? 'সপ্তাহে ৩–৪ দিন প্রায় ৩০ মিনিট হাঁটা বা ব্যায়াম করুন এবং ধীরে intensity বাড়ান।'
            : 'Aim for about 30 minutes of activity on 3–4 days a week and increase gradually.';
      case 'moderate':
        return isBangla
            ? 'সপ্তাহে ৪–৫ দিন নিয়মিত activity বজায় রাখুন এবং পর্যাপ্ত recovery দিন রাখুন।'
            : 'Maintain activity on 4–5 days a week with adequate recovery days.';
      case 'high':
        return isBangla
            ? 'বর্তমান activity বজায় রেখে training, nutrition এবং recovery-এর মধ্যে ভারসাম্য রাখুন।'
            : 'Maintain your activity while balancing training, nutrition, and recovery.';
      default:
        return isBangla
            ? 'সপ্তাহে ৩ দিন ২০–৩০ মিনিট হালকা হাঁটা দিয়ে শুরু করুন এবং ধীরে সময় বাড়ান।'
            : 'Start with 20–30 minutes of light walking on 3 days a week and build gradually.';
    }
  }

  String _sleepPlan() {
    switch (sleep) {
      case 'less_than_6':
        return isBangla
            ? 'ঘুমের সময় ধীরে বাড়িয়ে নিয়মিতভাবে ৭–৯ ঘণ্টার দিকে যাওয়ার চেষ্টা করুন।'
            : 'Gradually increase sleep toward a consistent 7–9 hours.';
      case '6_to_7':
        return isBangla
            ? 'নিয়মিত bedtime রেখে সম্ভব হলে ঘুম ৭–৯ ঘণ্টার কাছাকাছি নিন।'
            : 'Keep a regular bedtime and move closer to 7–9 hours when possible.';
      case '7_to_9':
        return isBangla
            ? 'বর্তমান ঘুমের সময় ও নিয়মিত sleep schedule বজায় রাখুন।'
            : 'Maintain your current sleep duration and regular schedule.';
      default:
        return isBangla
            ? 'নিয়মিত sleep schedule রাখুন এবং ঘুমের পর শরীরের সতেজতা পর্যবেক্ষণ করুন।'
            : 'Keep a regular sleep schedule and monitor how refreshed you feel.';
    }
  }

  String _budgetPlan() {
    switch (budget) {
      case 'budget_friendly':
        return isBangla
            ? 'ডাল, ডিম, ছোলা, মৌসুমি সবজি, ভাত ও সহজলভ্য স্থানীয় খাবারকে অগ্রাধিকার দিন।'
            : 'Prioritize lentils, eggs, chickpeas, seasonal vegetables, rice, and accessible local foods.';
      case 'moderate':
        return isBangla
            ? 'স্থানীয় খাবারের সঙ্গে মাছ, মুরগি, দুধ বা দইয়ের মতো protein source পরিকল্পনায় রাখুন।'
            : 'Combine local foods with protein sources such as fish, chicken, milk, or yogurt.';
      default:
        return isBangla
            ? 'বিভিন্ন ধরনের whole food বেছে নিন এবং portion ও খাবারের ভারসাম্য বজায় রাখুন।'
            : 'Choose a variety of whole foods while maintaining balanced portions.';
    }
  }

  String _progressPlan() {
    switch (_goalKind) {
      case 'loss':
        return isBangla
            ? 'একই সময়ে সপ্তাহে ১–২ বার ওজন নথিভুক্ত করুন এবং দৈনিক পরিবর্তনের বদলে কয়েক সপ্তাহের trend দেখুন।'
            : 'Record weight 1–2 times a week under similar conditions and follow the multi-week trend.';
      case 'gain':
        return isBangla
            ? 'সাপ্তাহিক ওজন, শক্তি ও খাবারের ধারাবাহিকতা দেখে ধীরে অগ্রগতি মূল্যায়ন করুন।'
            : 'Review weekly weight, strength, and meal consistency to assess gradual progress.';
      default:
        return isBangla
            ? 'সাপ্তাহিক ওজন, activity, ঘুম এবং habit consistency পর্যালোচনা করুন।'
            : 'Review weight, activity, sleep, and habit consistency each week.';
    }
  }

  void _confirm(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => DashboardNavigationScreen(
          isBangla: isBangla,
          goal: goal,
          targetCaloriesMin: targetCaloriesMin,
          targetCaloriesMax: targetCaloriesMax,
          schedule: schedule,
          activity: activity,
          sleep: sleep,
          budget: budget,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBangla ? 'পরিকল্পনা নিশ্চিত করুন' : 'Confirm your plan'),
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
                      Icons.fact_check_outlined,
                      size: 60,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isBangla
                          ? 'আপনার প্রাথমিক পরিকল্পনা'
                          : 'Your initial plan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${isBangla ? 'লক্ষ্য' : 'Goal'}: ${_goalLabel()}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      size: 42,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBangla
                                ? 'প্রস্তাবিত দৈনিক calorie target'
                                : 'Suggested daily calorie target',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$targetCaloriesMin–$targetCaloriesMax kcal',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PlanItem(
                icon: Icons.flag_outlined,
                title: isBangla ? 'লক্ষ্যের কৌশল' : 'Goal strategy',
                description: _goalStrategy(),
              ),
              const SizedBox(height: 12),
              _PlanItem(
                icon: Icons.restaurant_menu,
                title: isBangla ? 'খাবারের কাঠামো' : 'Meal structure',
                description: _mealPlan(),
              ),
              const SizedBox(height: 12),
              _PlanItem(
                icon: Icons.directions_walk_outlined,
                title: isBangla ? 'শারীরিক সক্রিয়তা' : 'Physical activity',
                description: _activityPlan(),
              ),
              const SizedBox(height: 12),
              _PlanItem(
                icon: Icons.bedtime_outlined,
                title: isBangla ? 'ঘুম ও recovery' : 'Sleep and recovery',
                description: _sleepPlan(),
              ),
              const SizedBox(height: 12),
              _PlanItem(
                icon: Icons.shopping_basket_outlined,
                title: isBangla ? 'বাজেট অনুযায়ী খাবার' : 'Budget-based food',
                description: _budgetPlan(),
              ),
              const SizedBox(height: 12),
              _PlanItem(
                icon: Icons.insights_outlined,
                title: isBangla ? 'সাপ্তাহিক অগ্রগতি' : 'Weekly progress',
                description: _progressPlan(),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isBangla
                            ? 'এটি আপনার দেওয়া তথ্যের ভিত্তিতে তৈরি একটি প্রাথমিক পরিকল্পনা। এটি medical prescription নয় এবং অগ্রগতি অনুযায়ী পরে পরিবর্তন করা যাবে।'
                            : 'This is an initial plan based on your information. It is not a medical prescription and can be adjusted as you progress.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                  onPressed: () => _confirm(context),
                  child: Text(
                    isBangla ? 'পরিকল্পনা নিশ্চিত করুন' : 'Confirm plan',
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

class _PlanItem extends StatelessWidget {
  const _PlanItem({
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(width: 15),
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
