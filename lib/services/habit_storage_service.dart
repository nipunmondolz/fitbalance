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

class StoredHabitReminder {
  const StoredHabitReminder({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;
}

class HabitStorageService {
  HabitStorageService._();

  static final HabitStorageService instance = HabitStorageService._();

  static const String _completionKeyPrefix = 'habit_completion_';
  static const String _checkInKeyPrefix = 'daily_check_in_';
  static const String _reminderSettingsKey = 'habit_reminder_settings_v1';

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

  Future<List<StoredHabitReminder>?> loadHabitReminders(int habitCount) async {
    final savedValues = await _preferences.getStringList(_reminderSettingsKey);

    if (savedValues == null || savedValues.length != habitCount) {
      return null;
    }

    final reminders = <StoredHabitReminder>[];

    for (final savedValue in savedValues) {
      final parts = savedValue.split('|');

      if (parts.length != 3) {
        return null;
      }

      final bool enabled;

      if (parts[0] == '1') {
        enabled = true;
      } else if (parts[0] == '0') {
        enabled = false;
      } else {
        return null;
      }

      final hour = int.tryParse(parts[1]);
      final minute = int.tryParse(parts[2]);

      if (hour == null ||
          hour < 0 ||
          hour > 23 ||
          minute == null ||
          minute < 0 ||
          minute > 59) {
        return null;
      }

      reminders.add(
        StoredHabitReminder(enabled: enabled, hour: hour, minute: minute),
      );
    }

    return List<StoredHabitReminder>.unmodifiable(reminders);
  }

  Future<void> saveHabitReminders(List<StoredHabitReminder> reminders) {
    final values = reminders
        .map(
          (reminder) =>
              '${reminder.enabled ? 1 : 0}|'
              '${reminder.hour}|'
              '${reminder.minute}',
        )
        .toList(growable: false);

    return _preferences.setStringList(_reminderSettingsKey, values);
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
