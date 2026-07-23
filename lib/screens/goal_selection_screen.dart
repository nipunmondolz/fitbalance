import 'package:flutter/material.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({
    required this.isBangla,
    required this.age,
    required this.gender,
    required this.heightInCm,
    required this.weightInKg,
    super.key,
  });

  final bool isBangla;
  final int age;
  final String gender;
  final double heightInCm;
  final double weightInKg;

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String? _selectedGoal;

  void _continue() {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'অনুগ্রহ করে আপনার লক্ষ্য নির্বাচন করুন'
                  : 'Please select your goal',
            ),
          ),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla
                ? 'আপনার লক্ষ্য সফলভাবে সংরক্ষণ করা হয়েছে'
                : 'Your goal has been saved successfully',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = widget.isBangla;
    final colorScheme = Theme.of(context).colorScheme;

    final goals = [
      _GoalOption(
        value: 'lose_weight',
        icon: Icons.trending_down,
        title: isBangla ? 'ওজন কমানো' : 'Lose weight',
        description: isBangla
            ? 'স্বাস্থ্যকরভাবে শরীরের অতিরিক্ত ওজন কমান'
            : 'Reduce excess body weight in a healthy way',
      ),
      _GoalOption(
        value: 'gain_weight',
        icon: Icons.trending_up,
        title: isBangla ? 'ওজন বাড়ানো' : 'Gain weight',
        description: isBangla
            ? 'স্বাস্থ্যকর উপায়ে প্রয়োজনীয় ওজন অর্জন করুন'
            : 'Reach a healthy weight in a balanced way',
      ),
      _GoalOption(
        value: 'maintain_weight',
        icon: Icons.balance,
        title: isBangla ? 'বর্তমান ওজন বজায় রাখা' : 'Maintain weight',
        description: isBangla
            ? 'বর্তমান স্বাস্থ্যকর ওজন ধরে রাখুন'
            : 'Keep your current healthy body weight',
      ),
      _GoalOption(
        value: 'improve_fitness',
        icon: Icons.fitness_center,
        title: isBangla
            ? 'ফিটনেস ও সুস্থতা উন্নত করা'
            : 'Improve fitness and wellness',
        description: isBangla
            ? 'শক্তি, সহনশীলতা ও সার্বিক সুস্থতা বাড়ান'
            : 'Improve strength, endurance, and overall wellness',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(isBangla ? 'আপনার লক্ষ্য' : 'Your goal')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.flag_outlined, size: 72, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                isBangla
                    ? 'আপনার প্রধান লক্ষ্য কী?'
                    : 'What is your main goal?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isBangla
                    ? 'আপনার জন্য উপযুক্ত স্বাস্থ্য পরিকল্পনা তৈরির জন্য একটি লক্ষ্য নির্বাচন করুন।'
                    : 'Select one goal so we can prepare a suitable health plan for you.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              ...goals.map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _GoalCard(
                    goal: goal,
                    isSelected: _selectedGoal == goal.value,
                    onTap: () {
                      setState(() {
                        _selectedGoal = goal.value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isBangla
                            ? 'আপনি পরবর্তীতে অ্যাপের সেটিংস থেকে এই লক্ষ্য পরিবর্তন করতে পারবেন।'
                            : 'You can change this goal later from the app settings.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _continue,
                  child: Text(
                    isBangla ? 'এগিয়ে যান' : 'Continue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption {
  const _GoalOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String value;
  final IconData icon;
  final String title;
  final String description;
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  final _GoalOption goal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  goal.icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      goal.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
