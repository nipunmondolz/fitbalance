import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/app_settings_storage_service.dart';
import '../services/body_metrics_storage_service.dart';
import '../services/measurement_unit_converter.dart';
import '../services/daily_log_storage_service.dart';
import '../services/habit_storage_service.dart';
import '../services/weight_storage_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    required this.isBangla,
    required this.targetCaloriesMin,
    required this.targetCaloriesMax,
    required this.refreshListenable,
    super.key,
  });

  final bool isBangla;
  final int targetCaloriesMin;
  final int targetCaloriesMax;
  final ValueListenable<int> refreshListenable;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

enum _ProgressChartMetric { calories, water, exercise, sleep, habits }

enum _WeightGoalDirection { loss, gain, maintain }

enum _BmiCategory { underweight, healthy, overweight, obesity }

enum _HeightEntryMode { metric, imperial }

class _ChartBarData {
  const _ChartBarData({
    required this.label,
    required this.value,
    required this.valueText,
  });

  final String label;
  final double value;
  final String valueText;
}

class _WeightEntryResult {
  const _WeightEntryResult({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;
}

class _WeightTrendPoint {
  const _WeightTrendPoint({required this.date, required this.weightKg});

  final DateTime date;
  final double? weightKg;
}

class _ProgressDay {
  const _ProgressDay({
    required this.date,
    required this.dailyLogSummary,
    required this.habitCompletions,
    required this.dailyCheckIn,
  });

  final DateTime date;
  final DailyLogSummary dailyLogSummary;
  final List<bool> habitCompletions;
  final StoredDailyCheckIn? dailyCheckIn;

  int get completedHabitCount =>
      habitCompletions.where((isCompleted) => isCompleted).length;

  bool get hasSavedData =>
      dailyLogSummary.calories > 0 ||
      dailyLogSummary.waterGlasses > 0 ||
      dailyLogSummary.softDrinkMl > 0 ||
      dailyLogSummary.exerciseMinutes > 0 ||
      dailyLogSummary.sleepHours > 0 ||
      completedHabitCount > 0 ||
      dailyCheckIn != null;
}

class _ProgressScreenState extends State<ProgressScreen>
    with WidgetsBindingObserver {
  static const int _habitCount = 3;

  DailyLogSummary _dailyLogSummary = DailyLogSummary.empty;
  List<bool> _habitCompletions = List<bool>.filled(_habitCount, false);
  StoredDailyCheckIn? _dailyCheckIn;
  List<_ProgressDay> _sevenDayProgress = const [];
  List<StoredWeightEntry> _weightEntries = const [];
  double? _targetWeightKg;
  double? _heightCm;
  _ProgressChartMetric _selectedChartMetric = _ProgressChartMetric.calories;

  bool _isLoading = true;
  bool _isSavingWeight = false;
  bool _isSavingTargetWeight = false;
  bool _isSavingHeight = false;
  int _loadGeneration = 0;

  MeasurementUnitMode get _measurementUnit =>
      AppSettingsController.instance.currentMeasurementUnit;

  int get _completedHabitCount =>
      _habitCompletions.where((isCompleted) => isCompleted).length;

  double get _habitProgress => _habitCompletions.isEmpty
      ? 0
      : _completedHabitCount / _habitCompletions.length;

  double get _calorieProgress => widget.targetCaloriesMax <= 0
      ? 0
      : (_dailyLogSummary.calories / widget.targetCaloriesMax)
            .clamp(0.0, 1.0)
            .toDouble();

  StoredWeightEntry? get _latestWeight =>
      _weightEntries.isEmpty ? null : _weightEntries.last;

  StoredWeightEntry? get _startingWeight =>
      _weightEntries.isEmpty ? null : _weightEntries.first;

  StoredWeightEntry? get _todayWeight {
    final now = DateTime.now();

    for (final entry in _weightEntries.reversed) {
      if (_isSameDate(entry.date, now)) {
        return entry;
      }
    }

    return null;
  }

  double? get _totalWeightChange {
    final startingWeight = _startingWeight;
    final latestWeight = _latestWeight;

    if (startingWeight == null || latestWeight == null) {
      return null;
    }

    return latestWeight.weightKg - startingWeight.weightKg;
  }

  _WeightGoalDirection? get _weightGoalDirection {
    final startingWeight = _startingWeight;
    final targetWeightKg = _targetWeightKg;

    if (startingWeight == null || targetWeightKg == null) {
      return null;
    }

    final difference = targetWeightKg - startingWeight.weightKg;

    if (difference.abs() < 0.05) {
      return _WeightGoalDirection.maintain;
    }

    return difference < 0
        ? _WeightGoalDirection.loss
        : _WeightGoalDirection.gain;
  }

  double get _weightGoalProgress {
    final startingWeight = _startingWeight;
    final latestWeight = _latestWeight;
    final targetWeightKg = _targetWeightKg;
    final direction = _weightGoalDirection;

    if (startingWeight == null ||
        latestWeight == null ||
        targetWeightKg == null ||
        direction == null) {
      return 0;
    }

    switch (direction) {
      case _WeightGoalDirection.loss:
        final totalDistance = startingWeight.weightKg - targetWeightKg;
        final completedDistance =
            startingWeight.weightKg - latestWeight.weightKg;

        if (totalDistance <= 0) {
          return 0;
        }

        return (completedDistance / totalDistance).clamp(0.0, 1.0).toDouble();
      case _WeightGoalDirection.gain:
        final totalDistance = targetWeightKg - startingWeight.weightKg;
        final completedDistance =
            latestWeight.weightKg - startingWeight.weightKg;

        if (totalDistance <= 0) {
          return 0;
        }

        return (completedDistance / totalDistance).clamp(0.0, 1.0).toDouble();
      case _WeightGoalDirection.maintain:
        return (latestWeight.weightKg - targetWeightKg).abs() <= 0.5 ? 1 : 0;
    }
  }

  double? get _remainingToTargetKg {
    final latestWeight = _latestWeight;
    final targetWeightKg = _targetWeightKg;
    final direction = _weightGoalDirection;

    if (latestWeight == null || targetWeightKg == null || direction == null) {
      return null;
    }

    switch (direction) {
      case _WeightGoalDirection.loss:
        return math.max(latestWeight.weightKg - targetWeightKg, 0).toDouble();
      case _WeightGoalDirection.gain:
        return math.max(targetWeightKg - latestWeight.weightKg, 0).toDouble();
      case _WeightGoalDirection.maintain:
        return (latestWeight.weightKg - targetWeightKg).abs();
    }
  }

  bool get _hasReachedWeightTarget {
    final remaining = _remainingToTargetKg;

    if (remaining == null) {
      return false;
    }

    return _weightGoalDirection == _WeightGoalDirection.maintain
        ? remaining <= 0.5
        : remaining <= 0.05;
  }

  double? get _bmi {
    final latestWeight = _latestWeight;
    final heightCm = _heightCm;

    if (latestWeight == null || heightCm == null || heightCm <= 0) {
      return null;
    }

    final heightM = heightCm / 100;
    return latestWeight.weightKg / (heightM * heightM);
  }

  _BmiCategory? get _bmiCategory {
    final bmi = _bmi;

    if (bmi == null) {
      return null;
    }

    if (bmi < 18.5) {
      return _BmiCategory.underweight;
    }

    if (bmi < 25) {
      return _BmiCategory.healthy;
    }

    if (bmi < 30) {
      return _BmiCategory.overweight;
    }

    return _BmiCategory.obesity;
  }

  double? get _healthyWeightMinKg {
    final heightCm = _heightCm;

    if (heightCm == null || heightCm <= 0) {
      return null;
    }

    final heightM = heightCm / 100;
    return 18.5 * heightM * heightM;
  }

  double? get _healthyWeightMaxKg {
    final heightCm = _heightCm;

    if (heightCm == null || heightCm <= 0) {
      return null;
    }

    final heightM = heightCm / 100;
    return 24.9 * heightM * heightM;
  }

  List<_WeightTrendPoint> get _weightTrendPoints {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entriesByDate = <int, StoredWeightEntry>{
      for (final entry in _weightEntries) _dateToken(entry.date): entry,
    };

    return List<_WeightTrendPoint>.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return _WeightTrendPoint(
        date: date,
        weightKg: entriesByDate[_dateToken(date)]?.weightKg,
      );
    }, growable: false);
  }

