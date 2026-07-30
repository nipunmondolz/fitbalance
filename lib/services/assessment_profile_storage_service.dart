import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredAssessmentProfile {
  const StoredAssessmentProfile({
    required this.age,
    required this.gender,
    required this.targetCaloriesMin,
    required this.targetCaloriesMax,
  });

  final int age;
  final String gender;
  final int targetCaloriesMin;
  final int targetCaloriesMax;

  Map<String, Object> toJson() {
    return {
      'age': age,
      'gender': gender,
      'targetCaloriesMin': targetCaloriesMin,
      'targetCaloriesMax': targetCaloriesMax,
    };
  }

  static StoredAssessmentProfile? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final json = Map<String, Object?>.from(value);
    final age = json['age'];
    final gender = json['gender'];
    final targetCaloriesMin = json['targetCaloriesMin'];
    final targetCaloriesMax = json['targetCaloriesMax'];

    if (age is! int ||
        gender is! String ||
        targetCaloriesMin is! int ||
        targetCaloriesMax is! int) {
      return null;
    }

    if (age < 18 ||
        age > 120 ||
        !_allowedGenders.contains(gender) ||
        targetCaloriesMin < 1 ||
        targetCaloriesMin > 12000 ||
        targetCaloriesMax < targetCaloriesMin ||
        targetCaloriesMax > 12000) {
      return null;
    }

    return StoredAssessmentProfile(
      age: age,
      gender: gender,
      targetCaloriesMin: targetCaloriesMin,
      targetCaloriesMax: targetCaloriesMax,
    );
  }

  static const Set<String> _allowedGenders = {
    'male',
    'female',
    'other',
    'prefer_not_to_say',
  };
}

class AssessmentProfileStorageService {
  AssessmentProfileStorageService._();

  static final AssessmentProfileStorageService instance =
      AssessmentProfileStorageService._();

  static const String _assessmentProfileKey = 'assessment_profile_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<StoredAssessmentProfile?> loadProfile() async {
    final savedJson = await _preferences.getString(_assessmentProfileKey);

    if (savedJson == null || savedJson.isEmpty) {
      return null;
    }

    try {
      return StoredAssessmentProfile.fromJson(jsonDecode(savedJson));
    } on FormatException {
      return null;
    }
  }

  Future<void> saveProfile(StoredAssessmentProfile profile) async {
    final validated = StoredAssessmentProfile.fromJson(profile.toJson());

    if (validated == null) {
      throw const FormatException('Invalid assessment profile');
    }

    await _preferences.setString(
      _assessmentProfileKey,
      jsonEncode(validated.toJson()),
    );
  }
}
