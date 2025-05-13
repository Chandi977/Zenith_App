import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<void> saveUserData(String username, String email, String fullName, String avatar, String role, String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('fullName', fullName);
    await prefs.setString('avatar', avatar.isNotEmpty ? avatar : 'default_avatar_url');
    await prefs.setString('role', role.isNotEmpty ? role : 'user');
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? 'Unknown',
      'email': prefs.getString('email') ?? 'unknown@example.com',
      'fullName': prefs.getString('fullName') ?? 'Unknown User',
      'avatar': prefs.getString('avatar') ?? 'default_avatar_url',
      'role': prefs.getString('role') ?? 'user',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
    };
  }
}