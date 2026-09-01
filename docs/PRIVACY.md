# Privacy & Data

## Current Data Model

FitBalance is an offline local-data MVP. It does not currently require:

- an account,
- authentication,
- a backend server,
- cloud synchronization.

Core profile, lifestyle, progress, log, habit, and app-setting data is stored locally on the device through SharedPreferences-based services.

## Local Data Includes

- onboarding completion/session
- age and gender
- calorie target range
- goal and lifestyle preferences
- height
- weight history
- target weight
- Daily Log entries
- habit completion
- daily check-in
- habit reminder settings
- theme preference
- Metric/Imperial preference

## Notifications

Habit reminders are scheduled locally on Android. FitBalance currently uses three fixed reminder IDs: `1000`, `1001`, and `1002`.

## Delete All Data

Profile includes a **Privacy and data** section with a destructive **Delete all FitBalance data** action.

The action:

1. shows a confirmation dialog,
2. cancels the three scheduled habit reminders,
3. clears local SharedPreferences-backed app data,
4. resets in-memory appearance and measurement-unit settings to defaults,
5. returns to the fresh Welcome/onboarding flow.

The deletion is intentionally irreversible from inside the app.

## Health & Medical Scope

FitBalance is a general lifestyle-management MVP. It does not provide a medical diagnosis, treatment, or prescription.

## Production Considerations

Before using a similar app for real production health data, additional work should include:

- a formal privacy policy,
- applicable legal/compliance review,
- secure/encrypted storage appropriate for sensitive data,
- authentication/account-security review if accounts are added,
- secure backend/API design if cloud features are introduced,
- data retention/export/deletion policies,
- threat modeling and security testing.