  List<_ProgressDay> get _loggedProgressDays => _sevenDayProgress
      .where((progressDay) => progressDay.hasSavedData)
      .toList(growable: false);

  double _loggedDayAverage(double Function(_ProgressDay progressDay) valueOf) {
    final loggedDays = _loggedProgressDays;

    if (loggedDays.isEmpty) {
      return 0;
    }

    final total = loggedDays.fold<double>(
      0,
      (sum, progressDay) => sum + valueOf(progressDay),
    );

    return total / loggedDays.length;
  }

  double get _averageCalories => _loggedDayAverage(
    (progressDay) => progressDay.dailyLogSummary.calories.toDouble(),
  );

  double get _averageWater => _loggedDayAverage(
    (progressDay) => progressDay.dailyLogSummary.waterGlasses.toDouble(),
  );

  double get _averageExercise => _loggedDayAverage(
    (progressDay) => progressDay.dailyLogSummary.exerciseMinutes.toDouble(),
  );

  double get _averageSleep => _loggedDayAverage(
    (progressDay) => progressDay.dailyLogSummary.sleepHours,
  );

  double get _habitConsistency {
    final loggedDays = _loggedProgressDays;

    if (loggedDays.isEmpty) {
      return 0;
    }

    final completedHabits = loggedDays.fold<int>(
      0,
      (sum, progressDay) => sum + progressDay.completedHabitCount,
    );
    final availableHabits = loggedDays.length * _habitCount;

    return availableHabits == 0 ? 0 : (completedHabits / availableHabits) * 100;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.refreshListenable.addListener(_handleRefreshRequest);
    AppSettingsController.instance.measurementUnitListenable.addListener(
      _handleMeasurementUnitChanged,
    );
    unawaited(_loadProgress());
  }

