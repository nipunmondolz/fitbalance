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

class DailyLogStorageService {
  DailyLogStorageService._();

  static final DailyLogStorageService instance = DailyLogStorageService._();

  static const String _dailyLogKeyPrefix = 'daily_log_entries_v1_';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<StoredDailyLogEntry>> loadTodayEntries() async {
    final savedJson = await _preferences.getString(_todayKey);

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

  Future<void> saveTodayEntries(List<StoredDailyLogEntry> entries) async {
    if (entries.isEmpty) {
      await _preferences.remove(_todayKey);
      return;
    }

    final encodedEntries = entries
        .map((entry) => entry.toJson())
        .toList(growable: false);

    await _preferences.setString(_todayKey, jsonEncode(encodedEntries));
  }

  String get _todayKey => '$_dailyLogKeyPrefix$_todayDate';

  String get _todayDate {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }
}
