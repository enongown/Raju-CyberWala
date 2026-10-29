import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { traveller, host }

/// Small wrapper around shared_preferences for the user's choices.
class AppPrefs {
  AppPrefs._(this._sp);

  static const _roleKey = 'user_role';
  static const _offlineKey = 'offline_mode';

  static late AppPrefs instance;

  final SharedPreferences _sp;

  static Future<AppPrefs> load() async {
    instance = AppPrefs._(await SharedPreferences.getInstance());
    return instance;
  }

  UserRole? get role => switch (_sp.getString(_roleKey)) {
    'traveller' => UserRole.traveller,
    'host' => UserRole.host,
    _ => null,
  };

  Future<void> setRole(UserRole role) => _sp.setString(_roleKey, role.name);

  Future<void> clearRole() => _sp.remove(_roleKey);

  bool get offlineMode => _sp.getBool(_offlineKey) ?? true;

  Future<void> setOfflineMode(bool value) => _sp.setBool(_offlineKey, value);
}
