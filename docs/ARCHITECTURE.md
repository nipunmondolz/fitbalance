# Architecture

## Overview

FitBalance is an Android-first, offline Flutter MVP. The architecture is intentionally lightweight: UI/state is primarily screen-local, while persistence and calculations are separated into small service classes.

## Runtime Startup

```text
main.dart
  -> FitBalanceApp
     -> initialize AppSettingsController
     -> AppStartupScreen
        -> valid unified onboarding session?
           -> DashboardNavigationScreen
        -> otherwise try legacy profile migration
           -> successful migration -> DashboardNavigationScreen
           -> no complete saved data -> WelcomeScreen
```

The app restores appearance and measurement-unit settings before showing the main startup flow.

## Onboarding Flow

```text
Welcome
 -> Consent & Safety
 -> Personal Information
 -> Goal Selection
 -> Lifestyle Assessment
 -> Assessment Result
 -> Plan Confirmation
 -> persist session/profile/body/preferences
 -> Dashboard
```

The dashboard is entered only after required state is successfully persisted.

## Main Navigation

The bottom navigation contains six core areas:

1. Today
2. Daily Log
3. Plan / Habits
4. Progress
5. Learn
6. Profile

Android Back from a non-Today tab returns to Today first.

## Service Responsibilities

| Service | Responsibility |
|---|---|
| `OnboardingStorageService` | Unified completed onboarding/profile session |
| `AssessmentProfileStorageService` | Age, gender, calorie target range |
| `ProfilePreferencesStorageService` | Goal, schedule, activity, sleep, budget |
| `BodyMetricsStorageService` | Canonical height in centimetres |
| `WeightStorageService` | Weight history and target weight in kilograms |
| `DailyLogStorageService` | Date-specific meal/water/soft-drink/exercise/sleep entries |
| `HabitStorageService` | Date-specific habit completion, daily check-in, reminder settings |
| `NotificationService` | Local scheduled habit notifications |
| `CalorieTargetCalculator` | BMI/BMR/TDEE and calorie-target calculations |
| `AppSettingsStorageService` | Appearance and measurement-unit persistence |
| `MeasurementUnitConverter` | kg/lb and cm/ft-in display/input conversion |
| `PrivacyResetService` | Cancel reminders, clear local preferences, reset in-memory app settings |

## Persistence Model

The MVP uses SharedPreferences-based local storage. Important keys include:

- `onboarding_complete_v1`
- `onboarding_session_v1`
- `assessment_profile_v1`
- `profile_preferences_v1`
- `profile_height_cm_v1`
- `weight_entries_v1`
- `target_weight_v1`
- `daily_log_entries_v1_YYYY-MM-DD`
- `habit_completion_YYYY-MM-DD`
- `daily_check_in_YYYY-MM-DD`
- `habit_reminder_settings_v1`
- `app_appearance_mode_v1`
- `app_measurement_unit_v1`

## Canonical Measurement Strategy

Internal body measurements remain metric:

- Weight: kilograms
- Height: centimetres

Imperial values are converted at input/display boundaries. This prevents historical data from being rewritten when the user switches units.

## Notifications

FitBalance has three fixed habit reminder IDs:

- `1000`
- `1001`
- `1002`

Notifications are scheduled using timezone-aware local scheduling and can repeat daily at the chosen time. Resetting all app data explicitly cancels these reminders.

## Privacy Reset Flow

```text
Profile
 -> Privacy and data
 -> Delete all FitBalance data
 -> confirmation required
 -> cancel habit reminders
 -> clear local SharedPreferences data
 -> reset in-memory appearance/unit defaults
 -> AppStartupScreen
 -> Welcome
```

## Architectural Trade-offs

This structure is appropriate for a solo MVP and portfolio project, but a larger production application would likely benefit from:

- centralized state management,
- repository/domain layers,
- encrypted or database-backed sensitive-data storage,
- dependency injection,
- backend/authentication,
- automated integration/UI tests,
- CI/CD.
