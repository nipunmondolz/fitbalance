import 'package:flutter/material.dart';

import '../services/habit_storage_service.dart';
import '../services/notification_service.dart';

class HabitEngineScreen extends StatefulWidget {
  const HabitEngineScreen({required this.isBangla, super.key});

  final bool isBangla;

  @override
  State<HabitEngineScreen> createState() => _HabitEngineScreenState();
}

class _HabitEngineScreenState extends State<HabitEngineScreen> {
  List<bool> _completedHabits = [false, false, false];

  List<_HabitReminder> _habitReminders = const [
    _HabitReminder(enabled: false, time: TimeOfDay(hour: 9, minute: 0)),
    _HabitReminder(enabled: false, time: TimeOfDay(hour: 18, minute: 0)),
    _HabitReminder(enabled: false, time: TimeOfDay(hour: 22, minute: 30)),
  ];

  _CheckInMood? _checkInMood;
  int? _energyLevel;
  String _checkInNote = '';

  int get _completedCount =>
      _completedHabits.where((isCompleted) => isCompleted).length;

  double get _progress => _completedCount / _completedHabits.length;

  bool get _hasCheckIn => _checkInMood != null && _energyLevel != null;

  int get _activeReminderCount =>
      _habitReminders.where((reminder) => reminder.enabled).length;

  @override
  void initState() {
    super.initState();
    _loadTodayHabitData();
  }

