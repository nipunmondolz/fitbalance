import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredOnboardingSession {
  const StoredOnboardingSession({
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

  Map<String, Object> toJson() {
    return {
      'isBangla': isBangla,
      'age': age,
      'gender': gender,
      'heightInCm': heightInCm,
      'weightInKg': weightInKg,
      'goal': goal,
      'targetCaloriesMin': targetCaloriesMin,
      'targetCaloriesMax': targetCaloriesMax,
      'schedule': schedule,
      'activity': activity,
      'sleep': sleep,
      'budget': budget,
    };
  }

  static StoredOnboardingSession? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final json = Map<String, Object?>.from(value);
    final isBangla = json['isBangla'];
    final age = json['age'];
    final gender = json['gender'];
    final height = json['heightInCm'];
    final weight = json['weightInKg'];
    final goal = json['goal'];
    final targetCaloriesMin = json['targetCaloriesMin'];
    final targetCaloriesMax = json['targetCaloriesMax'];
    final schedule = json['schedule'];
    final activity = json['activity'];
    final sleep = json['sleep'];
    final budget = json['budget'];

    if (isBangla is! bool ||
        age is! int ||
        gender is! String ||
        height is! num ||
        weight is! num ||
        goal is! String ||
        targetCaloriesMin is! int ||
        targetCaloriesMax is! int ||
        schedule is! String ||
        activity is! String ||
        sleep is! String ||
        budget is! String) {
      return null;
    }

    final heightInCm = height.toDouble();
    final weightInKg = weight.toDouble();
    final normalisedSchedule = _normaliseSchedule(schedule);

    if (age < 18 ||
        age > 120 ||
        !_allowedGenders.contains(gender) ||
        !heightInCm.isFinite ||
        heightInCm < 100 ||
        heightInCm > 250 ||
        !weightInKg.isFinite ||
        weightInKg < 20 ||
        weightInKg > 400 ||
        !_allowedGoals.contains(goal) ||
        targetCaloriesMin < 1 ||
        targetCaloriesMin > 12000 ||
        targetCaloriesMax < targetCaloriesMin ||
        targetCaloriesMax > 12000 ||
        !_allowedSchedules.contains(normalisedSchedule) ||
        !_allowedActivities.contains(activity) ||
        !_allowedSleepValues.contains(sleep) ||
        !_allowedBudgets.contains(budget)) {
      return null;
    }

    return StoredOnboardingSession(
      isBangla: isBangla,
      age: age,
      gender: gender,
      heightInCm: heightInCm,
      weightInKg: weightInKg,
      goal: goal,
      targetCaloriesMin: targetCaloriesMin,
      targetCaloriesMax: targetCaloriesMax,
      schedule: normalisedSchedule,
      activity: activity,
      sleep: sleep,
      budget: budget,
    );
  }

  static const Set<String> _allowedGenders = {
    'male',
    'female',
    'other',
    'prefer_not_to_say',
  };
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

  static String _normaliseSchedule(String value) {
    return value == 'shift' ? 'shift_based' : value;
  }
}

class OnboardingStorageService {
  OnboardingStorageService._();

  static final OnboardingStorageService instance = OnboardingStorageService._();

  static const String _completionKey = 'onboarding_complete_v1';
  static const String _sessionKey = 'onboarding_session_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<StoredOnboardingSession?> loadSession() async {
    final isComplete = await _preferences.getBool(_completionKey);

    if (isComplete != true) {
      return null;
    }

    final savedJson = await _preferences.getString(_sessionKey);

    if (savedJson == null || savedJson.isEmpty) {
      return null;
    }

    try {
      return StoredOnboardingSession.fromJson(jsonDecode(savedJson));
    } on FormatException {
      return null;
    }
  }

  Future<void> saveSession(StoredOnboardingSession session) async {
    final validated = StoredOnboardingSession.fromJson(session.toJson());

    if (validated == null) {
      throw const FormatException('Invalid onboarding session');
    }

    await _preferences.setString(_sessionKey, jsonEncode(validated.toJson()));
    await _preferences.setBool(_completionKey, true);
  }
}
