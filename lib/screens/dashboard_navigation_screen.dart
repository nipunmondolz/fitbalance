import 'dart:async';

import 'package:flutter/material.dart';

import '../services/assessment_profile_storage_service.dart';
import '../services/body_metrics_storage_service.dart';
import '../services/calorie_target_calculator.dart';
import '../services/onboarding_storage_service.dart';
import '../services/profile_preferences_storage_service.dart';
import '../services/weight_storage_service.dart';

import 'daily_log_screen.dart';
import 'habit_engine_screen.dart';
import 'learn_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'reassessment_screen.dart';
import 'today_dashboard_screen.dart';
import 'welcome_screen.dart';

class DashboardNavigationScreen extends StatefulWidget {
  const DashboardNavigationScreen({
    required this.isBangla,
    required this.age,
    required this.gender,
    required this.heightInCm,
    required this.weightInKg,
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
  final int age;
  final String gender;
  final double heightInCm;
  final double weightInKg;
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

  late bool _isBangla;
  late int _age;
  late String _gender;
  late int _targetCaloriesMin;
  late int _targetCaloriesMax;
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

    _isBangla = widget.isBangla;
    _age = widget.age;
    _gender = widget.gender;
    _targetCaloriesMin = widget.targetCaloriesMin;
    _targetCaloriesMax = widget.targetCaloriesMax;
    _goal = widget.goal;
    _schedule = widget.schedule;
    _activity = widget.activity;
    _sleep = widget.sleep;
    _budget = widget.budget;

    _todayRefreshNotifier = ValueNotifier<int>(0);
    _progressRefreshNotifier = ValueNotifier<int>(0);
    _profileRefreshNotifier = ValueNotifier<int>(0);

    unawaited(_initialiseSavedDashboardData());
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

  Future<void> _saveOnboardingSnapshot({
    bool? isBangla,
    int? age,
    String? gender,
    double? heightInCm,
    double? weightInKg,
    String? goal,
    int? targetCaloriesMin,
    int? targetCaloriesMax,
    String? schedule,
    String? activity,
    String? sleep,
    String? budget,
  }) async {
    final resolvedHeight =
        heightInCm ?? await BodyMetricsStorageService.instance.loadHeightCm();
    final weightEntries = weightInKg == null
        ? await WeightStorageService.instance.loadEntries()
        : const <StoredWeightEntry>[];
    final resolvedWeight =
        weightInKg ??
        (weightEntries.isEmpty
            ? widget.weightInKg
            : weightEntries.last.weightKg);

    await OnboardingStorageService.instance.saveSession(
      StoredOnboardingSession(
        isBangla: isBangla ?? _isBangla,
        age: age ?? _age,
        gender: gender ?? _gender,
        heightInCm: resolvedHeight ?? widget.heightInCm,
        weightInKg: resolvedWeight,
        goal: goal ?? _goal,
        targetCaloriesMin: targetCaloriesMin ?? _targetCaloriesMin,
        targetCaloriesMax: targetCaloriesMax ?? _targetCaloriesMax,
        schedule: schedule ?? _schedule,
        activity: activity ?? _activity,
        sleep: sleep ?? _sleep,
        budget: budget ?? _budget,
      ),
    );
  }

  Future<void> _initialiseSavedDashboardData() async {
    try {
      final preferencesFuture = ProfilePreferencesStorageService.instance
          .loadPreferences(fallback: _currentPreferences);
      final assessmentFuture = AssessmentProfileStorageService.instance
          .loadProfile();
      final heightFuture = BodyMetricsStorageService.instance.loadHeightCm();
      final weightEntriesFuture = WeightStorageService.instance.loadEntries();

      final preferences = await preferencesFuture;
      final savedAssessment = await assessmentFuture;
      final savedHeight = await heightFuture;
      final weightEntries = await weightEntriesFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _goal = preferences.goal;
        _schedule = preferences.schedule;
        _activity = preferences.activity;
        _sleep = preferences.sleep;
        _budget = preferences.budget;

        if (savedAssessment != null) {
          _age = savedAssessment.age;
          _gender = savedAssessment.gender;
          _targetCaloriesMin = savedAssessment.targetCaloriesMin;
          _targetCaloriesMax = savedAssessment.targetCaloriesMax;
        }
      });

      if (savedAssessment == null) {
        await AssessmentProfileStorageService.instance.saveProfile(
          StoredAssessmentProfile(
            age: _age,
            gender: _gender,
            targetCaloriesMin: _targetCaloriesMin,
            targetCaloriesMax: _targetCaloriesMax,
          ),
        );

        if (savedHeight == null) {
          await BodyMetricsStorageService.instance.saveHeightCm(
            widget.heightInCm,
          );
        }

        if (weightEntries.isEmpty) {
          await WeightStorageService.instance.saveWeightForDate(
            date: DateTime.now(),
            weightKg: widget.weightInKg,
          );
        }
      }

      await _saveOnboardingSnapshot(
        heightInCm: savedHeight ?? widget.heightInCm,
        weightInKg: weightEntries.isEmpty
            ? widget.weightInKg
            : weightEntries.last.weightKg,
      );

      if (!mounted) {
        return;
      }

      _todayRefreshNotifier.value++;
      _progressRefreshNotifier.value++;
      _profileRefreshNotifier.value++;
    } catch (_) {
      // Storage initialization ব্যর্থ হলে constructor-এর visible data রাখা হবে।
    }
  }

