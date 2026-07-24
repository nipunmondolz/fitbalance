import 'package:flutter/material.dart';

import 'daily_log_screen.dart';
import 'habit_engine_screen.dart';
import 'today_dashboard_screen.dart';

class DashboardNavigationScreen extends StatefulWidget {
  const DashboardNavigationScreen({
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

  @override
  State<DashboardNavigationScreen> createState() =>
      _DashboardNavigationScreenState();
}

class _DashboardNavigationScreenState extends State<DashboardNavigationScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    final isBangla = widget.isBangla;

    _pages = <Widget>[
      TodayDashboardScreen(
        isBangla: isBangla,
        goal: widget.goal,
        targetCaloriesMin: widget.targetCaloriesMin,
        targetCaloriesMax: widget.targetCaloriesMax,
        schedule: widget.schedule,
        activity: widget.activity,
        sleep: widget.sleep,
        budget: widget.budget,
      ),
      DailyLogScreen(
        isBangla: isBangla,
        targetCaloriesMin: widget.targetCaloriesMin,
        targetCaloriesMax: widget.targetCaloriesMax,
      ),
      HabitEngineScreen(
  isBangla: isBangla,
),
      _DashboardPlaceholderScreen(
        icon: Icons.bar_chart,
        title: isBangla ? 'অগ্রগতি' : 'Progress',
        description: isBangla
            ? 'ওজন, calorie, activity এবং habit-এর পরিবর্তন chart-এর মাধ্যমে দেখা যাবে।'
            : 'Changes in weight, calories, activity, and habits will appear in charts.',
        isBangla: isBangla,
      ),
      _DashboardPlaceholderScreen(
        icon: Icons.menu_book_outlined,
        title: isBangla ? 'শিখুন' : 'Learn',
        description: isBangla
            ? 'স্বাস্থ্যকর খাবার, ব্যায়াম, ঘুম ও lifestyle সম্পর্কিত নির্ভরযোগ্য তথ্য এখানে থাকবে।'
            : 'Reliable guidance about food, exercise, sleep, and lifestyle will appear here.',
        isBangla: isBangla,
      ),
      _DashboardPlaceholderScreen(
        icon: Icons.person_outline,
        title: isBangla ? 'প্রোফাইল' : 'Profile',
        description: isBangla
            ? 'ব্যক্তিগত তথ্য, health goal, language এবং app settings এখান থেকে পরিবর্তন করা যাবে।'
            : 'Personal information, health goals, language, and app settings will be managed here.',
        isBangla: isBangla,
      ),
    ];
  }

  void _selectPage(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = widget.isBangla;

    return PopScope<void>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _selectedIndex == 0) {
          return;
        }

        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectPage,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: isBangla ? 'আজ' : 'Today',
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_circle_outline),
              selectedIcon: const Icon(Icons.add_circle),
              label: isBangla ? 'লগ' : 'Log',
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_note_outlined),
              selectedIcon: const Icon(Icons.event_note),
              label: isBangla ? 'প্ল্যান' : 'Plan',
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart),
              label: isBangla ? 'প্রগতি' : 'Progress',
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: isBangla ? 'শিখুন' : 'Learn',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: isBangla ? 'প্রোফাইল' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPlaceholderScreen extends StatelessWidget {
  const _DashboardPlaceholderScreen({
    required this.icon,
    required this.title,
    required this.description,
    required this.isBangla,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isBangla;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          icon,
                          size: 36,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isBangla ? 'Navigation প্রস্তুত' : 'Navigation ready',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isBangla
                            ? 'এই section-এর মূল feature পরবর্তী development ধাপে তৈরি হবে।'
                            : 'The main features of this section will be built in a later development step.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
