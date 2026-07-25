import 'package:shared_preferences/shared_preferences.dart';

class HabitStorageService {
  HabitStorageService._();

  static final HabitStorageService instance = HabitStorageService._();

  static const String _completionKeyPrefix = 'habit_completion_';

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

  String get _todayKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$_completionKeyPrefix${now.year}-$month-$day';
  }
}
