import 'package:flutter/material.dart';

import 'personal_info_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({required this.isBangla, super.key});

  final bool isBangla;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _hasAccepted = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBangla = widget.isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBangla ? 'সম্মতি ও নিরাপত্তা' : 'Consent and safety'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                isBangla
                    ? 'শুরু করার আগে গুরুত্বপূর্ণ তথ্য'
                    : 'Important information before you begin',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _SafetyCard(
                icon: Icons.medical_information_outlined,
                title: isBangla
                    ? 'চিকিৎসার বিকল্প নয়'
                    : 'Not a substitute for medical care',
                description: isBangla
                    ? 'FitBalance সাধারণ স্বাস্থ্য ও জীবনযাপনবিষয়ক নির্দেশনা দেয়। এটি কোনো চিকিৎসকের রোগ নির্ণয়, চিকিৎসা বা ব্যক্তিগত পরামর্শের বিকল্প নয়।'
                    : 'FitBalance provides general health and lifestyle guidance. It does not replace diagnosis, treatment, or personalized advice from a medical professional.',
              ),
              const SizedBox(height: 14),
              _SafetyCard(
                icon: Icons.emergency_outlined,
                title: isBangla
                    ? 'জরুরি পরিস্থিতিতে সাহায্য নিন'
                    : 'Get help in an emergency',
                description: isBangla
                    ? 'গুরুতর অসুস্থতা, তীব্র ব্যথা বা জরুরি স্বাস্থ্যসমস্যা হলে দ্রুত স্থানীয় জরুরি সেবা বা যোগ্য চিকিৎসকের সাহায্য নিন।'
                    : 'For serious illness, severe pain, or a health emergency, immediately contact local emergency services or a qualified medical professional.',
              ),
              const SizedBox(height: 14),
              _SafetyCard(
                icon: Icons.person_search_outlined,
                title: isBangla
                    ? 'নিজের অবস্থার প্রতি সতর্ক থাকুন'
                    : 'Consider your personal condition',
                description: isBangla
                    ? 'গর্ভাবস্থা, দীর্ঘমেয়াদি রোগ, নিয়মিত ওষুধ গ্রহণ বা বিশেষ খাদ্যগত প্রয়োজন থাকলে পরিকল্পনা অনুসরণের আগে চিকিৎসকের পরামর্শ নিন।'
                    : 'Consult a medical professional before following a plan if you are pregnant, have a chronic condition, take regular medication, or have special dietary needs.',
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: CheckboxListTile(
                  value: _hasAccepted,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  title: Text(
                    isBangla
                        ? 'আমি উপরের তথ্য পড়েছি ও বুঝেছি এবং FitBalance ব্যবহার করতে সম্মত।'
                        : 'I have read and understood the information above and agree to use FitBalance.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      _hasAccepted = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _hasAccepted
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  PersonalInfoScreen(isBangla: isBangla),
                            ),
                          );
                        }
                      : null,
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

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
