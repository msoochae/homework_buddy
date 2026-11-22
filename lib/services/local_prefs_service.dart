import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';

class LocalPrefsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    assert(_prefs != null, 'LocalPrefsService.init() must be called first');
    return _prefs!;
  }

  static UserRole? get role {
    final v = prefs.getString(AppConstants.keyRole);
    if (v == null) return null;
    return UserRole.values.firstWhere((e) => e.name == v, orElse: () => UserRole.child);
  }

  static bool get isParent => role == UserRole.dad || role == UserRole.mom;

  static Future<void> setRole(UserRole role) =>
      prefs.setString(AppConstants.keyRole, role.name);

  static String? get familyCode => prefs.getString(AppConstants.keyFamilyCode);
  static Future<void> setFamilyCode(String code) =>
      prefs.setString(AppConstants.keyFamilyCode, code);

  static String get deviceId {
    var id = prefs.getString(AppConstants.keyDeviceId);
    if (id == null) {
      id = const Uuid().v4();
      prefs.setString(AppConstants.keyDeviceId, id);
    }
    return id;
  }

  static bool get notificationsEnabled =>
      prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  static Future<void> setNotificationsEnabled(bool v) =>
      prefs.setBool(AppConstants.keyNotificationsEnabled, v);
}
