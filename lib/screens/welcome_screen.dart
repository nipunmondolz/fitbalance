import 'package:flutter/material.dart';

import 'consent_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({this.initialIsBangla = true, super.key});

  final bool initialIsBangla;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late String _selectedLanguage;

  bool get _isBangla => _selectedLanguage == 'bn';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialIsBangla ? 'bn' : 'en';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'bn', label: Text('বাংলা')),
                    ButtonSegment<String>(value: 'en', label: Text('English')),
                  ],
                  selected: <String>{_selectedLanguage},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _selectedLanguage = selection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 56),
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    size: 56,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'FitBalance',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isBangla
                    ? 'আপনার স্বাস্থ্যকর জীবনের শুরু এখানে'
                    : 'Your healthier journey starts here',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isBangla
                    ? 'আপনার লক্ষ্য অনুযায়ী ওজন কমানো, বাড়ানো বা ধরে রাখার জন্য সহজ দৈনন্দিন অভ্যাস গড়ে তুলুন।'
                    : 'Build simple daily habits to lose, gain, or maintain weight according to your goal.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _isBangla
                            ? '১৮ বছর বা তার বেশি বয়সী ব্যবহারকারীদের জন্য'
                            : 'For users aged 18 and over',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            ConsentScreen(isBangla: _isBangla),
                      ),
                    );
                  },
                  child: Text(
                    _isBangla ? 'শুরু করুন' : 'Get started',
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
