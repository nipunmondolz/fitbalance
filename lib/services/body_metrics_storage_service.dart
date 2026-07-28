import 'package:shared_preferences/shared_preferences.dart';

class BodyMetricsStorageService {
  BodyMetricsStorageService._();

  static final BodyMetricsStorageService instance =
      BodyMetricsStorageService._();

  static const String _heightCmKey = 'profile_height_cm_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<double?> loadHeightCm() async {
    final savedHeight = await _preferences.getDouble(_heightCmKey);

    if (savedHeight == null ||
        !savedHeight.isFinite ||
        savedHeight < 100 ||
        savedHeight > 250) {
      return null;
    }

    return savedHeight;
  }

  Future<void> saveHeightCm(double heightCm) {
    if (!heightCm.isFinite || heightCm < 100 || heightCm > 250) {
      throw const FormatException('Invalid height value');
    }

    return _preferences.setDouble(_heightCmKey, heightCm);
  }
}
