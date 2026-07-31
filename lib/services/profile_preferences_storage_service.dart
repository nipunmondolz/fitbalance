import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredProfilePreferences {
  const StoredProfilePreferences({
    required this.goal,
    required this.schedule,
    required this.activity,
    required this.sleep,
    required this.budget,
  });

  final String goal;
  final String schedule;
  final String activity;
  final String sleep;
  final String budget;

  Map<String, String> toJson() {
    return {
      'goal': goal,
      'schedule': schedule,
      'activity': activity,
      'sleep': sleep,
      'budget': budget,
    };
  }
}

class ProfilePreferencesStorageService {
  ProfilePreferencesStorageService._();

  static final ProfilePreferencesStorageService instance =
      ProfilePreferencesStorageService._();

  static const String _preferencesKey = 'profile_preferences_v1';

  static const Set<String> _allowedGoals = {
    'lose_weight',
    'gain_weight',
    'maintain_weight',
    'improve_fitness',
  };
  static const Set<String> _allowedSchedules = {
    'regular',
    'irregular',
    'shift_based',
  };
  static const Set<String> _allowedActivities = {
    'low',
    'light',
    'moderate',
    'high',
  };
  static const Set<String> _allowedSleepValues = {
    'less_than_6',
    '6_to_7',
    '7_to_9',
    'more_than_9',
  };
  static const Set<String> _allowedBudgets = {
    'budget_friendly',
    'moderate',
    'flexible',
    'premium',
  };

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<StoredProfilePreferences> loadPreferences({
    required StoredProfilePreferences fallback,
  }) async {
    return await loadSavedPreferences() ?? _normalise(fallback);
  }

  Future<StoredProfilePreferences?> loadSavedPreferences() async {
    final savedJson = await _preferences.getString(_preferencesKey);

    if (savedJson == null || savedJson.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(savedJson);

      if (decoded is! Map) {
        return null;
      }

      final values = Map<String, Object?>.from(decoded);
      final goal = values['goal'];
      final schedule = values['schedule'];
      final activity = values['activity'];
      final sleep = values['sleep'];
      final budget = values['budget'];

      if (goal is! String ||
          schedule is! String ||
          activity is! String ||
          sleep is! String ||
          budget is! String) {
        return null;
      }

      final normalised = StoredProfilePreferences(
        goal: _normaliseGoal(goal),
        schedule: _normaliseSchedule(schedule),
        activity: _normaliseActivity(activity),
        sleep: _normaliseSleep(sleep),
        budget: _normaliseBudget(budget),
      );

      if (!_allowedGoals.contains(normalised.goal) ||
          !_allowedSchedules.contains(normalised.schedule) ||
          !_allowedActivities.contains(normalised.activity) ||
          !_allowedSleepValues.contains(normalised.sleep) ||
          !_allowedBudgets.contains(normalised.budget)) {
        return null;
      }

      return normalised;
    } on FormatException {
      return null;
    }
  }

  Future<void> savePreferences(StoredProfilePreferences preferences) async {
    final normalised = _normalise(preferences);

    await _preferences.setString(
      _preferencesKey,
      jsonEncode(normalised.toJson()),
    );
  }

  StoredProfilePreferences _normalise(StoredProfilePreferences preferences) {
    return StoredProfilePreferences(
      goal: _normaliseGoal(preferences.goal),
      schedule: _normaliseSchedule(preferences.schedule),
      activity: _normaliseActivity(preferences.activity),
      sleep: _normaliseSleep(preferences.sleep),
      budget: _normaliseBudget(preferences.budget),
    );
  }

  String _normaliseGoal(String value) {
    final normalised = value.trim().toLowerCase();

    if (normalised.contains('gain') ||
        normalised.contains('বাড়') ||
        normalised.contains('বাড়')) {
      return 'gain_weight';
    }
    if (normalised.contains('loss') ||
        normalised.contains('lose') ||
        normalised.contains('কম')) {
      return 'lose_weight';
    }
    if (normalised.contains('fitness') ||
        normalised.contains('fit') ||
        normalised.contains('ফিট')) {
      return 'improve_fitness';
    }

    return 'maintain_weight';
  }

  String _normaliseSchedule(String value) {
    switch (value.trim().toLowerCase()) {
      case 'regular':
        return 'regular';
      case 'shift':
      case 'shift_based':
        return 'shift_based';
      default:
        return 'irregular';
    }
  }

  String _normaliseActivity(String value) {
    switch (value.trim().toLowerCase()) {
      case 'light':
        return 'light';
      case 'moderate':
      case 'medium':
        return 'moderate';
      case 'high':
        return 'high';
      default:
        return 'low';
    }
  }

  String _normaliseSleep(String value) {
    final normalised = value.trim().toLowerCase();

    return _allowedSleepValues.contains(normalised) ? normalised : '7_to_9';
  }

  String _normaliseBudget(String value) {
    switch (value.trim().toLowerCase()) {
      case 'moderate':
      case 'medium':
        return 'moderate';
      case 'flexible':
        return 'flexible';
      case 'premium':
      case 'high':
        return 'premium';
      default:
        return 'budget_friendly';
    }
  }
}
