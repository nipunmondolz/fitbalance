import 'package:flutter/material.dart';

import '../services/assessment_profile_storage_service.dart';
import '../services/body_metrics_storage_service.dart';
import '../services/onboarding_storage_service.dart';
import '../services/profile_preferences_storage_service.dart';
import '../services/weight_storage_service.dart';

import 'dashboard_navigation_screen.dart';
import 'welcome_screen.dart';

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  late final Future<StoredOnboardingSession?> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _loadStartupSession();
  }

  Future<StoredOnboardingSession?> _loadStartupSession() async {
    final savedSession = await OnboardingStorageService.instance.loadSession();

    if (savedSession != null) {
      return savedSession;
    }

    return _migrateExistingProfile();
  }

  Future<StoredOnboardingSession?> _migrateExistingProfile() async {
    try {
      final assessmentFuture = AssessmentProfileStorageService.instance
          .loadProfile();
      final preferencesFuture = ProfilePreferencesStorageService.instance
          .loadSavedPreferences();
      final heightFuture = BodyMetricsStorageService.instance.loadHeightCm();
      final weightEntriesFuture = WeightStorageService.instance.loadEntries();

      final assessment = await assessmentFuture;
      final preferences = await preferencesFuture;
      final heightInCm = await heightFuture;
      final weightEntries = await weightEntriesFuture;

      if (assessment == null ||
          preferences == null ||
          heightInCm == null ||
          weightEntries.isEmpty) {
        return null;
      }

      final migratedSession = StoredOnboardingSession(
        // পুরোনো version language save করত না। Welcome screen-এর default
        // অনুযায়ী existing profile migration-এ বাংলা রাখা হচ্ছে।
        isBangla: true,
        age: assessment.age,
        gender: assessment.gender,
        heightInCm: heightInCm,
        weightInKg: weightEntries.last.weightKg,
        goal: preferences.goal,
        targetCaloriesMin: assessment.targetCaloriesMin,
        targetCaloriesMax: assessment.targetCaloriesMax,
        schedule: preferences.schedule,
        activity: preferences.activity,
        sleep: preferences.sleep,
        budget: preferences.budget,
      );

      await OnboardingStorageService.instance.saveSession(migratedSession);
      return migratedSession;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoredOnboardingSession?>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupLoadingView();
        }

        final session = snapshot.data;

        if (session == null) {
          return const WelcomeScreen();
        }

        return DashboardNavigationScreen(
          isBangla: session.isBangla,
          age: session.age,
          gender: session.gender,
          heightInCm: session.heightInCm,
          weightInKg: session.weightInKg,
          goal: session.goal,
          targetCaloriesMin: session.targetCaloriesMin,
          targetCaloriesMax: session.targetCaloriesMax,
          schedule: session.schedule,
          activity: session.activity,
          sleep: session.sleep,
          budget: session.budget,
        );
      },
    );
  }
}

class _StartupLoadingView extends StatelessWidget {
  const _StartupLoadingView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    size: 42,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'FitBalance',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 12),
                Text(
                  'তথ্য প্রস্তুত হচ্ছে…',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
