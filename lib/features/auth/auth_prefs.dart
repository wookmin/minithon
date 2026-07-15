import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 편의를 위한 로컬 저장. 이메일만 저장하며 비밀번호는 절대 저장하지 않는다.
class AuthPrefs {
  static const _emailKey = 'auth.saved_email';

  Future<String?> readSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey)?.trim();
    return (email == null || email.isEmpty) ? null : email;
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim());
  }

  Future<void> clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
  }
}
