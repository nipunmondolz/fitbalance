import 'package:flutter/material.dart';

enum _LogType { meal, water, exercise, sleep }

enum _MealTime { morning, noon, afternoon, night }

class _DailyLogEntry {
  const _DailyLogEntry({
    required this.type,
    required this.title,
    required this.amount,
    required this.details,
  });

  final _LogType type;
  final String title;
  final double amount;
  final String details;
}

class _FoodPortion {
  const _FoodPortion({
    required this.nameBn,
    required this.nameEn,
    required this.calories,
  });

  final String nameBn;
  final String nameEn;
  final int calories;
}

class _FoodItem {
  const _FoodItem({
    required this.nameBn,
    required this.nameEn,
    required this.portions,
  });

  final String nameBn;
  final String nameEn;
  final List<_FoodPortion> portions;
}

class _CustomFoodCategory {
  const _CustomFoodCategory({
    required this.nameBn,
    required this.nameEn,
    required this.mediumCalories,
    required this.keywords,
  });

  final String nameBn;
  final String nameEn;
  final int mediumCalories;
  final List<String> keywords;
}

class _CustomPortion {
  const _CustomPortion({
    required this.nameBn,
    required this.nameEn,
    required this.multiplier,
  });

  final String nameBn;
  final String nameEn;
  final double multiplier;
}

const _foods = <_FoodItem>[
  _FoodItem(
    nameBn: 'সাদা ভাত',
    nameEn: 'White rice',
    portions: [
      _FoodPortion(nameBn: '½ কাপ', nameEn: '½ cup', calories: 133),
      _FoodPortion(nameBn: '১ কাপ', nameEn: '1 cup', calories: 266),
      _FoodPortion(nameBn: '১ প্লেট', nameEn: '1 plate', calories: 390),
    ],
  ),
  _FoodItem(
    nameBn: 'রুটি',
    nameEn: 'Roti',
    portions: [
      _FoodPortion(nameBn: '১টি মাঝারি', nameEn: '1 medium', calories: 120),
      _FoodPortion(nameBn: '২টি মাঝারি', nameEn: '2 medium', calories: 240),
      _FoodPortion(nameBn: '৩টি মাঝারি', nameEn: '3 medium', calories: 360),
    ],
  ),
  _FoodItem(
    nameBn: 'ডাল',
    nameEn: 'Lentil dal',
    portions: [
      _FoodPortion(nameBn: '½ কাপ', nameEn: '½ cup', calories: 115),
      _FoodPortion(nameBn: '১ কাপ', nameEn: '1 cup', calories: 230),
    ],
  ),
  _FoodItem(
    nameBn: 'সেদ্ধ ডিম',
    nameEn: 'Boiled egg',
    portions: [
      _FoodPortion(nameBn: '১টি', nameEn: '1 egg', calories: 78),
      _FoodPortion(nameBn: '২টি', nameEn: '2 eggs', calories: 156),
    ],
  ),
  _FoodItem(
    nameBn: 'মুরগির তরকারি',
    nameEn: 'Chicken curry',
    portions: [
      _FoodPortion(
        nameBn: '১ টুকরা ও ঝোল',
        nameEn: '1 piece with gravy',
        calories: 240,
      ),
      _FoodPortion(
        nameBn: '২ টুকরা ও ঝোল',
        nameEn: '2 pieces with gravy',
        calories: 420,
      ),
    ],
  ),
  _FoodItem(
    nameBn: 'মাছের তরকারি',
    nameEn: 'Fish curry',
    portions: [
      _FoodPortion(
        nameBn: '১ টুকরা ও ঝোল',
        nameEn: '1 piece with gravy',
        calories: 150,
      ),
      _FoodPortion(
        nameBn: '২ টুকরা ও ঝোল',
        nameEn: '2 pieces with gravy',
        calories: 280,
      ),
    ],
  ),
  _FoodItem(
    nameBn: 'সবজি',
    nameEn: 'Mixed vegetables',
    portions: [
      _FoodPortion(nameBn: '½ কাপ', nameEn: '½ cup', calories: 90),
      _FoodPortion(nameBn: '১ কাপ', nameEn: '1 cup', calories: 180),
    ],
  ),
  _FoodItem(
    nameBn: 'খিচুড়ি',
    nameEn: 'Khichuri',
    portions: [
      _FoodPortion(nameBn: '১ কাপ', nameEn: '1 cup', calories: 240),
      _FoodPortion(nameBn: '১ প্লেট', nameEn: '1 plate', calories: 360),
    ],
  ),
  _FoodItem(
    nameBn: 'বিরিয়ানি',
    nameEn: 'Biryani',
    portions: [
      _FoodPortion(nameBn: '½ প্লেট', nameEn: '½ plate', calories: 350),
      _FoodPortion(nameBn: '১ প্লেট', nameEn: '1 plate', calories: 700),
    ],
  ),
  _FoodItem(
    nameBn: 'কলা',
    nameEn: 'Banana',
    portions: [
      _FoodPortion(nameBn: '১টি মাঝারি', nameEn: '1 medium', calories: 105),
      _FoodPortion(nameBn: '২টি মাঝারি', nameEn: '2 medium', calories: 210),
    ],
  ),
  _FoodItem(
    nameBn: 'আপেল',
    nameEn: 'Apple',
    portions: [
      _FoodPortion(nameBn: '১টি মাঝারি', nameEn: '1 medium', calories: 95),
      _FoodPortion(nameBn: '½টি', nameEn: '½ apple', calories: 48),
    ],
  ),
  _FoodItem(
    nameBn: 'দুধ',
    nameEn: 'Milk',
    portions: [
      _FoodPortion(nameBn: '½ কাপ', nameEn: '½ cup', calories: 75),
      _FoodPortion(nameBn: '১ কাপ', nameEn: '1 cup', calories: 150),
    ],
  ),
  _FoodItem(
    nameBn: 'টক দই',
    nameEn: 'Plain yogurt',
    portions: [
      _FoodPortion(nameBn: '½ কাপ', nameEn: '½ cup', calories: 75),
      _FoodPortion(nameBn: '১ কাপ', nameEn: '1 cup', calories: 150),
    ],
  ),
  _FoodItem(
    nameBn: 'পাউরুটি',
    nameEn: 'Bread',
    portions: [
      _FoodPortion(nameBn: '১ স্লাইস', nameEn: '1 slice', calories: 80),
      _FoodPortion(nameBn: '২ স্লাইস', nameEn: '2 slices', calories: 160),
    ],
  ),
];

