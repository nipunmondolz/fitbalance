import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredDailyLogEntry {
  const StoredDailyLogEntry({
    required this.typeIndex,
    required this.title,
    required this.amount,
    required this.details,
  });

  final int typeIndex;
  final String title;
  final double amount;
  final String details;

  Map<String, Object> toJson() {
    return {
      'typeIndex': typeIndex,
      'title': title,
      'amount': amount,
      'details': details,
    };
  }

  static StoredDailyLogEntry? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final json = Map<String, Object?>.from(value);
    final typeIndex = json['typeIndex'];
    final title = json['title'];
    final amount = json['amount'];
    final details = json['details'];

    if (typeIndex is! int ||
        title is! String ||
        amount is! num ||
        details is! String) {
      return null;
    }

    return StoredDailyLogEntry(
      typeIndex: typeIndex,
      title: title,
      amount: amount.toDouble(),
      details: details,
    );
  }
}

class DailyLogSummary {
  const DailyLogSummary({
    required this.calories,
    required this.waterGlasses,
    required this.softDrinkMl,
    required this.exerciseMinutes,
    required this.sleepHours,
  });

  static const DailyLogSummary empty = DailyLogSummary(
    calories: 0,
    waterGlasses: 0,
    softDrinkMl: 0,
    exerciseMinutes: 0,
    sleepHours: 0,
  );

  final int calories;
  final int waterGlasses;
  final int softDrinkMl;
  final int exerciseMinutes;
  final double sleepHours;
}

class DailyLogStorageService {
  DailyLogStorageService._();

  static final DailyLogStorageService instance = DailyLogStorageService._();

  static const String _dailyLogKeyPrefix = 'daily_log_entries_v1_';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<StoredDailyLogEntry>> loadTodayEntries() {
    return loadEntriesForDate(DateTime.now());
  }

  Future<List<StoredDailyLogEntry>> loadEntriesForDate(DateTime date) async {
    final savedJson = await _preferences.getString(_keyForDate(date));

    if (savedJson == null || savedJson.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(savedJson);

      if (decoded is! List) {
        return const [];
      }

      return decoded
          .map(StoredDailyLogEntry.fromJson)
          .whereType<StoredDailyLogEntry>()
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<DailyLogSummary> loadTodaySummary() {
    return loadSummaryForDate(DateTime.now());
  }

  Future<DailyLogSummary> loadSummaryForDate(DateTime date) async {
    final entries = await loadEntriesForDate(date);

    var calories = 0;
    var waterGlasses = 0;
    var softDrinkMl = 0;
    var exerciseMinutes = 0;
    var sleepHours = 0.0;

    for (final entry in entries) {
      switch (entry.typeIndex) {
        case 0:
          calories += entry.amount.round();
          break;
        case 1:
          waterGlasses += entry.amount.round();
          break;
        case 2:
          softDrinkMl += entry.amount.round();
          break;
        case 3:
          exerciseMinutes += entry.amount.round();
          break;
        case 4:
          sleepHours += entry.amount;
          break;
      }
    }

    return DailyLogSummary(
      calories: calories,
      waterGlasses: waterGlasses,
      softDrinkMl: softDrinkMl,
      exerciseMinutes: exerciseMinutes,
      sleepHours: sleepHours,
    );
  }

  Future<void> saveTodayEntries(List<StoredDailyLogEntry> entries) async {
    final todayKey = _keyForDate(DateTime.now());

    if (entries.isEmpty) {
      await _preferences.remove(todayKey);
      return;
    }

    final encodedEntries = entries
        .map((entry) => entry.toJson())
        .toList(growable: false);

    await _preferences.setString(todayKey, jsonEncode(encodedEntries));
  }

  String _keyForDate(DateTime date) {
    return '$_dailyLogKeyPrefix${_dateText(date)}';
  }

  String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
