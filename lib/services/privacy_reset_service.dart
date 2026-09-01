import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings_storage_service.dart';
import 'notification_service.dart';

class PrivacyResetService {
  PrivacyResetService._();

  static final PrivacyResetService instance = PrivacyResetService._();

  static const List<int> _habitReminderIds = [1000, 1001, 1002];

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<void> resetAllLocalData() async {
    for (final notificationId in _habitReminderIds) {
      await NotificationService.instance.cancelHabitReminder(notificationId);
    }

    await _preferences.clear();
    AppSettingsController.instance.resetToDefaultsAfterDataClear();
  }
}