const _customFoodCategories = <_CustomFoodCategory>[
  _CustomFoodCategory(
    nameBn: 'ভাত ও শস্য',
    nameEn: 'Rice and grains',
    mediumCalories: 300,
    keywords: [
      'ভাত',
      'চাল',
      'পোলাও',
      'খিচুড়ি',
      'বিরিয়ানি',
      'rice',
      'pulao',
      'khichuri',
      'biryani',
      'oats',
    ],
  ),
  _CustomFoodCategory(
    nameBn: 'রুটি ও স্টার্চ',
    nameEn: 'Bread and starch',
    mediumCalories: 220,
    keywords: [
      'রুটি',
      'পরোটা',
      'পাউরুটি',
      'নান',
      'আলু',
      'স্যান্ডউইচ',
      'নুডলস',
      'পাস্তা',
      'bread',
      'roti',
      'paratha',
      'naan',
      'potato',
      'noodle',
      'pasta',
    ],
  ),
  _CustomFoodCategory(
    nameBn: 'মাংস, মাছ ও ডিম',
    nameEn: 'Meat, fish and egg',
    mediumCalories: 280,
    keywords: [
      'মাংস',
      'গরু',
      'খাসি',
      'মুরগি',
      'চিকেন',
      'মাছ',
      'ডিম',
      'beef',
      'mutton',
      'chicken',
      'fish',
      'egg',
    ],
  ),
  _CustomFoodCategory(
    nameBn: 'ডাল ও শিমজাতীয়',
    nameEn: 'Lentils and beans',
    mediumCalories: 220,
    keywords: [
      'ডাল',
      'ছোলা',
      'শিম',
      'মটর',
      'lentil',
      'dal',
      'chickpea',
      'bean',
      'pea',
    ],
  ),
  _CustomFoodCategory(
    nameBn: 'সবজি',
    nameEn: 'Vegetables',
    mediumCalories: 120,
    keywords: [
      'সবজি',
      'শাক',
      'বেগুন',
      'লাউ',
      'ফুলকপি',
      'বাঁধাকপি',
      'vegetable',
      'spinach',
      'salad',
    ],
  ),
  _CustomFoodCategory(
    nameBn: 'ফল',
    nameEn: 'Fruit',
    mediumCalories: 100,
    keywords: [
      'ফল',
      'কলা',
      'আপেল',
      'আম',
      'কমলা',
      'পেয়ারা',
      'fruit',
      'banana',
      'apple',
      'mango',
      'orange',
      'guava',
    ],
  ),
  _CustomFoodCategory(
    nameBn: 'দুধ ও দুগ্ধজাত',
    nameEn: 'Milk and dairy',
    mediumCalories: 150,
    keywords: ['দুধ', 'দই', 'পনির', 'milk', 'yogurt', 'curd', 'cheese'],
  ),
  _CustomFoodCategory(
    nameBn: 'নাশতা ও মিষ্টি',
    nameEn: 'Snacks and sweets',
    mediumCalories: 300,
    keywords: [
      'মিষ্টি',
      'কেক',
      'বিস্কুট',
      'চিপস',
      'সমুচা',
      'সিঙ্গারা',
      'sweet',
      'cake',
      'biscuit',
      'chips',
      'samosa',
      'snack',
    ],
  ),
  _CustomFoodCategory(
    nameBn: 'পানীয়',
    nameEn: 'Drinks',
    mediumCalories: 140,
    keywords: [
      'জুস',
      'চা',
      'কফি',
      'শরবত',
      'juice',
      'tea',
      'coffee',
      'drink',
      'shake',
    ],
  ),
];

