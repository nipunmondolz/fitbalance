import 'package:shared_preferences/shared_preferences.dart';

class StoredDailyCheckIn {
  const StoredDailyCheckIn({
    required this.moodIndex,
    required this.energyLevel,
    required this.note,
  });

  final int moodIndex;
  final int energyLevel;
  final String note;
}

class HabitStorageService {
  HabitStorageService._();

  static final HabitStorageService instance = HabitStorageService._();

  static const String _completionKeyPrefix = 'habit_completion_';
  static const String _checkInKeyPrefix = 'daily_check_in_';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<bool>> loadTodayCompletions(int habitCount) async {
    final savedValues = await _preferences.getStringList(_todayKey);

    if (savedValues == null || savedValues.length != habitCount) {
      return List<bool>.filled(habitCount, false);
    }

    return List<bool>.generate(
      habitCount,
      (index) => savedValues[index] == '1',
      growable: false,
    );
  }

  Future<void> saveTodayCompletions(List<bool> completions) {
    final values = completions
        .map((isCompleted) => isCompleted ? '1' : '0')
        .toList(growable: false);

    return _preferences.setStringList(_todayKey, values);
  }

  Future<StoredDailyCheckIn?> loadTodayCheckIn() async {
    final savedValues = await _preferences.getStringList(_todayCheckInKey);

    if (savedValues == null || savedValues.length != 3) {
      return null;
    }

    final moodIndex = int.tryParse(savedValues[0]);
    final energyLevel = int.tryParse(savedValues[1]);

    if (moodIndex == null ||
        moodIndex < 0 ||
        moodIndex > 3 ||
        energyLevel == null ||
        energyLevel < 1 ||
        energyLevel > 5) {
      return null;
    }

    return StoredDailyCheckIn(
      moodIndex: moodIndex,
      energyLevel: energyLevel,
      note: savedValues[2],
    );
  }

  Future<void> saveTodayCheckIn({
    required int moodIndex,
    required int energyLevel,
    required String note,
  }) {
    return _preferences.setStringList(_todayCheckInKey, [
      moodIndex.toString(),
      energyLevel.toString(),
      note,
    ]);
  }

  String get _todayKey => '$_completionKeyPrefix$_todayDate';

  String get _todayCheckInKey => '$_checkInKeyPrefix$_todayDate';

  String get _todayDate {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }
}
