import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<void> saveUserData(String name, String email, String accessToken, String refreshToken, String profileImage, param5,param6) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('avatar', profileImage); // Save profile image
  }

  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name') ?? 'Unknown User', // Default value
      'email': prefs.getString('email') ?? 'unknown@example.com', // Default value
      'profileImage': prefs.getString('avatar') ?? '', // Default value
      'accessToken': prefs.getString('accessToken') ?? '', // Default value
      'refreshToken': prefs.getString('refreshToken') ?? '', // Default value
    };
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken != null) {
      // Simulate API call to refresh token
      await Future.delayed(const Duration(seconds: 2));
      final newAccessToken = 'newAccessToken123'; // Replace with API response
      await prefs.setString('accessToken', newAccessToken);
      return newAccessToken;
    }
    return null;
  }
}
