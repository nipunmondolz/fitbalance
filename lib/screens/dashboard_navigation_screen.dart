import 'dart:async';

import 'package:flutter/material.dart';

import '../services/profile_preferences_storage_service.dart';

import 'daily_log_screen.dart';
import 'habit_engine_screen.dart';
import 'learn_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
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
  late String _goal;
  late String _schedule;
  late String _activity;
  late String _sleep;
  late String _budget;

  late final ValueNotifier<int> _todayRefreshNotifier;
  late final ValueNotifier<int> _progressRefreshNotifier;
  late final ValueNotifier<int> _profileRefreshNotifier;

  @override
  void initState() {
    super.initState();

    _goal = widget.goal;
    _schedule = widget.schedule;
    _activity = widget.activity;
    _sleep = widget.sleep;
    _budget = widget.budget;

    _todayRefreshNotifier = ValueNotifier<int>(0);
    _progressRefreshNotifier = ValueNotifier<int>(0);
    _profileRefreshNotifier = ValueNotifier<int>(0);

    unawaited(_loadSavedProfilePreferences());
  }

  StoredProfilePreferences get _currentPreferences {
    return StoredProfilePreferences(
      goal: _goal,
      schedule: _schedule,
      activity: _activity,
      sleep: _sleep,
      budget: _budget,
    );
  }

  Future<void> _loadSavedProfilePreferences() async {
    try {
      final preferences = await ProfilePreferencesStorageService.instance
          .loadPreferences(fallback: _currentPreferences);

      if (!mounted) {
        return;
      }

      setState(() {
        _goal = preferences.goal;
        _schedule = preferences.schedule;
        _activity = preferences.activity;
        _sleep = preferences.sleep;
        _budget = preferences.budget;
      });

      _todayRefreshNotifier.value++;
      _profileRefreshNotifier.value++;
    } catch (_) {
      // Storage read ব্যর্থ হলে assessment থেকে পাওয়া visible values রাখা হবে।
    }
  }

  Future<void> _saveProfilePreferences(
    StoredProfilePreferences preferences,
  ) async {
    await ProfilePreferencesStorageService.instance.savePreferences(
      preferences,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _goal = preferences.goal;
      _schedule = preferences.schedule;
      _activity = preferences.activity;
      _sleep = preferences.sleep;
      _budget = preferences.budget;
    });

    _todayRefreshNotifier.value++;
    _profileRefreshNotifier.value++;
  }

  void _selectPage(int index) {
    if (index == _selectedIndex) {
      if (index == 0) {
        _todayRefreshNotifier.value++;
      } else if (index == 3) {
        _progressRefreshNotifier.value++;
      } else if (index == 5) {
        _profileRefreshNotifier.value++;
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _todayRefreshNotifier.value++;
    } else if (index == 3) {
      _progressRefreshNotifier.value++;
    } else if (index == 5) {
      _profileRefreshNotifier.value++;
    }
  }

  @override
  void dispose() {
    _todayRefreshNotifier.dispose();
    _progressRefreshNotifier.dispose();
    _profileRefreshNotifier.dispose();
    super.dispose();
  }

  List<Widget> _buildPages() {
    final isBangla = widget.isBangla;

    return <Widget>[
      TodayDashboardScreen(
        isBangla: isBangla,
        goal: _goal,
        targetCaloriesMin: widget.targetCaloriesMin,
        targetCaloriesMax: widget.targetCaloriesMax,
        schedule: _schedule,
        activity: _activity,
        sleep: _sleep,
        budget: _budget,
        refreshListenable: _todayRefreshNotifier,
        onOpenLog: () => _selectPage(1),
        onOpenHabits: () => _selectPage(2),
      ),
      DailyLogScreen(
        isBangla: isBangla,
        targetCaloriesMin: widget.targetCaloriesMin,
        targetCaloriesMax: widget.targetCaloriesMax,
      ),
      HabitEngineScreen(isBangla: isBangla),
      ProgressScreen(
        isBangla: isBangla,
        targetCaloriesMin: widget.targetCaloriesMin,
        targetCaloriesMax: widget.targetCaloriesMax,
        refreshListenable: _progressRefreshNotifier,
      ),
      LearnScreen(isBangla: isBangla),
      ProfileScreen(
        isBangla: isBangla,
        goal: _goal,
        schedule: _schedule,
        activity: _activity,
        sleep: _sleep,
        budget: _budget,
        refreshListenable: _profileRefreshNotifier,
        onManageBodyInformation: () => _selectPage(3),
        onSavePreferences: _saveProfilePreferences,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = widget.isBangla;
    final pages = _buildPages();

    return PopScope<void>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _selectedIndex == 0) {
          return;
        }

        setState(() {
          _selectedIndex = 0;
        });
        _todayRefreshNotifier.value++;
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: pages),
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
