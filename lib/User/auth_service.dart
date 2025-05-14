import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<void> saveUserData(String _id, String name, String email, String fullName, String profileImage, String role, String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    print(accessToken);
    await prefs.setString('_id', _id);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('fullName', fullName);
    await prefs.setString('profileImage', profileImage);
    await prefs.setString('role', role);
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      '_id': prefs.getString('_id') ?? '',
      'name': prefs.getString('name') ?? 'Unknown User',
      'fullname': prefs.getString('fullname') ?? 'Unknown User',
      'email': prefs.getString('email') ?? 'unknown@example.com',
      'profileImage': prefs.getString('avatar') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
    };
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null || token.isEmpty) {
      throw Exception('Authorization token is missing or invalid');
    }
    return token;
  }
}