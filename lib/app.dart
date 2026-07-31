import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/app_startup_screen.dart';
import 'services/app_settings_storage_service.dart';

class FitBalanceApp extends StatefulWidget {
  const FitBalanceApp({super.key});

  @override
  State<FitBalanceApp> createState() => _FitBalanceAppState();
}

class _FitBalanceAppState extends State<FitBalanceApp> {
  bool _hasLoadedSettings = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialiseSettings());
  }

  Future<void> _initialiseSettings() async {
    try {
      await AppSettingsController.instance.initialise();
    } catch (_) {
      // Storage ব্যর্থ হলে System default theme ব্যবহার করা হবে।
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _hasLoadedSettings = true;
    });
  }

  ThemeMode _themeModeFromAppearance(AppAppearanceMode mode) {
    switch (mode) {
      case AppAppearanceMode.light:
        return ThemeMode.light;
      case AppAppearanceMode.dark:
        return ThemeMode.dark;
      case AppAppearanceMode.system:
        return ThemeMode.system;
    }
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppAppearanceMode>(
      valueListenable: AppSettingsController.instance.appearanceModeListenable,
      builder: (context, appearanceMode, child) {
        return MaterialApp(
          title: 'FitBalance',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: _themeModeFromAppearance(appearanceMode),
          home: _hasLoadedSettings
              ? const AppStartupScreen()
              : const _SettingsStartupView(),
        );
      },
    );
  }
}

class _SettingsStartupView extends StatelessWidget {
  const _SettingsStartupView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monitor_weight_outlined,
                size: 52,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'FitBalance',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
