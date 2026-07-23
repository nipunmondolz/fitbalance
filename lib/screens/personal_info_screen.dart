import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({required this.isBangla, super.key});

  final bool isBangla;

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedGender;
  String _heightUnit = 'feet_inches';

  @override
  void dispose() {
    _ageController.dispose();
    _heightCmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String _normalizeNumber(String value) {
    const banglaDigits = '০১২৩৪৫৬৭৮৯';
    const englishDigits = '0123456789';

    var normalized = value.trim();

    for (var i = 0; i < banglaDigits.length; i++) {
      normalized = normalized.replaceAll(banglaDigits[i], englishDigits[i]);
    }

    return normalized;
  }

  String? _validateAge(String? value) {
    final isBangla = widget.isBangla;

    if (value == null || value.trim().isEmpty) {
      return isBangla ? 'আপনার বয়স লিখুন' : 'Enter your age';
    }

    final age = int.tryParse(_normalizeNumber(value));

    if (age == null) {
      return isBangla
          ? 'সঠিক পূর্ণসংখ্যায় বয়স লিখুন'
          : 'Enter a valid whole number';
    }

    if (age < 18) {
      return isBangla
          ? 'FitBalance শুধু ১৮ বছর বা তার বেশি বয়সীদের জন্য'
          : 'FitBalance is only for users aged 18 or over';
    }

    if (age > 120) {
      return isBangla ? 'সঠিক বয়স লিখুন' : 'Enter a valid age';
    }

    return null;
  }

  String? _validateHeightCm(String? value) {
    final isBangla = widget.isBangla;

    if (value == null || value.trim().isEmpty) {
      return isBangla ? 'আপনার উচ্চতা লিখুন' : 'Enter your height';
    }

    final height = double.tryParse(_normalizeNumber(value));

    if (height == null) {
      return isBangla ? 'সঠিক সংখ্যায় উচ্চতা লিখুন' : 'Enter a valid height';
    }

    if (height < 100 || height > 250) {
      return isBangla
          ? 'উচ্চতা ১০০ থেকে ২৫০ সেমির মধ্যে লিখুন'
          : 'Enter a height between 100 and 250 cm';
    }

    return null;
  }

  String? _validateFeet(String? value) {
    final isBangla = widget.isBangla;

    if (value == null || value.trim().isEmpty) {
      return isBangla ? 'ফুট লিখুন' : 'Enter feet';
    }

    final feet = int.tryParse(_normalizeNumber(value));

    if (feet == null) {
      return isBangla
          ? 'সঠিক পূর্ণসংখ্যায় ফুট লিখুন'
          : 'Enter valid whole-number feet';
    }

    if (feet < 3 || feet > 8) {
      return isBangla
          ? 'ফুট ৩ থেকে ৮-এর মধ্যে লিখুন'
          : 'Enter feet between 3 and 8';
    }

    return null;
  }

  String? _validateInches(String? value) {
    final isBangla = widget.isBangla;

    if (value == null || value.trim().isEmpty) {
      return isBangla ? 'ইঞ্চি লিখুন' : 'Enter inches';
    }

    final inches = int.tryParse(_normalizeNumber(value));

    if (inches == null) {
      return isBangla
          ? 'সঠিক পূর্ণসংখ্যায় ইঞ্চি লিখুন'
          : 'Enter valid whole-number inches';
    }

    if (inches < 0 || inches > 11) {
      return isBangla
          ? 'ইঞ্চি ০ থেকে ১১-এর মধ্যে লিখুন'
          : 'Enter inches between 0 and 11';
    }

    final feet = int.tryParse(_normalizeNumber(_feetController.text));

    if (feet != null) {
      final heightInCm = (feet * 12 + inches) * 2.54;

      if (heightInCm < 100 || heightInCm > 250) {
        return isBangla
            ? 'মোট উচ্চতা ১০০ থেকে ২৫০ সেমির মধ্যে হতে হবে'
            : 'Total height must be between 100 and 250 cm';
      }
    }

    return null;
  }

  String? _validateWeight(String? value) {
    final isBangla = widget.isBangla;

    if (value == null || value.trim().isEmpty) {
      return isBangla ? 'আপনার বর্তমান ওজন লিখুন' : 'Enter your current weight';
    }

    final weight = double.tryParse(_normalizeNumber(value));

    if (weight == null) {
      return isBangla ? 'সঠিক সংখ্যায় ওজন লিখুন' : 'Enter a valid weight';
    }

    if (weight < 25 || weight > 350) {
      return isBangla
          ? 'ওজন ২৫ থেকে ৩৫০ কেজির মধ্যে লিখুন'
          : 'Enter a weight between 25 and 350 kg';
    }

    return null;
  }

  double _getHeightInCm() {
    if (_heightUnit == 'centimeters') {
      return double.parse(_normalizeNumber(_heightCmController.text));
    }

    final feet = int.parse(_normalizeNumber(_feetController.text));
    final inches = int.parse(_normalizeNumber(_inchesController.text));

    return (feet * 12 + inches) * 2.54;
  }

  void _continue() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.isBangla
                  ? 'অনুগ্রহ করে লিঙ্গ নির্বাচন করুন'
                  : 'Please select your gender',
            ),
          ),
        );
      return;
    }

    final heightInCm = _getHeightInCm();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla
                ? 'তথ্য যাচাই সফল—উচ্চতা ${heightInCm.toStringAsFixed(1)} সেমি'
                : 'Information validated—height '
                      '${heightInCm.toStringAsFixed(1)} cm',
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
        title: Text(isBangla ? 'ব্যক্তিগত তথ্য' : 'Personal information'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 72,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  isBangla
                      ? 'আপনার সম্পর্কে কিছু তথ্য দিন'
                      : 'Tell us a little about yourself',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isBangla
                      ? 'এই তথ্য BMI ও ব্যক্তিগত স্বাস্থ্য পরিকল্পনা তৈরিতে ব্যবহার করা হবে।'
                      : 'This information will be used to calculate BMI and prepare your personalized health plan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'বয়স' : 'Age',
                    hintText: isBangla ? 'যেমন: ২৫' : 'For example: 25',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixText: isBangla ? 'বছর' : 'years',
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateAge,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'লিঙ্গ' : 'Gender',
                    prefixIcon: const Icon(Icons.people_outline),
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(isBangla ? 'নির্বাচন করুন' : 'Select an option'),
                  items: [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text(isBangla ? 'পুরুষ' : 'Male'),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text(isBangla ? 'নারী' : 'Female'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text(isBangla ? 'অন্যান্য' : 'Other'),
                    ),
                    DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text(
                        isBangla ? 'বলতে অনিচ্ছুক' : 'Prefer not to say',
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _heightUnit,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'উচ্চতা মাপার পদ্ধতি' : 'Height unit',
                    prefixIcon: const Icon(Icons.straighten),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'feet_inches',
                      child: Text(isBangla ? 'ফুট ও ইঞ্চি' : 'Feet and inches'),
                    ),
                    DropdownMenuItem(
                      value: 'centimeters',
                      child: Text(isBangla ? 'সেন্টিমিটার' : 'Centimeters'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _heightUnit = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                if (_heightUnit == 'feet_inches')
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _feetController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: isBangla ? 'ফুট' : 'Feet',
                            hintText: isBangla ? 'যেমন: ৫' : 'For example: 5',
                            prefixIcon: const Icon(Icons.height),
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateFeet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _inchesController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: isBangla ? 'ইঞ্চি' : 'Inches',
                            hintText: isBangla ? 'যেমন: ৭' : 'For example: 7',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateInches,
                        ),
                      ),
                    ],
                  )
                else
                  TextFormField(
                    controller: _heightCmController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: isBangla ? 'উচ্চতা' : 'Height',
                      hintText: isBangla ? 'যেমন: ১৭০' : 'For example: 170',
                      prefixIcon: const Icon(Icons.height),
                      suffixText: isBangla ? 'সেমি' : 'cm',
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateHeightCm,
                  ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'বর্তমান ওজন' : 'Current weight',
                    hintText: isBangla ? 'যেমন: ৬৫' : 'For example: 65',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    suffixText: isBangla ? 'কেজি' : 'kg',
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateWeight,
                  onFieldSubmitted: (_) => _continue(),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isBangla
                              ? 'আপনার দেওয়া তথ্য ব্যক্তিগত স্বাস্থ্য হিসাবের জন্য ব্যবহার করা হবে।'
                              : 'Your information will be used for personal health calculations.',
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
      ),
    );
  }
}
