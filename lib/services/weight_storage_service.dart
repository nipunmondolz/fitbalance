import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredWeightEntry {
  const StoredWeightEntry({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;

  Map<String, Object> toJson() {
    return {'date': _dateText(date), 'weightKg': weightKg};
  }

  static StoredWeightEntry? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final json = Map<String, Object?>.from(value);
    final dateValue = json['date'];
    final weightValue = json['weightKg'];

    if (dateValue is! String || weightValue is! num) {
      return null;
    }

    final parsedDate = DateTime.tryParse(dateValue);
    final weightKg = weightValue.toDouble();

    if (parsedDate == null ||
        !weightKg.isFinite ||
        weightKg < 20 ||
        weightKg > 400) {
      return null;
    }

    return StoredWeightEntry(
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      weightKg: weightKg,
    );
  }

  static String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class WeightStorageService {
  WeightStorageService._();

  static final WeightStorageService instance = WeightStorageService._();

  static const String _weightEntriesKey = 'weight_entries_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<StoredWeightEntry>> loadEntries() async {
    final savedJson = await _preferences.getString(_weightEntriesKey);

    if (savedJson == null || savedJson.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(savedJson);

      if (decoded is! List) {
        return const [];
      }

      final entries = decoded
          .map(StoredWeightEntry.fromJson)
          .whereType<StoredWeightEntry>()
          .toList();

      entries.sort((first, second) => first.date.compareTo(second.date));
      return List<StoredWeightEntry>.unmodifiable(entries);
    } on FormatException {
      return const [];
    }
  }

  Future<List<StoredWeightEntry>> saveWeightForDate({
    required DateTime date,
    required double weightKg,
  }) {
    return saveWeightEntry(date: date, weightKg: weightKg);
  }

  Future<List<StoredWeightEntry>> saveWeightEntry({
    required DateTime date,
    required double weightKg,
    DateTime? replacingDate,
  }) async {
    if (!weightKg.isFinite || weightKg < 20 || weightKg > 400) {
      throw const FormatException('Invalid weight value');
    }

    final normalizedDate = _normalizeDate(date);
    final entries = List<StoredWeightEntry>.of(await loadEntries());

    if (replacingDate != null) {
      final normalizedReplacingDate = _normalizeDate(replacingDate);

      entries.removeWhere(
        (entry) => _isSameDate(entry.date, normalizedReplacingDate),
      );
    }

    final existingIndex = entries.indexWhere(
      (entry) => _isSameDate(entry.date, normalizedDate),
    );
    final updatedEntry = StoredWeightEntry(
      date: normalizedDate,
      weightKg: weightKg,
    );

    if (existingIndex >= 0) {
      entries[existingIndex] = updatedEntry;
    } else {
      entries.add(updatedEntry);
    }

    return _saveEntries(entries);
  }

  Future<List<StoredWeightEntry>> deleteWeightForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final entries = List<StoredWeightEntry>.of(await loadEntries())
      ..removeWhere((entry) => _isSameDate(entry.date, normalizedDate));

    return _saveEntries(entries);
  }

  Future<List<StoredWeightEntry>> _saveEntries(
    List<StoredWeightEntry> entries,
  ) async {
    entries.sort((first, second) => first.date.compareTo(second.date));

    if (entries.isEmpty) {
      await _preferences.remove(_weightEntriesKey);
      return const [];
    }

    await _preferences.setString(
      _weightEntriesKey,
      jsonEncode(
        entries.map((entry) => entry.toJson()).toList(growable: false),
      ),
    );

    return List<StoredWeightEntry>.unmodifiable(entries);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
