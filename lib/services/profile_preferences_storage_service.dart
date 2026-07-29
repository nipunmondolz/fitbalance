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
  static const Set<String> _allowedActivities = {'low', 'moderate', 'high'};
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
    final savedJson = await _preferences.getString(_preferencesKey);

    if (savedJson == null || savedJson.isEmpty) {
      return _normalise(fallback);
    }

    try {
      final decoded = jsonDecode(savedJson);

      if (decoded is! Map) {
        return _normalise(fallback);
      }

      final values = Map<String, Object?>.from(decoded);

      return StoredProfilePreferences(
        goal: _validatedValue(
          values['goal'],
          _allowedGoals,
          _normaliseGoal(fallback.goal),
        ),
        schedule: _validatedValue(
          values['schedule'],
          _allowedSchedules,
          _normaliseSchedule(fallback.schedule),
        ),
        activity: _validatedValue(
          values['activity'],
          _allowedActivities,
          _normaliseActivity(fallback.activity),
        ),
        sleep: _validatedValue(
          values['sleep'],
          _allowedSleepValues,
          _normaliseSleep(fallback.sleep),
        ),
        budget: _validatedValue(
          values['budget'],
          _allowedBudgets,
          _normaliseBudget(fallback.budget),
        ),
      );
    } on FormatException {
      return _normalise(fallback);
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

  String _validatedValue(
    Object? value,
    Set<String> allowedValues,
    String fallback,
  ) {
    if (value is String && allowedValues.contains(value)) {
      return value;
    }

    return fallback;
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