const _customPortions = <_CustomPortion>[
  _CustomPortion(nameBn: 'ছোট', nameEn: 'Small', multiplier: 0.65),
  _CustomPortion(nameBn: 'মাঝারি', nameEn: 'Medium', multiplier: 1),
  _CustomPortion(nameBn: 'বড়', nameEn: 'Large', multiplier: 1.4),
];

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({
    required this.isBangla,
    required this.targetCaloriesMin,
    required this.targetCaloriesMax,
    super.key,
  });

  final bool isBangla;
  final int targetCaloriesMin;
  final int targetCaloriesMax;

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final List<_DailyLogEntry> _entries = [];
  int _selectedWaterGlasses = 1;

  int get _calories => _entries
      .where((entry) => entry.type == _LogType.meal)
      .fold(0, (total, entry) => total + entry.amount.round());

  int get _waterGlasses => _entries
      .where((entry) => entry.type == _LogType.water)
      .fold(0, (total, entry) => total + entry.amount.round());

  int get _exerciseMinutes => _entries
      .where((entry) => entry.type == _LogType.exercise)
      .fold(0, (total, entry) => total + entry.amount.round());

  double get _sleepHours => _entries
      .where((entry) => entry.type == _LogType.sleep)
      .fold(0, (total, entry) => total + entry.amount);

  String _amountText(_DailyLogEntry entry) {
    switch (entry.type) {
      case _LogType.meal:
        return '≈ ${entry.amount.round()} kcal';
      case _LogType.water:
        final glasses = entry.amount.round();
        return widget.isBangla
            ? '$glasses গ্লাস'
            : '$glasses ${glasses == 1 ? 'glass' : 'glasses'}';
      case _LogType.exercise:
        return widget.isBangla
            ? '${entry.amount.round()} মিনিট'
            : '${entry.amount.round()} min';
      case _LogType.sleep:
        return widget.isBangla
            ? '${entry.amount.toStringAsFixed(1)} ঘণ্টা'
            : '${entry.amount.toStringAsFixed(1)} hours';
    }
  }

  IconData _typeIcon(_LogType type) {
    switch (type) {
      case _LogType.meal:
        return Icons.restaurant;
      case _LogType.water:
        return Icons.water_drop;
      case _LogType.exercise:
        return Icons.directions_run;
      case _LogType.sleep:
        return Icons.bedtime;
    }
  }

  void _insertEntry(_DailyLogEntry entry) {
    setState(() {
      if (entry.type == _LogType.sleep) {
        _entries.removeWhere((item) => item.type == _LogType.sleep);
      }
      _entries.insert(0, entry);
    });
  }

  Future<void> _showFoodPicker() async {
    final entry = await Navigator.of(context).push<_DailyLogEntry>(
      MaterialPageRoute(
        builder: (context) => _FoodPickerScreen(isBangla: widget.isBangla),
      ),
    );

    if (entry != null && mounted) {
      _insertEntry(entry);
    }
  }

  void _addWater() {
    final glasses = _selectedWaterGlasses;

    setState(() {
      _entries.insert(
        0,
        _DailyLogEntry(
          type: _LogType.water,
          title: widget.isBangla ? 'পানি' : 'Water',
          amount: glasses.toDouble(),
          details: widget.isBangla ? 'আজ' : 'Today',
        ),
      );
      _selectedWaterGlasses = 1;
    });
  }

  void _decreaseWater() {
    if (_selectedWaterGlasses <= 1) {
      return;
    }

    setState(() {
      _selectedWaterGlasses--;
    });
  }

  void _increaseWater() {
    if (_selectedWaterGlasses >= 20) {
      return;
    }

    setState(() {
      _selectedWaterGlasses++;
    });
  }

  Future<void> _showExercisePicker() async {
    final namesBn = ['হাঁটা', 'দৌড়', 'সাইক্লিং', 'যোগব্যায়াম', 'শক্তি ব্যায়াম'];
    final namesEn = ['Walking', 'Running', 'Cycling', 'Yoga', 'Strength'];
    final minuteOptions = [10, 15, 20, 30, 45, 60];
    var selectedActivity = 0;
    var selectedMinutes = 30;

    final entry = await showModalBottomSheet<_DailyLogEntry>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBangla ? 'ব্যায়াম যোগ করুন' : 'Add exercise',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.isBangla ? 'ব্যায়ামের ধরন' : 'Exercise type'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(namesBn.length, (index) {
                        return ChoiceChip(
                          label: Text(
                            widget.isBangla ? namesBn[index] : namesEn[index],
                          ),
                          selected: selectedActivity == index,
                          onSelected: (_) {
                            setSheetState(() {
                              selectedActivity = index;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Text(widget.isBangla ? 'সময়' : 'Duration'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: minuteOptions.map((minutes) {
                        return ChoiceChip(
                          label: Text(
                            widget.isBangla ? '$minutes মিনিট' : '$minutes min',
                          ),
                          selected: selectedMinutes == minutes,
                          onSelected: (_) {
                            setSheetState(() {
                              selectedMinutes = minutes;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                            _DailyLogEntry(
                              type: _LogType.exercise,
                              title: widget.isBangla
                                  ? namesBn[selectedActivity]
                                  : namesEn[selectedActivity],
                              amount: selectedMinutes.toDouble(),
                              details: widget.isBangla ? 'ব্যায়াম' : 'Exercise',
                            ),
                          );
                        },
                        child: Text(widget.isBangla ? 'যোগ করুন' : 'Add'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (entry != null && mounted) {
      _insertEntry(entry);
    }
  }

  Future<void> _showSleepPicker() async {
    final hourOptions = [5.0, 6.0, 7.0, 7.5, 8.0, 9.0];
    var selectedHours = 8.0;

    final entry = await showModalBottomSheet<_DailyLogEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBangla ? 'ঘুম যোগ করুন' : 'Add sleep',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isBangla
                          ? 'গত রাতে কত ঘণ্টা ঘুমিয়েছেন?'
                          : 'How many hours did you sleep last night?',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hourOptions.map((hours) {
                        final hourText = hours == hours.roundToDouble()
                            ? hours.round().toString()
                            : hours.toStringAsFixed(1);

                        return ChoiceChip(
                          label: Text(
                            widget.isBangla
                                ? '$hourText ঘণ্টা'
                                : '$hourText hours',
                          ),
                          selected: selectedHours == hours,
                          onSelected: (_) {
                            setSheetState(() {
                              selectedHours = hours;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.isBangla
                          ? 'নিজের সময় ঠিক করুন: ${selectedHours.toStringAsFixed(1)} ঘণ্টা'
                          : 'Set your own time: ${selectedHours.toStringAsFixed(1)} hours',
                    ),
                    Slider(
                      value: selectedHours,
                      min: 0.5,
                      max: 24,
                      divisions: 47,
                      label: selectedHours.toStringAsFixed(1),
                      onChanged: (value) {
                        setSheetState(() {
                          selectedHours = value;
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                            _DailyLogEntry(
                              type: _LogType.sleep,
                              title: widget.isBangla ? 'ঘুম' : 'Sleep',
                              amount: selectedHours,
                              details: widget.isBangla
                                  ? 'গত রাত'
                                  : 'Last night',
                            ),
                          );
                        },
                        child: Text(widget.isBangla ? 'যোগ করুন' : 'Add'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (entry != null && mounted) {
      _insertEntry(entry);
    }
  }

  Future<void> _deleteEntry(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.isBangla ? 'এন্ট্রি মুছবেন?' : 'Delete entry?'),
        content: Text(
          widget.isBangla
              ? 'এই Daily Log এন্ট্রিটি সরানো হবে।'
              : 'This Daily Log entry will be removed.',
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
      ),
    );

    if (shouldDelete == true && mounted && index < _entries.length) {
      setState(() {
        _entries.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final calorieProgress = widget.targetCaloriesMax <= 0
        ? 0.0
        : (_calories / widget.targetCaloriesMax).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.isBangla ? 'দৈনিক লগ' : 'Daily log'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              widget.isBangla ? 'আজকের সারাংশ' : 'Today’s summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: [
                        _SummaryItem(
                          icon: Icons.local_fire_department,
                          value: '$_calories',
                          label: 'kcal',
                        ),
                        _SummaryItem(
                          icon: Icons.water_drop,
                          value: '$_waterGlasses',
                          label: widget.isBangla ? 'গ্লাস' : 'glasses',
                        ),
                        _SummaryItem(
                          icon: Icons.directions_run,
                          value: '$_exerciseMinutes',
                          label: widget.isBangla ? 'মিনিট' : 'minutes',
                        ),
                        _SummaryItem(
                          icon: Icons.bedtime,
                          value: _sleepHours.toStringAsFixed(1),
                          label: widget.isBangla ? 'ঘণ্টা' : 'hours',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: calorieProgress,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isBangla
                          ? 'ক্যালরি লক্ষ্য: ${widget.targetCaloriesMin}–${widget.targetCaloriesMax} kcal'
                          : 'Calorie target: ${widget.targetCaloriesMin}–${widget.targetCaloriesMax} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isBangla ? 'দ্রুত যোগ করুন' : 'Quick add',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.65,
              children: [
                _QuickActionCard(
                  icon: Icons.restaurant,
                  label: widget.isBangla ? 'খাবার' : 'Meal',
                  helper: widget.isBangla
                      ? 'খাবার, পরিমাণ ও সময়'
                      : 'Food, portion and time',
                  onTap: _showFoodPicker,
                ),
                _WaterSelectorCard(
                  isBangla: widget.isBangla,
                  glasses: _selectedWaterGlasses,
                  onDecrease: _selectedWaterGlasses > 1 ? _decreaseWater : null,
                  onIncrease: _selectedWaterGlasses < 20
                      ? _increaseWater
                      : null,
                  onAdd: _addWater,
                ),
                _QuickActionCard(
                  icon: Icons.directions_run,
                  label: widget.isBangla ? 'ব্যায়াম' : 'Exercise',
                  helper: widget.isBangla ? 'ধরন ও সময়' : 'Type and duration',
                  onTap: _showExercisePicker,
                ),
                _QuickActionCard(
                  icon: Icons.bedtime,
                  label: widget.isBangla ? 'ঘুম' : 'Sleep',
                  helper: widget.isBangla
                      ? 'পছন্দ বা নিজের সময়'
                      : 'Preset or custom time',
                  onTap: _showSleepPicker,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.isBangla ? 'আজকের এন্ট্রি' : 'Today’s entries',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_entries.isEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 42,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.isBangla
                            ? 'আজ এখনো কোনো তথ্য যোগ করা হয়নি।'
                            : 'No information has been added today.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_entries.length, (index) {
                final entry = _entries[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_typeIcon(entry.type))),
                    title: Text(entry.title),
                    subtitle: Text(entry.details),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _amountText(entry),
                          style: theme.textTheme.labelLarge,
                        ),
                        IconButton(
                          tooltip: widget.isBangla ? 'মুছুন' : 'Delete',
                          onPressed: () => _deleteEntry(index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _FoodPickerScreen extends StatefulWidget {
  const _FoodPickerScreen({required this.isBangla});

  final bool isBangla;

  @override
  State<_FoodPickerScreen> createState() => _FoodPickerScreenState();
}

class _FoodPickerScreenState extends State<_FoodPickerScreen> {
  final _searchController = TextEditingController();
  final _customNameController = TextEditingController();

  _FoodItem? _selectedFood;
  _FoodPortion? _selectedKnownPortion;
  _MealTime? _selectedMealTime;
  var _query = '';
  var _showCustomFood = false;
  var _customCategoryIndex = 0;
  var _customPortionIndex = 1;
  var _categoryChosenManually = false;
  var _showCustomValidation = false;

  String _foodName(_FoodItem food) =>
      widget.isBangla ? food.nameBn : food.nameEn;

  String _portionName(_FoodPortion portion) =>
      widget.isBangla ? portion.nameBn : portion.nameEn;

  String _categoryName(_CustomFoodCategory category) =>
      widget.isBangla ? category.nameBn : category.nameEn;

  String _customPortionName(_CustomPortion portion) =>
      widget.isBangla ? portion.nameBn : portion.nameEn;

  String _mealTimeName(_MealTime mealTime) {
    switch (mealTime) {
      case _MealTime.morning:
        return widget.isBangla ? 'সকাল' : 'Morning';
      case _MealTime.noon:
        return widget.isBangla ? 'দুপুর' : 'Noon';
      case _MealTime.afternoon:
        return widget.isBangla ? 'বিকাল' : 'Afternoon';
      case _MealTime.night:
        return widget.isBangla ? 'রাত' : 'Night';
    }
  }

  IconData _mealTimeIcon(_MealTime mealTime) {
    switch (mealTime) {
      case _MealTime.morning:
        return Icons.wb_sunny_outlined;
      case _MealTime.noon:
        return Icons.light_mode_outlined;
      case _MealTime.afternoon:
        return Icons.wb_twilight_outlined;
      case _MealTime.night:
        return Icons.nightlight_outlined;
    }
  }

  int get _estimatedCustomCalories {
    final category = _customFoodCategories[_customCategoryIndex];
    final portion = _customPortions[_customPortionIndex];
    return (category.mediumCalories * portion.multiplier).round();
  }

  void _updateCustomFoodName(String value) {
    var detectedIndex = -1;

    if (!_categoryChosenManually) {
      final normalizedName = value.trim().toLowerCase();
      detectedIndex = _customFoodCategories.indexWhere(
        (category) => category.keywords.any(
          (keyword) => normalizedName.contains(keyword),
        ),
      );
    }

    setState(() {
      if (detectedIndex >= 0) {
        _customCategoryIndex = detectedIndex;
      }
    });
  }

  void _openCustomFood() {
    final searchedName = _searchController.text.trim();

    setState(() {
      _showCustomFood = true;
      _selectedFood = null;
      _selectedKnownPortion = null;
      _customNameController.text = searchedName;
      _categoryChosenManually = false;
      _showCustomValidation = false;
    });

    _updateCustomFoodName(searchedName);
  }

  void _addCustomFood() {
    final foodName = _customNameController.text.trim();
    if (foodName.isEmpty || _selectedMealTime == null) {
      setState(() {
        _showCustomValidation = true;
      });
      return;
    }

    final category = _customFoodCategories[_customCategoryIndex];
    final portion = _customPortions[_customPortionIndex];
    final mealTime = _selectedMealTime!;

    Navigator.pop(
      context,
      _DailyLogEntry(
        type: _LogType.meal,
        title: foodName,
        amount: _estimatedCustomCalories.toDouble(),
        details:
            '${_mealTimeName(mealTime)} • ${_customPortionName(portion)} • ${_categoryName(category)}',
      ),
    );
  }

  void _addKnownFood() {
    final selectedFood = _selectedFood;
    final selectedPortion = _selectedKnownPortion;
    final mealTime = _selectedMealTime;

    if (selectedFood == null || selectedPortion == null || mealTime == null) {
      return;
    }

    Navigator.pop(
      context,
      _DailyLogEntry(
        type: _LogType.meal,
        title: _foodName(selectedFood),
        amount: selectedPortion.calories.toDouble(),
        details:
            '${_mealTimeName(mealTime)} • ${_portionName(selectedPortion)}',
      ),
    );
  }

  Widget _buildMealTimeSelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isBangla ? 'কোন বেলার খাবার?' : 'When did you eat this?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isBangla
              ? 'সময়টি আপনি নিজে নির্বাচন করুন।'
              : 'Choose the meal time yourself.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _MealTime.values.map((mealTime) {
            return ChoiceChip(
              avatar: Icon(_mealTimeIcon(mealTime), size: 18),
              label: Text(_mealTimeName(mealTime)),
              selected: _selectedMealTime == mealTime,
              onSelected: (_) {
                setState(() {
                  _selectedMealTime = mealTime;
                  _showCustomValidation = false;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBangla ? 'খাবার যোগ করুন' : 'Add food'),
      ),
      body: SafeArea(
        child: _selectedFood != null
            ? _buildKnownFoodPortions()
            : _showCustomFood
            ? _buildCustomFoodForm()
            : _buildFoodList(),
      ),
    );
  }

  Widget _buildFoodList() {
    final filteredFoods = _foods.where((food) {
      final normalizedQuery = _query.trim().toLowerCase();
      return normalizedQuery.isEmpty ||
          food.nameBn.contains(normalizedQuery) ||
          food.nameEn.toLowerCase().contains(normalizedQuery);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isBangla
                ? 'তালিকা থেকে খাবার বেছে নিন'
                : 'Choose a food from the list',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isBangla
                ? 'ক্যালরি আনুমানিক—রান্না ও পরিমাণ অনুযায়ী বদলাতে পারে।'
                : 'Calories are estimates and vary by recipe and portion.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: widget.isBangla ? 'খাবার খুঁজুন' : 'Search food',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredFoods.isEmpty
                ? Center(
                    child: Text(
                      widget.isBangla
                          ? 'তালিকায় খাবারটি পাওয়া যায়নি।'
                          : 'The food was not found in the list.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filteredFoods.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.restaurant),
                        ),
                        title: Text(_foodName(food)),
                        subtitle: Text(
                          widget.isBangla ? food.nameEn : food.nameBn,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          setState(() {
                            _selectedFood = food;
                            _selectedKnownPortion = null;
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openCustomFood,
              icon: const Icon(Icons.add),
              label: Text(
                widget.isBangla
                    ? 'তালিকার বাইরে খাবার যোগ করুন'
                    : 'Add a food outside the list',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnownFoodPortions() {
    final selectedFood = _selectedFood!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              _selectedFood = null;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: Text(
            widget.isBangla ? 'অন্য খাবার বেছে নিন' : 'Choose another food',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _foodName(selectedFood),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          widget.isBangla
              ? 'সময় ও পরিমাণ নির্বাচন করে খাবারটি যোগ করুন।'
              : 'Choose the time and portion, then add the food.',
        ),
        const SizedBox(height: 18),
        _buildMealTimeSelector(),
        const SizedBox(height: 22),
        Text(
          widget.isBangla ? 'পরিমাণ' : 'Portion',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...selectedFood.portions.map((portion) {
          final isSelected = _selectedKnownPortion == portion;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(_portionName(portion)),
              subtitle: Text('≈ ${portion.calories} kcal'),
              trailing: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onTap: () {
                setState(() {
                  _selectedKnownPortion = portion;
                });
              },
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _selectedMealTime != null && _selectedKnownPortion != null
                ? _addKnownFood
                : null,
            child: Text(widget.isBangla ? 'খাবার যোগ করুন' : 'Add food'),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomFoodForm() {
    final selectedCategory = _customFoodCategories[_customCategoryIndex];
    final selectedPortion = _customPortions[_customPortionIndex];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showCustomFood = false;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: Text(
            widget.isBangla ? 'খাবারের তালিকায় ফিরুন' : 'Back to food list',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isBangla ? 'নিজের খাবার যোগ করুন' : 'Add your own food',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          widget.isBangla
              ? 'খাবারের নাম লিখুন। অ্যাপ নাম থেকে ধরন বোঝার চেষ্টা করবে; প্রয়োজন হলে আপনি ধরনটি ঠিক করে দিন।'
              : 'Enter the food name. The app will try to detect its type; correct the type if needed.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _customNameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: _updateCustomFoodName,
          decoration: InputDecoration(
            labelText: widget.isBangla ? 'খাবারের নাম' : 'Food name',
            hintText: widget.isBangla
                ? 'যেমন: চিকেন স্যান্ডউইচ'
                : 'For example: Chicken sandwich',
            border: const OutlineInputBorder(),
          ),
        ),
        if (_showCustomValidation &&
            _customNameController.text.trim().isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.isBangla ? 'খাবারের নাম লিখুন।' : 'Enter the food name.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        _buildMealTimeSelector(),
        if (_showCustomValidation && _selectedMealTime == null) ...[
          const SizedBox(height: 6),
          Text(
            widget.isBangla
                ? 'সকাল, দুপুর, বিকাল বা রাত—একটি সময় নির্বাচন করুন।'
                : 'Select morning, noon, afternoon, or night.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          widget.isBangla ? 'খাবারের ধরন' : 'Food type',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_customFoodCategories.length, (index) {
            final category = _customFoodCategories[index];

            return ChoiceChip(
              label: Text(_categoryName(category)),
              selected: _customCategoryIndex == index,
              onSelected: (_) {
                setState(() {
                  _customCategoryIndex = index;
                  _categoryChosenManually = true;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 20),
        Text(
          widget.isBangla ? 'পরিমাণ' : 'Portion',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_customPortions.length, (index) {
            final portion = _customPortions[index];

            return ChoiceChip(
              label: Text(_customPortionName(portion)),
              selected: _customPortionIndex == index,
              onSelected: (_) {
                setState(() {
                  _customPortionIndex = index;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isBangla
                            ? 'আনুমানিক ক্যালরি'
                            : 'Estimated calories',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '≈ $_estimatedCustomCalories kcal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_categoryName(selectedCategory)} • ${_customPortionName(selectedPortion)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isBangla
              ? 'এটি খাবারের ধরন ও পরিমাণভিত্তিক একটি আনুমানিক হিসাব। রেসিপি ও তেলের পরিমাণে ফল বদলাতে পারে।'
              : 'This is an estimate based on food type and portion. Recipe and oil can change the result.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _addCustomFood,
            child: Text(widget.isBangla ? 'খাবার যোগ করুন' : 'Add food'),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
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
                style: theme.textTheme.titleMedium?.copyWith(
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

class _WaterSelectorCard extends StatelessWidget {
  const _WaterSelectorCard({
    required this.isBangla,
    required this.glasses,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAdd,
  });

  final bool isBangla;
  final int glasses;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 21, color: colorScheme.primary),
                const SizedBox(width: 5),
                Text(
                  isBangla ? 'পানি' : 'Water',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  onPressed: onDecrease,
                  tooltip: isBangla ? 'কমিয়ে দিন' : 'Decrease',
                  icon: const Icon(Icons.remove, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    '$glasses',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: onIncrease,
                  tooltip: isBangla ? 'বাড়িয়ে দিন' : 'Increase',
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                ),
                const SizedBox(width: 5),
                IconButton.filled(
                  onPressed: onAdd,
                  tooltip: isBangla
                      ? '$glasses গ্লাস যোগ করুন'
                      : 'Add $glasses glasses',
                  icon: const Icon(Icons.check, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.helper,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                helper,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