  @override
  void didUpdateWidget(covariant ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable.removeListener(_handleRefreshRequest);
      widget.refreshListenable.addListener(_handleRefreshRequest);
      unawaited(_loadProgress());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadProgress());
    }
  }

  void _handleRefreshRequest() {
    unawaited(_loadProgress());
  }

  void _handleMeasurementUnitChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<_ProgressDay> _loadProgressDay(DateTime date) async {
    final dailyLogFuture = DailyLogStorageService.instance.loadSummaryForDate(
      date,
    );
    final habitFuture = HabitStorageService.instance.loadCompletionsForDate(
      date,
      _habitCount,
    );
    final checkInFuture = HabitStorageService.instance.loadCheckInForDate(date);

    final dailyLogSummary = await dailyLogFuture;
    final habitCompletions = await habitFuture;
    final dailyCheckIn = await checkInFuture;

    return _ProgressDay(
      date: date,
      dailyLogSummary: dailyLogSummary,
      habitCompletions: habitCompletions,
      dailyCheckIn: dailyCheckIn,
    );
  }

  Future<void> _loadProgress() async {
    final loadGeneration = ++_loadGeneration;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: index)),
      growable: false,
    );

    try {
      final sevenDayProgressFuture = Future.wait(dates.map(_loadProgressDay));
      final weightEntriesFuture = WeightStorageService.instance.loadEntries();
      final targetWeightFuture = WeightStorageService.instance
          .loadTargetWeight();
      final heightFuture = BodyMetricsStorageService.instance.loadHeightCm();

      final sevenDayProgress = await sevenDayProgressFuture;
      final weightEntries = await weightEntriesFuture;
      final targetWeightKg = await targetWeightFuture;
      final heightCm = await heightFuture;

      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }

      final todayProgress = sevenDayProgress.first;

      setState(() {
        _dailyLogSummary = todayProgress.dailyLogSummary;
        _habitCompletions = todayProgress.habitCompletions;
        _dailyCheckIn = todayProgress.dailyCheckIn;
        _sevenDayProgress = sevenDayProgress;
        _weightEntries = weightEntries;
        _targetWeightKg = targetWeightKg;
        _heightCm = heightCm;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  int _dateToken(DateTime date) {
    return (date.year * 10000) + (date.month * 100) + date.day;
  }

  String _signedWeightChange(double change) {
    return MeasurementUnitConverter.formatSignedWeight(
      change,
      _measurementUnit,
    );
  }

  String _formatWeight(double weightKg) {
    return MeasurementUnitConverter.formatWeight(weightKg, _measurementUnit);
  }

  String _weightDateLabel(DateTime date) {
    final now = DateTime.now();

    if (_isSameDate(date, now)) {
      return widget.isBangla ? 'আজ' : 'Today';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _showTodayWeightEntrySheet() {
    return _showWeightEditor(
      initialDate: DateTime.now(),
      initialWeight: _todayWeight?.weightKg ?? _latestWeight?.weightKg,
      isEditing: _todayWeight != null,
      allowDateSelection: false,
      replacingDate: _todayWeight?.date,
    );
  }

  Future<void> _showPastWeightEntrySheet() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    return _showWeightEditor(
      initialDate: yesterday,
      initialWeight: _latestWeight?.weightKg,
      isEditing: false,
      allowDateSelection: true,
    );
  }

  Future<void> _editWeightEntry(StoredWeightEntry entry) {
    return _showWeightEditor(
      initialDate: entry.date,
      initialWeight: entry.weightKg,
      isEditing: true,
      allowDateSelection: true,
      replacingDate: entry.date,
    );
  }

  Future<void> _showWeightEditor({
    required DateTime initialDate,
    required double? initialWeight,
    required bool isEditing,
    required bool allowDateSelection,
    DateTime? replacingDate,
  }) async {
    final result = await showModalBottomSheet<_WeightEntryResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _WeightEntrySheet(
          isBangla: widget.isBangla,
          initialDate: initialDate,
          initialWeight: initialWeight,
          isEditing: isEditing,
          allowDateSelection: allowDateSelection,
          measurementUnit: _measurementUnit,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _isSavingWeight = true;
    });

    try {
      final updatedEntries = await WeightStorageService.instance
          .saveWeightEntry(
            date: result.date,
            weightKg: result.weightKg,
            replacingDate: replacingDate,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _weightEntries = updatedEntries;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'ওজন সংরক্ষণ হয়েছে।'
                  : 'The weight has been saved.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'ওজন সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'
                  : 'The weight could not be saved. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingWeight = false;
        });
      }
    }
  }

  Future<void> _deleteWeightEntry(StoredWeightEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            widget.isBangla ? 'ওজনের এন্ট্রি মুছবেন?' : 'Delete weight entry?',
          ),
          content: Text(
            widget.isBangla
                ? '${_weightDateLabel(entry.date)} তারিখের ${_formatWeight(entry.weightKg)} ওজনটি মুছে যাবে।'
                : '${_formatWeight(entry.weightKg)} saved on ${_weightDateLabel(entry.date)} will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(widget.isBangla ? 'বাতিল' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(widget.isBangla ? 'মুছুন' : 'Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isSavingWeight = true;
    });

    try {
      final updatedEntries = await WeightStorageService.instance
          .deleteWeightForDate(entry.date);

      if (!mounted) {
        return;
      }

      setState(() {
        _weightEntries = updatedEntries;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'ওজনের এন্ট্রি মুছে ফেলা হয়েছে।'
                  : 'The weight entry has been deleted.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'ওজনের এন্ট্রি মুছতে সমস্যা হয়েছে।'
                  : 'The weight entry could not be deleted.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingWeight = false;
        });
      }
    }
  }

  Future<void> _showTargetWeightSheet() async {
    final targetWeightKg = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _TargetWeightEntrySheet(
          isBangla: widget.isBangla,
          initialTargetWeight: _targetWeightKg,
          measurementUnit: _measurementUnit,
        );
      },
    );

    if (targetWeightKg == null || !mounted) {
      return;
    }

    setState(() {
      _isSavingTargetWeight = true;
    });

    try {
      await WeightStorageService.instance.saveTargetWeight(targetWeightKg);

      if (!mounted) {
        return;
      }

      setState(() {
        _targetWeightKg = targetWeightKg;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'লক্ষ্য ওজন সংরক্ষণ হয়েছে।'
                  : 'The target weight has been saved.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'লক্ষ্য ওজন সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'
                  : 'The target weight could not be saved. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTargetWeight = false;
        });
      }
    }
  }

  Future<void> _showHeightEntrySheet() async {
    final heightCm = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _HeightEntrySheet(
          isBangla: widget.isBangla,
          initialHeightCm: _heightCm,
          measurementUnit: _measurementUnit,
        );
      },
    );

    if (heightCm == null || !mounted) {
      return;
    }

    setState(() {
      _isSavingHeight = true;
    });

    try {
      await BodyMetricsStorageService.instance.saveHeightCm(heightCm);

      if (!mounted) {
        return;
      }

      setState(() {
        _heightCm = heightCm;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'উচ্চতা সংরক্ষণ হয়েছে।'
                  : 'The height has been saved.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'উচ্চতা সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'
                  : 'The height could not be saved. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingHeight = false;
        });
      }
    }
  }

  String _moodName(int moodIndex) {
    switch (moodIndex) {
      case 0:
        return widget.isBangla ? 'কঠিন দিন' : 'Difficult';
      case 1:
        return widget.isBangla ? 'মোটামুটি' : 'Okay';
      case 2:
        return widget.isBangla ? 'ভালো' : 'Good';
      case 3:
        return widget.isBangla ? 'দারুণ' : 'Great';
      default:
        return widget.isBangla ? 'অজানা' : 'Unknown';
    }
  }

  String get _checkInText {
    final checkIn = _dailyCheckIn;

    if (checkIn == null) {
      return widget.isBangla
          ? 'আজ এখনো দৈনিক চেক-ইন করা হয়নি।'
          : 'No daily check-in has been saved yet.';
    }

    return widget.isBangla
        ? 'মুড: ${_moodName(checkIn.moodIndex)} • শক্তি: ${checkIn.energyLevel}/৫'
        : 'Mood: ${_moodName(checkIn.moodIndex)} • Energy: ${checkIn.energyLevel}/5';
  }

  String _dateLabel(DateTime date, int index) {
    const monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const monthsBn = [
      'জানু',
      'ফেব',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টে',
      'অক্টো',
      'নভে',
      'ডিসে',
    ];

    final relativeLabel = switch (index) {
      0 => widget.isBangla ? 'আজ' : 'Today',
      1 => widget.isBangla ? 'গতকাল' : 'Yesterday',
      _ => null,
    };

    final month = widget.isBangla
        ? monthsBn[date.month - 1]
        : monthsEn[date.month - 1];
    final dateText = '${date.day} $month';

    return relativeLabel == null ? dateText : '$relativeLabel • $dateText';
  }

  String _chartMetricLabel(_ProgressChartMetric metric) {
    switch (metric) {
      case _ProgressChartMetric.calories:
        return widget.isBangla ? 'ক্যালরি' : 'Calories';
      case _ProgressChartMetric.water:
        return widget.isBangla ? 'পানি' : 'Water';
      case _ProgressChartMetric.exercise:
        return widget.isBangla ? 'ব্যায়াম' : 'Exercise';
      case _ProgressChartMetric.sleep:
        return widget.isBangla ? 'ঘুম' : 'Sleep';
      case _ProgressChartMetric.habits:
        return widget.isBangla ? 'অভ্যাস' : 'Habits';
    }
  }

  IconData _chartMetricIcon(_ProgressChartMetric metric) {
    switch (metric) {
      case _ProgressChartMetric.calories:
        return Icons.local_fire_department;
      case _ProgressChartMetric.water:
        return Icons.water_drop;
      case _ProgressChartMetric.exercise:
        return Icons.directions_run;
      case _ProgressChartMetric.sleep:
        return Icons.bedtime;
      case _ProgressChartMetric.habits:
        return Icons.check_circle_outline;
    }
  }

  double _chartMetricValue(
    _ProgressDay progressDay,
    _ProgressChartMetric metric,
  ) {
    switch (metric) {
      case _ProgressChartMetric.calories:
        return progressDay.dailyLogSummary.calories.toDouble();
      case _ProgressChartMetric.water:
        return progressDay.dailyLogSummary.waterGlasses.toDouble();
      case _ProgressChartMetric.exercise:
        return progressDay.dailyLogSummary.exerciseMinutes.toDouble();
      case _ProgressChartMetric.sleep:
        return progressDay.dailyLogSummary.sleepHours;
      case _ProgressChartMetric.habits:
        return progressDay.habitCompletions.isEmpty
            ? 0
            : (progressDay.completedHabitCount /
                      progressDay.habitCompletions.length) *
                  100;
    }
  }

  String _chartValueText(
    _ProgressDay progressDay,
    _ProgressChartMetric metric,
  ) {
    final value = _chartMetricValue(progressDay, metric);

    switch (metric) {
      case _ProgressChartMetric.calories:
      case _ProgressChartMetric.water:
      case _ProgressChartMetric.exercise:
        return value.round().toString();
      case _ProgressChartMetric.sleep:
        return value.toStringAsFixed(1);
      case _ProgressChartMetric.habits:
        return '${value.round()}%';
    }
  }

  String _chartAverageText(_ProgressChartMetric metric) {
    switch (metric) {
      case _ProgressChartMetric.calories:
        return '≈ ${_averageCalories.round()} kcal';
      case _ProgressChartMetric.water:
        return widget.isBangla
            ? '${_averageWater.toStringAsFixed(1)} গ্লাস'
            : '${_averageWater.toStringAsFixed(1)} glasses';
      case _ProgressChartMetric.exercise:
        return widget.isBangla
            ? '${_averageExercise.round()} মিনিট'
            : '${_averageExercise.round()} min';
      case _ProgressChartMetric.sleep:
        return widget.isBangla
            ? '${_averageSleep.toStringAsFixed(1)} ঘণ্টা'
            : '${_averageSleep.toStringAsFixed(1)} hours';
      case _ProgressChartMetric.habits:
        return '${_habitConsistency.round()}%';
    }
  }

  String _shortDayLabel(DateTime date) {
    const weekdaysBn = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
    const weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return widget.isBangla
        ? weekdaysBn[date.weekday - 1]
        : weekdaysEn[date.weekday - 1];
  }

  List<_ChartBarData> get _chartBars {
    return _sevenDayProgress.reversed
        .map((progressDay) {
          return _ChartBarData(
            label: _shortDayLabel(progressDay.date),
            value: _chartMetricValue(progressDay, _selectedChartMetric),
            valueText: _chartValueText(progressDay, _selectedChartMetric),
          );
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    widget.refreshListenable.removeListener(_handleRefreshRequest);
    AppSettingsController.instance.measurementUnitListenable.removeListener(
      _handleMeasurementUnitChanged,
    );
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.isBangla ? 'অগ্রগতি' : 'Progress'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProgress,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                widget.isBangla ? 'আজকের অগ্রগতি' : "Today's progress",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isBangla
                    ? 'আজকের সংরক্ষিত খাবার, পানি, ব্যায়াম, ঘুম ও অভ্যাসের সারাংশ।'
                    : 'A summary of today’s saved food, hydration, exercise, sleep, and habits.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 18),
              _WeightTrackingCard(
                isBangla: widget.isBangla,
                latestWeight: _latestWeight,
                startingWeight: _startingWeight,
                totalChange: _totalWeightChange,
                latestDateLabel: _latestWeight == null
                    ? null
                    : _weightDateLabel(_latestWeight!.date),
                isSaving: _isSavingWeight,
                hasTodayWeight: _todayWeight != null,
                onLogTodayWeight: _showTodayWeightEntrySheet,
                onAddPastWeight: _showPastWeightEntrySheet,
                signedChangeBuilder: _signedWeightChange,
              ),
              const SizedBox(height: 14),
              _WeightGoalCard(
                isBangla: widget.isBangla,
                targetWeightKg: _targetWeightKg,
                startingWeightKg: _startingWeight?.weightKg,
                latestWeightKg: _latestWeight?.weightKg,
                direction: _weightGoalDirection,
                progress: _weightGoalProgress,
                remainingKg: _remainingToTargetKg,
                isReached: _hasReachedWeightTarget,
                isSaving: _isSavingTargetWeight,
                onSetTarget: _showTargetWeightSheet,
              ),
              const SizedBox(height: 14),
              _BmiInsightsCard(
                isBangla: widget.isBangla,
                latestWeightKg: _latestWeight?.weightKg,
                heightCm: _heightCm,
                bmi: _bmi,
                category: _bmiCategory,
                healthyWeightMinKg: _healthyWeightMinKg,
                healthyWeightMaxKg: _healthyWeightMaxKg,
                isSavingHeight: _isSavingHeight,
                onSetHeight: _showHeightEntrySheet,
              ),
              const SizedBox(height: 14),
              _WeightTrendCard(
                isBangla: widget.isBangla,
                points: _weightTrendPoints,
                dayLabelBuilder: _shortDayLabel,
              ),
              const SizedBox(height: 14),
              _WeightHistoryCard(
                isBangla: widget.isBangla,
                entries: _weightEntries.reversed.toList(growable: false),
                isBusy: _isSavingWeight,
                dateLabelBuilder: _weightDateLabel,
                onEdit: _editWeightEntry,
                onDelete: _deleteWeightEntry,
              ),
              const SizedBox(height: 14),
              _ProgressSectionCard(
                title: widget.isBangla ? 'ক্যালরি অগ্রগতি' : 'Calorie progress',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '≈ ${_dailyLogSummary.calories} kcal',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${(_calorieProgress * 100).round()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _calorieProgress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      widget.isBangla
                          ? 'লক্ষ্য: ${widget.targetCaloriesMin}–${widget.targetCaloriesMax} kcal'
                          : 'Target: ${widget.targetCaloriesMin}–${widget.targetCaloriesMax} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ProgressSectionCard(
                title: widget.isBangla
                    ? 'আজকের স্বাস্থ্য সারাংশ'
                    : 'Today’s health summary',
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.15,
                  children: [
                    _ProgressMetric(
                      icon: Icons.water_drop,
                      value: '${_dailyLogSummary.waterGlasses}',
                      label: widget.isBangla ? 'গ্লাস পানি' : 'glasses water',
                    ),
                    _ProgressMetric(
                      icon: Icons.local_drink,
                      value: '${_dailyLogSummary.softDrinkMl} ml',
                      label: widget.isBangla ? 'কোমল পানীয়' : 'soft drink',
                    ),
                    _ProgressMetric(
                      icon: Icons.directions_run,
                      value: '${_dailyLogSummary.exerciseMinutes}',
                      label: widget.isBangla
                          ? 'মিনিট ব্যায়াম'
                          : 'exercise minutes',
                    ),
                    _ProgressMetric(
                      icon: Icons.bedtime,
                      value: _dailyLogSummary.sleepHours.toStringAsFixed(1),
                      label: widget.isBangla ? 'ঘণ্টা ঘুম' : 'sleep hours',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ProgressSectionCard(
                title: widget.isBangla
                    ? 'অভ্যাস ও চেক-ইন'
                    : 'Habits and check-in',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.isBangla
                                ? '$_completedHabitCount / ${_habitCompletions.length} অভ্যাস সম্পন্ন'
                                : '$_completedHabitCount / ${_habitCompletions.length} habits completed',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(_habitProgress * 100).round()}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _habitProgress,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _dailyCheckIn == null
                              ? Icons.fact_check_outlined
                              : Icons.fact_check,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _checkInText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isBangla ? 'গত ৭ দিনের অগ্রগতি' : 'Last 7 days',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isBangla
                    ? 'সারাংশ, চার্ট এবং প্রতিদিনের সংরক্ষিত তথ্য একসঙ্গে দেখুন।'
                    : 'Review averages, charts, and saved daily records together.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _SevenDayOverviewCard(
                isBangla: widget.isBangla,
                loggedDays: _loggedProgressDays.length,
                averageCalories: _averageCalories,
                averageWater: _averageWater,
                averageExercise: _averageExercise,
                averageSleep: _averageSleep,
                habitConsistency: _habitConsistency,
              ),
              const SizedBox(height: 14),
              _SevenDayChartCard(
                isBangla: widget.isBangla,
                selectedMetric: _selectedChartMetric,
                metricLabel: _chartMetricLabel(_selectedChartMetric),
                metricIcon: _chartMetricIcon(_selectedChartMetric),
                averageText: _chartAverageText(_selectedChartMetric),
                bars: _chartBars,
                onMetricSelected: (metric) {
                  setState(() {
                    _selectedChartMetric = metric;
                  });
                },
                metricLabelBuilder: _chartMetricLabel,
                metricIconBuilder: _chartMetricIcon,
              ),
              const SizedBox(height: 20),
              Text(
                widget.isBangla ? 'প্রতিদিনের বিস্তারিত' : 'Daily details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (_sevenDayProgress.isEmpty && !_isLoading)
                _EmptyHistoryCard(
                  message: widget.isBangla
                      ? 'এখনো কোনো ইতিহাস পাওয়া যায়নি।'
                      : 'No history is available yet.',
                )
              else
                ...List<Widget>.generate(_sevenDayProgress.length, (index) {
                  final progressDay = _sevenDayProgress[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SevenDayProgressCard(
                      isBangla: widget.isBangla,
                      dateLabel: _dateLabel(progressDay.date, index),
                      progressDay: progressDay,
                    ),
                  );
                }),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isBangla
                            ? 'গড় হিসাব শুধু যেসব দিনে অন্তত একটি তথ্য সংরক্ষিত হয়েছে, সেই দিনগুলোর উপর ভিত্তি করে।'
                            : 'Averages are based only on days that contain at least one saved record.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeightEntrySheet extends StatefulWidget {
  const _HeightEntrySheet({
    required this.isBangla,
    required this.initialHeightCm,
    required this.measurementUnit,
  });

  final bool isBangla;
  final double? initialHeightCm;
  final MeasurementUnitMode measurementUnit;

  @override
  State<_HeightEntrySheet> createState() => _HeightEntrySheetState();
}

class _HeightEntrySheetState extends State<_HeightEntrySheet> {
  late final TextEditingController _centimetreController;
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;

  late _HeightEntryMode _mode;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _mode = widget.measurementUnit == MeasurementUnitMode.imperial
        ? _HeightEntryMode.imperial
        : _HeightEntryMode.metric;

    final initialHeightCm = widget.initialHeightCm;
    _centimetreController = TextEditingController(
      text: initialHeightCm?.toStringAsFixed(1) ?? '',
    );

    var feetText = '';
    var inchesText = '';

    if (initialHeightCm != null) {
      var totalInches = (initialHeightCm / 2.54).round();
      final feet = totalInches ~/ 12;
      var inches = totalInches % 12;

      if (inches == 12) {
        totalInches += 1;
        inches = 0;
      }

      feetText = '$feet';
      inchesText = '$inches';
    }

    _feetController = TextEditingController(text: feetText);
    _inchesController = TextEditingController(text: inchesText);
  }

  void _clearError() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  void _changeMode(_HeightEntryMode mode) {
    if (_mode == mode) {
      return;
    }

    if (_mode == _HeightEntryMode.metric) {
      final centimetres = double.tryParse(
        _centimetreController.text.trim().replaceAll(',', '.'),
      );

      if (centimetres != null && centimetres > 0) {
        final totalInches = (centimetres / 2.54).round();
        _feetController.text = '${totalInches ~/ 12}';
        _inchesController.text = '${totalInches % 12}';
      }
    } else {
      final feet = int.tryParse(_feetController.text.trim());
      final inches = int.tryParse(_inchesController.text.trim());

      if (feet != null && inches != null && inches >= 0 && inches <= 11) {
        final centimetres = ((feet * 12) + inches) * 2.54;
        _centimetreController.text = centimetres.toStringAsFixed(1);
      }
    }

    setState(() {
      _mode = mode;
      _errorText = null;
    });
  }

  double? _validatedHeightCm() {
    double? heightCm;

    if (_mode == _HeightEntryMode.metric) {
      heightCm = double.tryParse(
        _centimetreController.text.trim().replaceAll(',', '.'),
      );
    } else {
      final feet = int.tryParse(_feetController.text.trim());
      final inches = int.tryParse(_inchesController.text.trim());

      if (feet != null &&
          inches != null &&
          feet >= 0 &&
          inches >= 0 &&
          inches <= 11) {
        heightCm = ((feet * 12) + inches) * 2.54;
      }
    }

    if (heightCm == null || heightCm < 100 || heightCm > 250) {
      setState(() {
        _errorText = widget.isBangla
            ? '১০০ থেকে ২৫০ সেমির মধ্যে সঠিক উচ্চতা লিখুন।'
            : 'Enter a valid height between 100 and 250 cm.';
      });
      return null;
    }

    return heightCm;
  }

  void _submit() {
    final heightCm = _validatedHeightCm();

    if (heightCm != null) {
      Navigator.of(context).pop(heightCm);
    }
  }

  @override
  void dispose() {
    _centimetreController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialHeightCm == null
                  ? (widget.isBangla ? 'উচ্চতা যোগ করুন' : 'Add height')
                  : (widget.isBangla ? 'উচ্চতা আপডেট করুন' : 'Update height'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isBangla
                  ? 'BMI ও স্বাস্থ্যকর ওজনের সীমা হিসাবের জন্য উচ্চতা ব্যবহার হবে।'
                  : 'Height is used to calculate BMI and the healthy weight reference range.',
            ),
            const SizedBox(height: 18),
            SegmentedButton<_HeightEntryMode>(
              segments: [
                ButtonSegment(
                  value: _HeightEntryMode.metric,
                  icon: const Icon(Icons.straighten),
                  label: Text(widget.isBangla ? 'সেমি' : 'cm'),
                ),
                ButtonSegment(
                  value: _HeightEntryMode.imperial,
                  icon: const Icon(Icons.height),
                  label: Text(widget.isBangla ? 'ফুট/ইঞ্চি' : 'ft/in'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                _changeMode(selection.first);
              },
            ),
            const SizedBox(height: 18),
            if (_mode == _HeightEntryMode.metric)
              TextField(
                controller: _centimetreController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: widget.isBangla ? 'উচ্চতা (সেমি)' : 'Height (cm)',
                  hintText: '170',
                  suffixText: 'cm',
                  errorText: _errorText,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _clearError(),
                onSubmitted: (_) => _submit(),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _feetController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: widget.isBangla ? 'ফুট' : 'Feet',
                        hintText: '5',
                        suffixText: 'ft',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _clearError(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _inchesController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: widget.isBangla ? 'ইঞ্চি' : 'Inches',
                        hintText: '7',
                        suffixText: 'in',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _clearError(),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                widget.isBangla ? 'উচ্চতা সংরক্ষণ করুন' : 'Save height',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetWeightEntrySheet extends StatefulWidget {
  const _TargetWeightEntrySheet({
    required this.isBangla,
    required this.initialTargetWeight,
    required this.measurementUnit,
  });

  final bool isBangla;
  final double? initialTargetWeight;
  final MeasurementUnitMode measurementUnit;

  @override
  State<_TargetWeightEntrySheet> createState() =>
      _TargetWeightEntrySheetState();
}

class _TargetWeightEntrySheetState extends State<_TargetWeightEntrySheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initialTargetWeight = widget.initialTargetWeight;
    _controller = TextEditingController(
      text: initialTargetWeight == null
          ? ''
          : MeasurementUnitConverter.displayWeightFromKilograms(
              initialTargetWeight,
              widget.measurementUnit,
            ).toStringAsFixed(1),
    );
  }

  void _submit() {
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    final minimum = MeasurementUnitConverter.minimumWeightInput(
      20,
      widget.measurementUnit,
    );
    final maximum = MeasurementUnitConverter.maximumWeightInput(
      400,
      widget.measurementUnit,
    );

    if (parsed == null || parsed < minimum || parsed > maximum) {
      final unit = MeasurementUnitConverter.weightUnit(widget.measurementUnit);

      setState(() {
        _errorText = widget.isBangla
            ? '${minimum.toStringAsFixed(1)} থেকে ${maximum.toStringAsFixed(1)} $unit-এর মধ্যে সঠিক লক্ষ্য ওজন লিখুন।'
            : 'Enter a valid target weight between ${minimum.toStringAsFixed(1)} and ${maximum.toStringAsFixed(1)} $unit.';
      });
      return;
    }

    Navigator.of(context).pop(
      MeasurementUnitConverter.inputWeightToKilograms(
        parsed,
        widget.measurementUnit,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialTargetWeight == null
                  ? (widget.isBangla
                        ? 'লক্ষ্য ওজন ঠিক করুন'
                        : 'Set target weight')
                  : (widget.isBangla
                        ? 'লক্ষ্য ওজন আপডেট করুন'
                        : 'Update target weight'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isBangla
                  ? 'শুরুর ওজন ও সর্বশেষ ওজন থেকে লক্ষ্য অগ্রগতি হিসাব হবে।'
                  : 'Goal progress is calculated from your starting and latest weights.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: widget.isBangla
                    ? 'লক্ষ্য ওজন (${MeasurementUnitConverter.weightUnit(widget.measurementUnit)})'
                    : 'Target weight (${MeasurementUnitConverter.weightUnit(widget.measurementUnit)})',
                hintText: widget.measurementUnit == MeasurementUnitMode.imperial
                    ? '143.3'
                    : '65.0',
                suffixText: MeasurementUnitConverter.weightUnit(
                  widget.measurementUnit,
                ),
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.flag_outlined),
              label: Text(
                widget.isBangla
                    ? 'লক্ষ্য ওজন সংরক্ষণ করুন'
                    : 'Save target weight',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightEntrySheet extends StatefulWidget {
  const _WeightEntrySheet({
    required this.isBangla,
    required this.initialDate,
    required this.initialWeight,
    required this.isEditing,
    required this.allowDateSelection,
    required this.measurementUnit,
  });

  final bool isBangla;
  final DateTime initialDate;
  final double? initialWeight;
  final bool isEditing;
  final bool allowDateSelection;
  final MeasurementUnitMode measurementUnit;

  @override
  State<_WeightEntrySheet> createState() => _WeightEntrySheetState();
}

class _WeightEntrySheetState extends State<_WeightEntrySheet> {
  late final TextEditingController _controller;
  late DateTime _selectedDate;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    final initialWeight = widget.initialWeight;
    _controller = TextEditingController(
      text: initialWeight == null
          ? ''
          : MeasurementUnitConverter.displayWeightFromKilograms(
              initialWeight,
              widget.measurementUnit,
            ).toStringAsFixed(1),
    );
  }

  String _dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(today.year - 10, today.month, today.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: today,
      helpText: widget.isBangla ? 'ওজনের তারিখ বেছে নিন' : 'Select weight date',
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  double? _validatedWeight() {
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    final minimum = MeasurementUnitConverter.minimumWeightInput(
      20,
      widget.measurementUnit,
    );
    final maximum = MeasurementUnitConverter.maximumWeightInput(
      400,
      widget.measurementUnit,
    );

    if (parsed == null || parsed < minimum || parsed > maximum) {
      final unit = MeasurementUnitConverter.weightUnit(widget.measurementUnit);

      setState(() {
        _errorText = widget.isBangla
            ? '${minimum.toStringAsFixed(1)} থেকে ${maximum.toStringAsFixed(1)} $unit-এর মধ্যে সঠিক ওজন লিখুন।'
            : 'Enter a valid weight between ${minimum.toStringAsFixed(1)} and ${maximum.toStringAsFixed(1)} $unit.';
      });
      return null;
    }

    return MeasurementUnitConverter.inputWeightToKilograms(
      parsed,
      widget.measurementUnit,
    );
  }

  void _submit() {
    final weightKg = _validatedWeight();

    if (weightKg != null) {
      Navigator.of(
        context,
      ).pop(_WeightEntryResult(date: _selectedDate, weightKg: weightKg));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isEditing
                  ? (widget.isBangla
                        ? 'ওজনের এন্ট্রি সম্পাদনা করুন'
                        : 'Edit weight entry')
                  : (widget.isBangla
                        ? 'ওজনের এন্ট্রি যোগ করুন'
                        : 'Add weight entry'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isBangla
                  ? 'একই তারিখে আবার সংরক্ষণ করলে আগের ওজনটি হালনাগাদ হবে।'
                  : 'Saving on an existing date updates that weight entry.',
            ),
            const SizedBox(height: 18),
            if (widget.allowDateSelection) ...[
              Text(
                widget.isBangla ? 'তারিখ' : 'Date',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(_dateText(_selectedDate)),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: widget.isBangla
                    ? 'ওজন (${MeasurementUnitConverter.weightUnit(widget.measurementUnit)})'
                    : 'Weight (${MeasurementUnitConverter.weightUnit(widget.measurementUnit)})',
                hintText: widget.measurementUnit == MeasurementUnitMode.imperial
                    ? '155.4'
                    : '70.5',
                suffixText: MeasurementUnitConverter.weightUnit(
                  widget.measurementUnit,
                ),
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.monitor_weight_outlined),
              label: Text(widget.isBangla ? 'ওজন সংরক্ষণ করুন' : 'Save weight'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrackingCard extends StatelessWidget {
  const _WeightTrackingCard({
    required this.isBangla,
    required this.latestWeight,
    required this.startingWeight,
    required this.totalChange,
    required this.latestDateLabel,
    required this.isSaving,
    required this.hasTodayWeight,
    required this.onLogTodayWeight,
    required this.onAddPastWeight,
    required this.signedChangeBuilder,
  });

  final bool isBangla;
  final StoredWeightEntry? latestWeight;
  final StoredWeightEntry? startingWeight;
  final double? totalChange;
  final String? latestDateLabel;
  final bool isSaving;
  final bool hasTodayWeight;
  final VoidCallback onLogTodayWeight;
  final VoidCallback onAddPastWeight;
  final String Function(double change) signedChangeBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasWeight = latestWeight != null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBangla ? 'ওজন ট্র্যাকিং' : 'Weight tracking',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasWeight)
              Text(
                isBangla
                    ? 'প্রথম ওজনটি যোগ করলে সেটিই আপনার শুরুর ওজন হিসেবে ধরা হবে।'
                    : 'Your first saved entry will become your starting weight.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                MeasurementUnitConverter.formatWeight(
                  latestWeight!.weightKg,
                  AppSettingsController.instance.currentMeasurementUnit,
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isBangla
                    ? 'সর্বশেষ ওজন • $latestDateLabel'
                    : 'Latest weight • $latestDateLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _WeightSummaryValue(
                      label: isBangla ? 'শুরুর ওজন' : 'Starting weight',
                      value: MeasurementUnitConverter.formatWeight(
                        startingWeight!.weightKg,
                        AppSettingsController.instance.currentMeasurementUnit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WeightSummaryValue(
                      label: isBangla ? 'মোট পরিবর্তন' : 'Total change',
                      value: signedChangeBuilder(totalChange ?? 0),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isSaving ? null : onLogTodayWeight,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(
                hasTodayWeight
                    ? (isBangla
                          ? 'আজকের ওজন আপডেট করুন'
                          : "Update today's weight")
                    : (isBangla ? 'আজকের ওজন যোগ করুন' : "Log today's weight"),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isSaving ? null : onAddPastWeight,
              icon: const Icon(Icons.history),
              label: Text(
                isBangla
                    ? 'আগের তারিখের ওজন যোগ করুন'
                    : 'Add weight for a past date',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightGoalCard extends StatelessWidget {
  const _WeightGoalCard({
    required this.isBangla,
    required this.targetWeightKg,
    required this.startingWeightKg,
    required this.latestWeightKg,
    required this.direction,
    required this.progress,
    required this.remainingKg,
    required this.isReached,
    required this.isSaving,
    required this.onSetTarget,
  });

  final bool isBangla;
  final double? targetWeightKg;
  final double? startingWeightKg;
  final double? latestWeightKg;
  final _WeightGoalDirection? direction;
  final double progress;
  final double? remainingKg;
  final bool isReached;
  final bool isSaving;
  final VoidCallback onSetTarget;

  String _directionLabel() {
    switch (direction) {
      case _WeightGoalDirection.loss:
        return isBangla ? 'ওজন কমানোর লক্ষ্য' : 'Weight-loss goal';
      case _WeightGoalDirection.gain:
        return isBangla ? 'ওজন বাড়ানোর লক্ষ্য' : 'Weight-gain goal';
      case _WeightGoalDirection.maintain:
        return isBangla ? 'ওজন বজায় রাখার লক্ষ্য' : 'Weight-maintenance goal';
      case null:
        return isBangla ? 'লক্ষ্য ওজন' : 'Target weight';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasTarget = targetWeightKg != null;
    final canCalculateProgress =
        hasTarget && startingWeightKg != null && latestWeightKg != null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBangla
                        ? 'লক্ষ্য ওজন ও অগ্রগতি'
                        : 'Target weight and progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasTarget)
              Text(
                isBangla
                    ? 'লক্ষ্য ওজন ঠিক করলে কতটা বাকি এবং কত শতাংশ অগ্রগতি হয়েছে তা দেখা যাবে।'
                    : 'Set a target weight to see how much remains and your completion percentage.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                MeasurementUnitConverter.formatWeight(
                  targetWeightKg!,
                  AppSettingsController.instance.currentMeasurementUnit,
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _directionLabel(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (!canCalculateProgress)
                Text(
                  isBangla
                      ? 'লক্ষ্য অগ্রগতি হিসাব করতে অন্তত একটি ওজনের এন্ট্রি যোগ করুন।'
                      : 'Add at least one weight entry to calculate goal progress.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _WeightSummaryValue(
                        label: isBangla ? 'সর্বশেষ ওজন' : 'Latest weight',
                        value: MeasurementUnitConverter.formatWeight(
                          latestWeightKg!,
                          AppSettingsController.instance.currentMeasurementUnit,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WeightSummaryValue(
                        label: isBangla ? 'বাকি' : 'Remaining',
                        value: MeasurementUnitConverter.formatWeight(
                          isReached ? 0 : remainingKg!,
                          AppSettingsController.instance.currentMeasurementUnit,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isReached
                            ? (isBangla ? 'লক্ষ্য অর্জিত' : 'Target reached')
                            : (isBangla ? 'লক্ষ্য অগ্রগতি' : 'Goal progress'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isSaving ? null : onSetTarget,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_outlined),
              label: Text(
                hasTarget
                    ? (isBangla
                          ? 'লক্ষ্য ওজন আপডেট করুন'
                          : 'Update target weight')
                    : (isBangla ? 'লক্ষ্য ওজন ঠিক করুন' : 'Set target weight'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiInsightsCard extends StatelessWidget {
  const _BmiInsightsCard({
    required this.isBangla,
    required this.latestWeightKg,
    required this.heightCm,
    required this.bmi,
    required this.category,
    required this.healthyWeightMinKg,
    required this.healthyWeightMaxKg,
    required this.isSavingHeight,
    required this.onSetHeight,
  });

  final bool isBangla;
  final double? latestWeightKg;
  final double? heightCm;
  final double? bmi;
  final _BmiCategory? category;
  final double? healthyWeightMinKg;
  final double? healthyWeightMaxKg;
  final bool isSavingHeight;
  final VoidCallback onSetHeight;

  String _categoryLabel() {
    switch (category) {
      case _BmiCategory.underweight:
        return isBangla ? 'কম ওজন' : 'Underweight';
      case _BmiCategory.healthy:
        return isBangla ? 'স্বাস্থ্যকর ওজনের সীমা' : 'Healthy weight range';
      case _BmiCategory.overweight:
        return isBangla ? 'অতিরিক্ত ওজন' : 'Overweight';
      case _BmiCategory.obesity:
        return isBangla ? 'স্থূলতার সীমা' : 'Obesity range';
      case null:
        return '—';
    }
  }

  String _categoryMessage() {
    switch (category) {
      case _BmiCategory.underweight:
        return isBangla
            ? 'BMI প্রাপ্তবয়স্কদের রেফারেন্স সীমার নিচে। অনিচ্ছাকৃতভাবে ওজন কমলে স্বাস্থ্যকর্মীর পরামর্শ নিন।'
            : 'BMI is below the adult reference range. Seek professional advice if weight loss was unintentional.';
      case _BmiCategory.healthy:
        return isBangla
            ? 'BMI প্রাপ্তবয়স্কদের স্বাস্থ্যকর ওজনের রেফারেন্স সীমার মধ্যে আছে।'
            : 'BMI is within the adult healthy-weight reference range.';
      case _BmiCategory.overweight:
        return isBangla
            ? 'BMI প্রাপ্তবয়স্কদের স্বাস্থ্যকর ওজনের রেফারেন্স সীমার উপরে। BMI শরীরের গঠন সরাসরি মাপে না।'
            : 'BMI is above the adult healthy-weight reference range. BMI does not directly measure body composition.';
      case _BmiCategory.obesity:
        return isBangla
            ? 'BMI প্রাপ্তবয়স্কদের স্থূলতার সীমায় আছে। ব্যক্তিগত স্বাস্থ্যঝুঁকি বুঝতে স্বাস্থ্যকর্মীর পরামর্শ সহায়ক হতে পারে।'
            : 'BMI is in the adult obesity range. Professional guidance may help assess individual health risk.';
      case null:
        return '';
    }
  }

  String _heightText() {
    final value = heightCm;

    if (value == null) {
      return '—';
    }

    return MeasurementUnitConverter.formatHeight(
      value,
      AppSettingsController.instance.currentMeasurementUnit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasHeight = heightCm != null;
    final hasWeight = latestWeightKg != null;
    final hasInsights = bmi != null && category != null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBangla
                        ? 'বিএমআই ও স্বাস্থ্যকর ওজন বিশ্লেষণ'
                        : 'BMI and healthy weight insights',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasHeight)
              Text(
                isBangla
                    ? 'BMI হিসাব করতে প্রথমে আপনার উচ্চতা যোগ করুন।'
                    : 'Add your height first to calculate BMI.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else if (!hasWeight)
              Text(
                isBangla
                    ? 'উচ্চতা সংরক্ষিত হয়েছে। BMI হিসাব করতে অন্তত একটি ওজনের এন্ট্রি যোগ করুন।'
                    : 'Height is saved. Add at least one weight entry to calculate BMI.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else if (hasInsights) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bmi!.toStringAsFixed(1),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'BMI',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _categoryLabel(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _WeightSummaryValue(
                      label: isBangla ? 'সর্বশেষ ওজন' : 'Latest weight',
                      value: MeasurementUnitConverter.formatWeight(
                        latestWeightKg!,
                        AppSettingsController.instance.currentMeasurementUnit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WeightSummaryValue(
                      label: isBangla ? 'উচ্চতা' : 'Height',
                      value: _heightText(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.balance_outlined, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isBangla
                            ? 'আপনার উচ্চতায় প্রাপ্তবয়স্কদের স্বাস্থ্যকর ওজনের রেফারেন্স: ${MeasurementUnitConverter.formatWeightRange(healthyWeightMinKg!, healthyWeightMaxKg!, AppSettingsController.instance.currentMeasurementUnit)}'
                            : 'Adult healthy-weight reference for your height: ${MeasurementUnitConverter.formatWeightRange(healthyWeightMinKg!, healthyWeightMaxKg!, AppSettingsController.instance.currentMeasurementUnit)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _categoryMessage(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: isSavingHeight ? null : onSetHeight,
              icon: isSavingHeight
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.height),
              label: Text(
                hasHeight
                    ? (isBangla ? 'উচ্চতা আপডেট করুন' : 'Update height')
                    : (isBangla ? 'উচ্চতা যোগ করুন' : 'Add height'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isBangla
                  ? 'BMI প্রাপ্তবয়স্কদের জন্য একটি প্রাথমিক যাচাইয়ের মাপকাঠি—এটি রোগনির্ণয় নয় এবং শরীরের চর্বি সরাসরি মাপে না।'
                  : 'BMI is an adult screening measure, not a diagnosis or a direct measurement of body fat.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightSummaryValue extends StatelessWidget {
  const _WeightSummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({
    required this.isBangla,
    required this.points,
    required this.dayLabelBuilder,
  });

  final bool isBangla;
  final List<_WeightTrendPoint> points;
  final String Function(DateTime date) dayLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weights = points
        .map((point) => point.weightKg)
        .whereType<double>()
        .toList(growable: false);

    final minimumWeight = weights.isEmpty
        ? 0.0
        : weights.reduce((first, second) => math.min(first, second).toDouble());
    final maximumWeight = weights.isEmpty
        ? 0.0
        : weights.reduce((first, second) => math.max(first, second).toDouble());
    final range = maximumWeight - minimumWeight;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isBangla
                  ? '৭ দিনের ওজনের ধারা (${MeasurementUnitConverter.weightUnit(AppSettingsController.instance.currentMeasurementUnit)})'
                  : 'Seven-day weight trend (${MeasurementUnitConverter.weightUnit(AppSettingsController.instance.currentMeasurementUnit)})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBangla
                  ? 'ওজন শুধু যেদিন সংরক্ষণ করা হয়েছে, সেই দিনেই দেখানো হবে।'
                  : 'Weight appears only on days where an entry was saved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            if (weights.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isBangla
                      ? 'গত ৭ দিনে কোনো ওজন সংরক্ষণ করা হয়নি।'
                      : 'No weight has been saved in the last seven days.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: points
                      .map((point) {
                        final weight = point.weightKg;
                        final normalized = weight == null
                            ? 0.0
                            : range < 0.1
                            ? 0.55
                            : ((weight - minimumWeight) / range)
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                        final barHeight = weight == null
                            ? 6.0
                            : 34.0 + (normalized * 74);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 24,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      weight == null
                                          ? '—'
                                          : MeasurementUnitConverter.displayWeightFromKilograms(
                                              weight,
                                              AppSettingsController
                                                  .instance
                                                  .currentMeasurementUnit,
                                            ).toStringAsFixed(1),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  height: 108,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOut,
                                      width: 22,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: weight == null
                                            ? colorScheme
                                                  .surfaceContainerHighest
                                            : colorScheme.primary,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(7),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dayLabelBuilder(point.date),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeightHistoryCard extends StatelessWidget {
  const _WeightHistoryCard({
    required this.isBangla,
    required this.entries,
    required this.isBusy,
    required this.dateLabelBuilder,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isBangla;
  final List<StoredWeightEntry> entries;
  final bool isBusy;
  final String Function(DateTime date) dateLabelBuilder;
  final ValueChanged<StoredWeightEntry> onEdit;
  final ValueChanged<StoredWeightEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isBangla ? 'ওজনের ইতিহাস' : 'Weight history',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBangla
                  ? 'সর্বশেষ এন্ট্রি উপরে দেখানো হচ্ছে।'
                  : 'The newest entry appears first.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isBangla
                      ? 'এখনো কোনো ওজন সংরক্ষণ করা হয়নি।'
                      : 'No weight entries have been saved yet.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...List<Widget>.generate(entries.length, (index) {
                final entry = entries[index];

                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Icon(
                          Icons.monitor_weight_outlined,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        MeasurementUnitConverter.formatWeight(
                          entry.weightKg,
                          AppSettingsController.instance.currentMeasurementUnit,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(dateLabelBuilder(entry.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: isBangla ? 'সম্পাদনা' : 'Edit',
                            onPressed: isBusy ? null : () => onEdit(entry),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: isBangla ? 'মুছুন' : 'Delete',
                            onPressed: isBusy ? null : () => onDelete(entry),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                    if (index != entries.length - 1)
                      Divider(color: colorScheme.outlineVariant),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SevenDayOverviewCard extends StatelessWidget {
  const _SevenDayOverviewCard({
    required this.isBangla,
    required this.loggedDays,
    required this.averageCalories,
    required this.averageWater,
    required this.averageExercise,
    required this.averageSleep,
    required this.habitConsistency,
  });

  final bool isBangla;
  final int loggedDays;
  final double averageCalories;
  final double averageWater;
  final double averageExercise;
  final double averageSleep;
  final double habitConsistency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isBangla ? '৭ দিনের সারাংশ' : 'Seven-day overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBangla ? 'লগ করা দিনের গড়' : 'Averages for logged days',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 2.05,
              children: [
                _OverviewMetric(
                  icon: Icons.calendar_month_outlined,
                  value: '$loggedDays/7',
                  label: isBangla ? 'দিন লগ করা' : 'days logged',
                ),
                _OverviewMetric(
                  icon: Icons.local_fire_department,
                  value: '≈ ${averageCalories.round()}',
                  label: 'kcal',
                ),
                _OverviewMetric(
                  icon: Icons.water_drop,
                  value: averageWater.toStringAsFixed(1),
                  label: isBangla ? 'গ্লাস পানি' : 'glasses water',
                ),
                _OverviewMetric(
                  icon: Icons.directions_run,
                  value: '${averageExercise.round()}',
                  label: isBangla ? 'মিনিট ব্যায়াম' : 'exercise minutes',
                ),
                _OverviewMetric(
                  icon: Icons.bedtime,
                  value: averageSleep.toStringAsFixed(1),
                  label: isBangla ? 'ঘণ্টা ঘুম' : 'sleep hours',
                ),
                _OverviewMetric(
                  icon: Icons.check_circle_outline,
                  value: '${habitConsistency.round()}%',
                  label: isBangla
                      ? 'অভ্যাসের ধারাবাহিকতা'
                      : 'habit consistency',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SevenDayChartCard extends StatelessWidget {
  const _SevenDayChartCard({
    required this.isBangla,
    required this.selectedMetric,
    required this.metricLabel,
    required this.metricIcon,
    required this.averageText,
    required this.bars,
    required this.onMetricSelected,
    required this.metricLabelBuilder,
    required this.metricIconBuilder,
  });

  final bool isBangla;
  final _ProgressChartMetric selectedMetric;
  final String metricLabel;
  final IconData metricIcon;
  final String averageText;
  final List<_ChartBarData> bars;
  final ValueChanged<_ProgressChartMetric> onMetricSelected;
  final String Function(_ProgressChartMetric metric) metricLabelBuilder;
  final IconData Function(_ProgressChartMetric metric) metricIconBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isBangla ? '৭ দিনের চার্ট' : 'Seven-day chart',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _ProgressChartMetric.values
                    .map((metric) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(metricIconBuilder(metric), size: 18),
                          label: Text(metricLabelBuilder(metric)),
                          selected: selectedMetric == metric,
                          onSelected: (_) => onMetricSelected(metric),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(metricIcon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    metricLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  averageText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isBangla
                  ? 'বাম দিকের বার সবচেয়ে পুরোনো দিন, ডান দিকের বার আজ।'
                  : 'The oldest day is on the left and today is on the right.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _SevenDayBarChart(bars: bars),
          ],
        ),
      ),
    );
  }
}

class _SevenDayBarChart extends StatelessWidget {
  const _SevenDayBarChart({required this.bars});

  final List<_ChartBarData> bars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    var maximumValue = 0.0;
    for (final bar in bars) {
      maximumValue = math.max(maximumValue, bar.value);
    }

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars
            .map((bar) {
              final heightFactor = maximumValue <= 0
                  ? 0.0
                  : (bar.value / maximumValue).clamp(0.0, 1.0).toDouble();
              final barHeight = bar.value <= 0
                  ? 6.0
                  : math.max(12.0, heightFactor * 108).toDouble();

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 22,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            bar.valueText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 108,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: 22,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: bar.value <= 0
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bar.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _ProgressSectionCard extends StatelessWidget {
  const _ProgressSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SevenDayProgressCard extends StatelessWidget {
  const _SevenDayProgressCard({
    required this.isBangla,
    required this.dateLabel,
    required this.progressDay,
  });

  final bool isBangla;
  final String dateLabel;
  final _ProgressDay progressDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = progressDay.dailyLogSummary;
    final checkIn = progressDay.dailyCheckIn;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: progressDay.hasSavedData
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    progressDay.hasSavedData
                        ? (isBangla ? 'তথ্য আছে' : 'Saved')
                        : (isBangla ? 'তথ্য নেই' : 'No data'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: progressDay.hasSavedData
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.local_fire_department,
                        value: '${summary.calories}',
                        label: 'kcal',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.water_drop,
                        value: '${summary.waterGlasses}',
                        label: isBangla ? 'গ্লাস পানি' : 'glasses water',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.directions_run,
                        value: '${summary.exerciseMinutes}',
                        label: isBangla ? 'মিনিট ব্যায়াম' : 'exercise min',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.bedtime,
                        value: summary.sleepHours.toStringAsFixed(1),
                        label: isBangla ? 'ঘণ্টা ঘুম' : 'sleep hours',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: Icons.check_circle_outline,
                        value:
                            '${progressDay.completedHabitCount}/${progressDay.habitCompletions.length}',
                        label: isBangla ? 'অভ্যাস' : 'habits',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HistoryMetric(
                        icon: checkIn == null
                            ? Icons.fact_check_outlined
                            : Icons.fact_check,
                        value: checkIn == null
                            ? '—'
                            : '${checkIn.energyLevel}/5',
                        label: isBangla ? 'চেক-ইন' : 'check-in',
                      ),
                    ),
                  ],
                );
              },
            ),
            if (summary.softDrinkMl > 0) ...[
              const SizedBox(height: 12),
              Text(
                isBangla
                    ? 'কোমল পানীয়: ${summary.softDrinkMl} ml'
                    : 'Soft drink: ${summary.softDrinkMl} ml',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
