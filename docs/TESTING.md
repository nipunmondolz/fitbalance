# Testing

## Current Verification Status

Verified on the project recovery/finalization cycle:

- Flutter analyzer: **PASS**
- Automated tests: **8/8 PASS**
- Physical-device regression: **PASS**
- Privacy reset + fresh onboarding: **PASS**
- Reminder cancellation after full data reset: **PASS**

## Automated Tests

Current test files:

```text
test/services/calorie_target_calculator_test.dart
test/services/measurement_unit_converter_test.dart
```

The tests protect the current behavior of:

### Calorie Target Calculator

- BMI calculation
- BMR calculation
- Female-formula adjustment
- Current non-female adjustment
- Activity multipliers
- Weight-loss calorie floor
- Gain target range
- Fitness/maintenance-style target range
- Healthy-weight reference calculations

### Measurement Unit Converter

- kg -> lb
- lb -> kg
- metric weight formatting
- imperial weight formatting
- signed weight formatting
- cm -> nearest whole inch -> ft/in display
- metric/imperial input conversion
- weight-range formatting

## Regression Matrix

| Area | Verified behavior |
|---|---|
| Startup restore | Saved profile opens Dashboard after restart |
| Navigation | Non-Today Back returns to Today first |
| Daily Log | Add/delete and Today summary refresh |
| Habits | Daily completion/check-in persistence |
| Reminders | Enable, receive, restart, restore setting, disable/cancel |
| Progress | Weight, target, BMI, charts/history |
| Units | Metric/Imperial equivalent values and persistence |
| Profile | Preferences, reassessment, settings |
| Learn | Bilingual content screens |
| Language | Bangla/English switching and persistence |
| Appearance | System/Light/Dark persistence |
| Privacy reset | Destructive confirmation, deletion, Welcome reset |
| Fresh start | Consent gate, onboarding completion, restart persistence |

## Physical Device

Primary validation device:

- Google Pixel 6a
- Android 17 / API 37 during the final regression cycle

## Commands

```bash
flutter analyze
flutter test
git diff --check
git status --short
flutter run
```

## Testing Limitations

The current MVP does not yet include:

- widget-test coverage for all screens,
- integration tests for onboarding/navigation,
- automated Android notification integration tests,
- CI test execution on every push,
- multi-device / multi-API-level test matrix.

These are reasonable future improvements if the project moves beyond portfolio/MVP scope.
