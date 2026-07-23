import 'package:flutter/material.dart';

class LifestyleAssessmentScreen extends StatefulWidget {
  const LifestyleAssessmentScreen({
    required this.isBangla,
    required this.age,
    required this.gender,
    required this.heightInCm,
    required this.weightInKg,
    required this.goal,
    super.key,
  });

  final bool isBangla;
  final int age;
  final String gender;
  final double heightInCm;
  final double weightInKg;
  final String goal;

  @override
  State<LifestyleAssessmentScreen> createState() =>
      _LifestyleAssessmentScreenState();
}

class _LifestyleAssessmentScreenState extends State<LifestyleAssessmentScreen> {
  String? _selectedSchedule;
  String? _selectedActivity;
  String? _selectedSleep;
  String? _selectedBudget;

  void _continue() {
    final hasUnansweredQuestion = [
      _selectedSchedule,
      _selectedActivity,
      _selectedSleep,
      _selectedBudget,
    ].any((answer) => answer == null);

    if (hasUnansweredQuestion) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'অনুগ্রহ করে সব প্রশ্নের উত্তর দিন'
                  : 'Please answer all the questions',
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
                ? 'জীবনযাপনের তথ্য সফলভাবে সংরক্ষণ করা হয়েছে'
                : 'Lifestyle information has been saved successfully',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = widget.isBangla;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBangla ? 'জীবনযাপন মূল্যায়ন' : 'Lifestyle assessment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.self_improvement,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isBangla ? 'আপনার দৈনন্দিন অভ্যাস' : 'Your daily habits',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isBangla
                    ? 'আপনার জন্য বাস্তবসম্মত স্বাস্থ্য পরিকল্পনা তৈরির জন্য নিচের প্রশ্নগুলোর উত্তর দিন।'
                    : 'Answer the following questions so we can prepare a realistic health plan for you.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 30),
              _LifestyleSection(
                title: isBangla
                    ? 'আপনার দৈনন্দিন সময়সূচি কেমন?'
                    : 'What is your daily schedule like?',
                selectedValue: _selectedSchedule,
                options: [
                  _LifestyleOption(
                    value: 'regular',
                    icon: Icons.event_available_outlined,
                    label: isBangla ? 'নিয়মিত সময়সূচি' : 'Regular schedule',
                  ),
                  _LifestyleOption(
                    value: 'irregular',
                    icon: Icons.shuffle,
                    label: isBangla ? 'অনিয়মিত সময়সূচি' : 'Irregular schedule',
                  ),
                  _LifestyleOption(
                    value: 'shift',
                    icon: Icons.nightlight_outlined,
                    label: isBangla
                        ? 'শিফট বা রাতের কাজ'
                        : 'Shift or night work',
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedSchedule = value;
                  });
                },
              ),
              const SizedBox(height: 28),
              _LifestyleSection(
                title: isBangla
                    ? 'আপনি কতটা শারীরিকভাবে সক্রিয়?'
                    : 'How physically active are you?',
                selectedValue: _selectedActivity,
                options: [
                  _LifestyleOption(
                    value: 'low',
                    icon: Icons.airline_seat_recline_normal,
                    label: isBangla
                        ? 'খুব কম বা কোনো ব্যায়াম নেই'
                        : 'Little or no exercise',
                  ),
                  _LifestyleOption(
                    value: 'light',
                    icon: Icons.directions_walk,
                    label: isBangla
                        ? 'সপ্তাহে ১–২ দিন ব্যায়াম'
                        : 'Exercise 1–2 days a week',
                  ),
                  _LifestyleOption(
                    value: 'moderate',
                    icon: Icons.directions_run,
                    label: isBangla
                        ? 'সপ্তাহে ৩–৫ দিন ব্যায়াম'
                        : 'Exercise 3–5 days a week',
                  ),
                  _LifestyleOption(
                    value: 'high',
                    icon: Icons.fitness_center,
                    label: isBangla
                        ? 'সপ্তাহে ৬–৭ দিন ব্যায়াম'
                        : 'Exercise 6–7 days a week',
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedActivity = value;
                  });
                },
              ),
              const SizedBox(height: 28),
              _LifestyleSection(
                title: isBangla
                    ? 'আপনি সাধারণত কত ঘণ্টা ঘুমান?'
                    : 'How long do you usually sleep?',
                selectedValue: _selectedSleep,
                options: [
                  _LifestyleOption(
                    value: 'less_than_6',
                    icon: Icons.bedtime_outlined,
                    label: isBangla ? '৬ ঘণ্টার কম' : 'Less than 6 hours',
                  ),
                  _LifestyleOption(
                    value: '6_to_7',
                    icon: Icons.bedtime_outlined,
                    label: isBangla ? '৬–৭ ঘণ্টা' : '6–7 hours',
                  ),
                  _LifestyleOption(
                    value: '7_to_9',
                    icon: Icons.bedtime_outlined,
                    label: isBangla ? '৭–৯ ঘণ্টা' : '7–9 hours',
                  ),
                  _LifestyleOption(
                    value: 'more_than_9',
                    icon: Icons.bedtime_outlined,
                    label: isBangla ? '৯ ঘণ্টার বেশি' : 'More than 9 hours',
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedSleep = value;
                  });
                },
              ),
              const SizedBox(height: 28),
              _LifestyleSection(
                title: isBangla
                    ? 'খাবারের পরিকল্পনায় আপনার বাজেট কেমন?'
                    : 'What is your food-plan budget?',
                selectedValue: _selectedBudget,
                options: [
                  _LifestyleOption(
                    value: 'budget_friendly',
                    icon: Icons.savings_outlined,
                    label: isBangla ? 'সাশ্রয়ী পরিকল্পনা' : 'Budget-friendly',
                  ),
                  _LifestyleOption(
                    value: 'moderate',
                    icon: Icons.account_balance_wallet_outlined,
                    label: isBangla ? 'মাঝারি বাজেট' : 'Moderate budget',
                  ),
                  _LifestyleOption(
                    value: 'flexible',
                    icon: Icons.payments_outlined,
                    label: isBangla ? 'বাজেট নমনীয়' : 'Flexible budget',
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedBudget = value;
                  });
                },
              ),
              const SizedBox(height: 32),
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

class _LifestyleOption {
  const _LifestyleOption({
    required this.value,
    required this.icon,
    required this.label,
  });

  final String value;
  final IconData icon;
  final String label;
}

class _LifestyleSection extends StatelessWidget {
  const _LifestyleSection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<_LifestyleOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LifestyleOptionTile(
              option: option,
              isSelected: selectedValue == option.value,
              onTap: () => onSelected(option.value),
            ),
          ),
        ),
      ],
    );
  }
}

class _LifestyleOptionTile extends StatelessWidget {
  const _LifestyleOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _LifestyleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(option.icon, color: colorScheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
