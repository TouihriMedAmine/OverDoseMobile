import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  static const _tokenKey = 'auth_token';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> readToken() async => (await _prefs).getString(_tokenKey);

  Future<void> writeToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
  }

  Future<List<String>> readStringList(String key) async {
    return (await _prefs).getStringList(key) ?? const [];
  }

  Future<void> writeStringList(String key, List<String> values) async {
    final prefs = await _prefs;
    await prefs.setStringList(key, values);
  }

  Future<void> removeValue(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }
}