  Future<void> _saveLanguage(bool isBangla) async {
    if (isBangla == _isBangla) {
      return;
    }

    await _saveOnboardingSnapshot(isBangla: isBangla);

    if (!mounted) {
      return;
    }

    setState(() {
      _isBangla = isBangla;
    });
  }

  Future<void> _saveProfilePreferences(
    StoredProfilePreferences preferences,
  ) async {
    await ProfilePreferencesStorageService.instance.savePreferences(
      preferences,
    );
    await _saveOnboardingSnapshot(
      goal: preferences.goal,
      schedule: preferences.schedule,
      activity: preferences.activity,
      sleep: preferences.sleep,
      budget: preferences.budget,
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

  Future<void> _saveReassessment(CalorieAssessmentResult result) async {
    final updatedPreferences = StoredProfilePreferences(
      goal: result.goal,
      schedule: _schedule,
      activity: result.activity,
      sleep: _sleep,
      budget: _budget,
    );

    await Future.wait<void>([
      AssessmentProfileStorageService.instance.saveProfile(
        StoredAssessmentProfile(
          age: result.age,
          gender: result.gender,
          targetCaloriesMin: result.targetCaloriesMin,
          targetCaloriesMax: result.targetCaloriesMax,
        ),
      ),
      BodyMetricsStorageService.instance.saveHeightCm(result.heightCm),
      WeightStorageService.instance
          .saveWeightForDate(date: DateTime.now(), weightKg: result.weightKg)
          .then<void>((_) {}),
      ProfilePreferencesStorageService.instance.savePreferences(
        updatedPreferences,
      ),
      _saveOnboardingSnapshot(
        age: result.age,
        gender: result.gender,
        heightInCm: result.heightCm,
        weightInKg: result.weightKg,
        goal: result.goal,
        targetCaloriesMin: result.targetCaloriesMin,
        targetCaloriesMax: result.targetCaloriesMax,
        activity: result.activity,
      ),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _age = result.age;
      _gender = result.gender;
      _targetCaloriesMin = result.targetCaloriesMin;
      _targetCaloriesMax = result.targetCaloriesMax;
      _goal = result.goal;
      _activity = result.activity;
    });

    _todayRefreshNotifier.value++;
    _progressRefreshNotifier.value++;
    _profileRefreshNotifier.value++;
  }

  Future<void> _openReassessment() async {
    try {
      final heightFuture = BodyMetricsStorageService.instance.loadHeightCm();
      final weightEntriesFuture = WeightStorageService.instance.loadEntries();

      final savedHeight = await heightFuture;
      final weightEntries = await weightEntriesFuture;

      if (!mounted) {
        return;
      }

      final latestWeight = weightEntries.isEmpty
          ? widget.weightInKg
          : weightEntries.last.weightKg;

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) {
            return ReassessmentScreen(
              isBangla: _isBangla,
              initialAge: _age,
              initialGender: _gender,
              initialHeightCm: savedHeight ?? widget.heightInCm,
              initialWeightKg: latestWeight,
              initialGoal: _goal,
              initialActivity: _activity,
              currentTargetCaloriesMin: _targetCaloriesMin,
              currentTargetCaloriesMax: _targetCaloriesMax,
              onSave: _saveReassessment,
            );
          },
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
              _isBangla
                  ? 'পুনর্মূল্যায়নের তথ্য খোলা যায়নি। আবার চেষ্টা করুন।'
                  : 'The reassessment data could not be opened. Please try again.',
            ),
          ),
        );
    }
  }

  Future<void> _openFullAssessment() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return WelcomeScreen(initialIsBangla: _isBangla);
        },
      ),
    );
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
    final isBangla = _isBangla;

    return <Widget>[
      TodayDashboardScreen(
        isBangla: isBangla,
        goal: _goal,
        targetCaloriesMin: _targetCaloriesMin,
        targetCaloriesMax: _targetCaloriesMax,
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
        targetCaloriesMin: _targetCaloriesMin,
        targetCaloriesMax: _targetCaloriesMax,
      ),
      HabitEngineScreen(isBangla: isBangla),
      ProgressScreen(
        isBangla: isBangla,
        targetCaloriesMin: _targetCaloriesMin,
        targetCaloriesMax: _targetCaloriesMax,
        refreshListenable: _progressRefreshNotifier,
      ),
      LearnScreen(isBangla: isBangla),
      ProfileScreen(
        isBangla: isBangla,
        age: _age,
        gender: _gender,
        targetCaloriesMin: _targetCaloriesMin,
        targetCaloriesMax: _targetCaloriesMax,
        goal: _goal,
        schedule: _schedule,
        activity: _activity,
        sleep: _sleep,
        budget: _budget,
        refreshListenable: _profileRefreshNotifier,
        onManageBodyInformation: () => _selectPage(3),
        onOpenReassessment: () => unawaited(_openReassessment()),
        onRestartAssessment: () => unawaited(_openFullAssessment()),
        onChangeLanguage: _saveLanguage,
        onSavePreferences: _saveProfilePreferences,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = _isBangla;
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