  Future<void> _loadTodayHabitData() async {
    try {
      final completionsFuture = HabitStorageService.instance
          .loadTodayCompletions(_completedHabits.length);

      final checkInFuture = HabitStorageService.instance.loadTodayCheckIn();

      final remindersFuture = HabitStorageService.instance.loadHabitReminders(
        _habitReminders.length,
      );

      final savedCompletions = await completionsFuture;
      final savedCheckIn = await checkInFuture;
      final savedReminders = await remindersFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _completedHabits = savedCompletions;

        if (savedCheckIn != null &&
            savedCheckIn.moodIndex >= 0 &&
            savedCheckIn.moodIndex < _CheckInMood.values.length) {
          _checkInMood = _CheckInMood.values[savedCheckIn.moodIndex];
          _energyLevel = savedCheckIn.energyLevel;
          _checkInNote = savedCheckIn.note;
        }

        if (savedReminders != null) {
          _habitReminders = savedReminders
              .map(
                (reminder) => _HabitReminder(
                  enabled: reminder.enabled,
                  time: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
                ),
              )
              .toList(growable: false);
        }
      });
    } catch (_) {
      // Storage read ব্যর্থ হলে default state রাখা হবে।
    }
  }

  List<_HabitItem> get _habits => [
    _HabitItem(
      icon: Icons.water_drop_outlined,
      title: widget.isBangla ? 'পানির লক্ষ্য পূরণ' : 'Reach water goal',
      description: widget.isBangla
          ? 'আজকের প্রয়োজনীয় পানি পান করুন'
          : 'Drink your recommended water today',
    ),
    _HabitItem(
      icon: Icons.directions_walk_outlined,
      title: widget.isBangla
          ? '৩০ মিনিট সক্রিয় থাকুন'
          : 'Stay active for 30 minutes',
      description: widget.isBangla
          ? 'হাঁটা বা পছন্দের ব্যায়াম করুন'
          : 'Walk or do your preferred exercise',
    ),
    _HabitItem(
      icon: Icons.bedtime_outlined,
      title: widget.isBangla
          ? 'ঘুমের রুটিন অনুসরণ'
          : 'Follow your sleep routine',
      description: widget.isBangla
          ? 'সময়মতো ঘুমের প্রস্তুতি নিন'
          : 'Prepare to sleep at your planned time',
    ),
  ];

  Future<void> _toggleHabit(int index) async {
    final previousCompletions = List<bool>.of(_completedHabits);
    final updatedCompletions = List<bool>.of(_completedHabits);

    updatedCompletions[index] = !updatedCompletions[index];

    setState(() {
      _completedHabits = updatedCompletions;
    });

    try {
      await HabitStorageService.instance.saveTodayCompletions(
        updatedCompletions,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _completedHabits = previousCompletions;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla
                ? 'অভ্যাসের পরিবর্তন সংরক্ষণ করা যায়নি।'
                : 'The habit change could not be saved.',
          ),
        ),
      );
    }
  }

  String _moodName(_CheckInMood mood) {
    switch (mood) {
      case _CheckInMood.low:
        return widget.isBangla ? 'কঠিন দিন' : 'Difficult';
      case _CheckInMood.okay:
        return widget.isBangla ? 'মোটামুটি' : 'Okay';
      case _CheckInMood.good:
        return widget.isBangla ? 'ভালো' : 'Good';
      case _CheckInMood.great:
        return widget.isBangla ? 'দারুণ' : 'Great';
    }
  }

  Future<void> _showReminderSettings() async {
    final result = await Navigator.of(context).push<List<_HabitReminder>>(
      MaterialPageRoute(
        builder: (context) => _ReminderSettingsScreen(
          isBangla: widget.isBangla,
          habits: _habits,
          initialReminders: _habitReminders,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _habitReminders = result;
    });
  }

  Future<void> _showDailyCheckIn() async {
    final result = await showModalBottomSheet<_DailyCheckInResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _DailyCheckInSheet(
        isBangla: widget.isBangla,
        initialMood: _checkInMood,
        initialEnergyLevel: _energyLevel,
        initialNote: _checkInNote,
        isEditing: _hasCheckIn,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final previousMood = _checkInMood;
    final previousEnergyLevel = _energyLevel;
    final previousNote = _checkInNote;

    setState(() {
      _checkInMood = result.mood;
      _energyLevel = result.energyLevel;
      _checkInNote = result.note;
    });

    try {
      await HabitStorageService.instance.saveTodayCheckIn(
        moodIndex: result.mood.index,
        energyLevel: result.energyLevel,
        note: result.note,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _checkInMood = previousMood;
        _energyLevel = previousEnergyLevel;
        _checkInNote = previousNote;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla
                ? 'দৈনিক চেক-ইন সংরক্ষণ করা যায়নি।'
                : 'The daily check-in could not be saved.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBangla = widget.isBangla;
    final habits = _habits;

    final reminderDescription = _activeReminderCount == 0
        ? (isBangla
              ? 'প্রয়োজনীয় সময়ে অভ্যাসের রিমাইন্ডার ঠিক করুন।'
              : 'Set reminders for your habits at useful times.')
        : (isBangla
              ? '$_activeReminderCountটি অভ্যাসের রিমাইন্ডার চালু আছে।'
              : '$_activeReminderCount habit reminder${_activeReminderCount == 1 ? '' : 's'} enabled.');

    final checkInDescription = _hasCheckIn
        ? (isBangla
              ? 'মুড: ${_moodName(_checkInMood!)} • শক্তি: $_energyLevel/৫'
              : 'Mood: ${_moodName(_checkInMood!)} • Energy: $_energyLevel/5')
        : (isBangla
              ? 'আজকের অনুভূতি ও শক্তির মাত্রা সংরক্ষণ করুন।'
              : 'Save today’s mood and energy level.');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isBangla ? 'অভ্যাস' : 'Habits'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              isBangla
                  ? 'ছোট অভ্যাস, নিয়মিত অগ্রগতি'
                  : 'Small habits, steady progress',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isBangla
                  ? 'প্রতিদিনের স্বাস্থ্যকর কাজগুলো এখানে অনুসরণ করুন।'
                  : 'Follow your daily healthy actions here.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isBangla ? 'আজকের অভ্যাস' : "Today's habits",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          isBangla
                              ? '$_completedCount / ${habits.length} সম্পন্ন'
                              : '$_completedCount / ${habits.length} completed',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(habits.length, (index) {
                      final habit = habits[index];
                      final isCompleted = _completedHabits[index];

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => _toggleHabit(index),
                            leading: CircleAvatar(
                              backgroundColor: isCompleted
                                  ? colorScheme.primaryContainer
                                  : colorScheme.secondaryContainer,
                              child: Icon(
                                habit.icon,
                                color: isCompleted
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSecondaryContainer,
                              ),
                            ),
                            title: Text(
                              habit.title,
                              style: isCompleted
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                    )
                                  : null,
                            ),
                            subtitle: Text(habit.description),
                            trailing: IconButton(
                              tooltip: isCompleted
                                  ? (isBangla
                                        ? 'অসম্পন্ন হিসেবে চিহ্নিত করুন'
                                        : 'Mark as incomplete')
                                  : (isBangla
                                        ? 'সম্পন্ন হিসেবে চিহ্নিত করুন'
                                        : 'Mark as completed'),
                              onPressed: () => _toggleHabit(index),
                              icon: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isCompleted
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (index != habits.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _PreviewCard(
              icon: Icons.notifications_none,
              title: isBangla ? 'রিমাইন্ডার' : 'Reminders',
              description: reminderDescription,
              status: _activeReminderCount == 0
                  ? (isBangla ? 'রিমাইন্ডার সেট করুন' : 'Set reminders')
                  : (isBangla
                        ? 'রিমাইন্ডার পরিবর্তন করুন'
                        : 'Manage reminders'),
              onTap: _showReminderSettings,
            ),
            const SizedBox(height: 12),
            _PreviewCard(
              icon: Icons.fact_check_outlined,
              title: isBangla ? 'দৈনিক চেক-ইন' : 'Daily check-in',
              description: checkInDescription,
              status: _hasCheckIn
                  ? (isBangla ? 'চেক-ইন পরিবর্তন করুন' : 'Edit check-in')
                  : (isBangla ? 'চেক-ইন করুন' : 'Check in now'),
              onTap: _showDailyCheckIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSettingsScreen extends StatefulWidget {
  const _ReminderSettingsScreen({
    required this.isBangla,
    required this.habits,
    required this.initialReminders,
  });

  final bool isBangla;
  final List<_HabitItem> habits;
  final List<_HabitReminder> initialReminders;

  @override
  State<_ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<_ReminderSettingsScreen> {
  late List<_HabitReminder> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List<_HabitReminder>.of(widget.initialReminders);
  }

  Future<void> _selectTime(int index) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _reminders[index].time,
      helpText: widget.isBangla ? 'রিমাইন্ডারের সময়' : 'Reminder time',
      cancelText: widget.isBangla ? 'বাতিল' : 'Cancel',
      confirmText: widget.isBangla ? 'ঠিক আছে' : 'OK',
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _reminders[index] = _reminders[index].copyWith(time: selectedTime);
    });
  }

  void _toggleReminder(int index, bool enabled) {
    setState(() {
      _reminders[index] = _reminders[index].copyWith(enabled: enabled);
    });
  }

  Future<void> _save() async {
    final hasEnabledReminder = _reminders.any((reminder) => reminder.enabled);

    if (hasEnabledReminder) {
      try {
        final permissionsGranted = await NotificationService.instance
            .requestSchedulingPermissions();

        if (!mounted) {
          return;
        }

        if (!permissionsGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isBangla
                    ? 'রিমাইন্ডারের জন্য Notification এবং Alarms & reminders permission প্রয়োজন।'
                    : 'Notification and Alarms & reminders permissions are required.',
              ),
            ),
          );
          return;
        }
      } catch (_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'Notification permission চালু করা যায়নি। আবার চেষ্টা করুন।'
                  : 'Notification permissions could not be enabled. Try again.',
            ),
          ),
        );
        return;
      }
    }

    try {
      for (var index = 0; index < _reminders.length; index++) {
        final reminder = _reminders[index];
        final notificationId = 1000 + index;

        if (reminder.enabled) {
          await NotificationService.instance.scheduleDailyHabitReminder(
            id: notificationId,
            hour: reminder.time.hour,
            minute: reminder.time.minute,
            title: widget.habits[index].title,
            body: widget.isBangla
                ? 'আজকের স্বাস্থ্যকর অভ্যাসটি সম্পন্ন করুন।'
                : 'Complete this healthy habit for today.',
          );
        } else {
          await NotificationService.instance.cancelHabitReminder(
            notificationId,
          );
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla
                ? 'রিমাইন্ডার schedule করা যায়নি। আবার চেষ্টা করুন।'
                : 'The reminders could not be scheduled. Try again.',
          ),
        ),
      );
      return;
    }

    try {
      await HabitStorageService.instance.saveHabitReminders(
        _reminders
            .map(
              (reminder) => StoredHabitReminder(
                enabled: reminder.enabled,
                hour: reminder.time.hour,
                minute: reminder.time.minute,
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla
                ? 'রিমাইন্ডার সেটিংস সংরক্ষণ করা যায়নি।'
                : 'The reminder settings could not be saved.',
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(List<_HabitReminder>.of(_reminders));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isBangla ? 'রিমাইন্ডার' : 'Reminders')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              widget.isBangla
                  ? 'অভ্যাসের সময় ঠিক করুন'
                  : 'Choose habit reminder times',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isBangla
                  ? 'প্রয়োজনীয় অভ্যাসের রিমাইন্ডার চালু করুন এবং সময় নির্বাচন করুন।'
                  : 'Enable the reminders you need and choose a time for each.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(widget.habits.length, (index) {
              final habit = widget.habits[index];
              final reminder = _reminders[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: reminder.enabled,
                        onChanged: (enabled) => _toggleReminder(index, enabled),
                        secondary: CircleAvatar(
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Icon(
                            habit.icon,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          habit.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          reminder.enabled
                              ? (widget.isBangla
                                    ? 'রিমাইন্ডার চালু আছে'
                                    : 'Reminder enabled')
                              : (widget.isBangla
                                    ? 'রিমাইন্ডার বন্ধ আছে'
                                    : 'Reminder disabled'),
                        ),
                      ),
                      if (reminder.enabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.isBangla
                                      ? 'রিমাইন্ডারের সময়'
                                      : 'Reminder time',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _selectTime(index),
                                icon: const Icon(Icons.schedule, size: 18),
                                label: Text(
                                  MaterialLocalizations.of(
                                    context,
                                  ).formatTimeOfDay(reminder.time),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            Card(
              margin: EdgeInsets.zero,
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isBangla
                            ? 'চালু করা রিমাইন্ডার প্রতিদিন নির্বাচিত সময়ে notification পাঠাবে।'
                            : 'Enabled reminders will send a notification every day at the selected time.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(
                  widget.isBangla
                      ? 'রিমাইন্ডার সংরক্ষণ করুন'
                      : 'Save reminders',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyCheckInSheet extends StatefulWidget {
  const _DailyCheckInSheet({
    required this.isBangla,
    required this.initialMood,
    required this.initialEnergyLevel,
    required this.initialNote,
    required this.isEditing,
  });

  final bool isBangla;
  final _CheckInMood? initialMood;
  final int? initialEnergyLevel;
  final String initialNote;
  final bool isEditing;

  @override
  State<_DailyCheckInSheet> createState() => _DailyCheckInSheetState();
}

class _DailyCheckInSheetState extends State<_DailyCheckInSheet> {
  late final TextEditingController _noteController;
  _CheckInMood? _selectedMood;
  int? _selectedEnergy;

  bool get _canSave => _selectedMood != null && _selectedEnergy != null;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
    _selectedEnergy = widget.initialEnergyLevel;
    _noteController = TextEditingController(text: widget.initialNote);
  }

  String _moodName(_CheckInMood mood) {
    switch (mood) {
      case _CheckInMood.low:
        return widget.isBangla ? 'কঠিন দিন' : 'Difficult';
      case _CheckInMood.okay:
        return widget.isBangla ? 'মোটামুটি' : 'Okay';
      case _CheckInMood.good:
        return widget.isBangla ? 'ভালো' : 'Good';
      case _CheckInMood.great:
        return widget.isBangla ? 'দারুণ' : 'Great';
    }
  }

  IconData _moodIcon(_CheckInMood mood) {
    switch (mood) {
      case _CheckInMood.low:
        return Icons.sentiment_dissatisfied_outlined;
      case _CheckInMood.okay:
        return Icons.sentiment_neutral_outlined;
      case _CheckInMood.good:
        return Icons.sentiment_satisfied_outlined;
      case _CheckInMood.great:
        return Icons.sentiment_very_satisfied_outlined;
    }
  }

  void _save() {
    final mood = _selectedMood;
    final energy = _selectedEnergy;

    if (mood == null || energy == null) {
      return;
    }

    Navigator.of(context).pop(
      _DailyCheckInResult(
        mood: mood,
        energyLevel: energy,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isBangla ? 'দৈনিক চেক-ইন' : 'Daily check-in',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isBangla
                  ? 'আজকের দিনটি কেমন যাচ্ছে তা সংরক্ষণ করুন।'
                  : 'Save how your day is going.',
            ),
            const SizedBox(height: 20),
            Text(
              widget.isBangla ? 'আজ কেমন লাগছে?' : 'How do you feel?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _CheckInMood.values.map((mood) {
                return ChoiceChip(
                  avatar: Icon(_moodIcon(mood), size: 18),
                  label: Text(_moodName(mood)),
                  selected: _selectedMood == mood,
                  onSelected: (_) {
                    setState(() {
                      _selectedMood = mood;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isBangla ? 'শক্তির মাত্রা' : 'Energy level',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isBangla
                  ? '১ মানে খুব কম, ৫ মানে অনেক ভালো।'
                  : '1 is very low and 5 is very good.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(5, (index) {
                final level = index + 1;

                return ChoiceChip(
                  label: Text('$level'),
                  selected: _selectedEnergy == level,
                  onSelected: (_) {
                    setState(() {
                      _selectedEnergy = level;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 180,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: widget.isBangla
                    ? 'ছোট নোট (ঐচ্ছিক)'
                    : 'Short note (optional)',
                hintText: widget.isBangla
                    ? 'আজকের দিন সম্পর্কে কিছু লিখুন'
                    : 'Write something about today',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(
                  widget.isEditing
                      ? (widget.isBangla
                            ? 'চেক-ইন আপডেট করুন'
                            : 'Update check-in')
                      : (widget.isBangla
                            ? 'চেক-ইন সংরক্ষণ করুন'
                            : 'Save check-in'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CheckInMood { low, okay, good, great }

class _DailyCheckInResult {
  const _DailyCheckInResult({
    required this.mood,
    required this.energyLevel,
    required this.note,
  });

  final _CheckInMood mood;
  final int energyLevel;
  final String note;
}

class _HabitReminder {
  const _HabitReminder({required this.enabled, required this.time});

  final bool enabled;
  final TimeOfDay time;

  _HabitReminder copyWith({bool? enabled, TimeOfDay? time}) {
    return _HabitReminder(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }
}

class _HabitItem {
  const _HabitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(icon, color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (onTap != null)
                          Icon(Icons.chevron_right, color: colorScheme.primary),
                      ],
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
