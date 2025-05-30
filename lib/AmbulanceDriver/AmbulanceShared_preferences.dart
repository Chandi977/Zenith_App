import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  Future<void> saveDriverData({
    required String id,
    required String name,
    required String email,
    required String contactNumber,
    required String age,
    required String drivingExperience,
    required String govtIdNumber,
    required String assignedShift,
    required String latitude,
    required String longitude,
    required String accessToken,
    required String refreshToken,
    required String available,
    required String ambulance,
    required String userRatings,
    required String createdAt,
    required String updatedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('_id', id);
    await prefs.setString('driver_name', name);
    await prefs.setString('driver_email', email);
    await prefs.setString('driver_contactNumber', contactNumber);
    await prefs.setString('driver_age', age);
    await prefs.setString('driver_drivingExperience', drivingExperience);
    await prefs.setString('driver_govtIdNumber', govtIdNumber);
    await prefs.setString('driver_assignedShift', assignedShift);
    await prefs.setString('driver_latitude', latitude);
    await prefs.setString('driver_longitude', longitude);
    await prefs.setString('driver_accessToken', accessToken);
    await prefs.setString('driver_refreshToken', refreshToken);
    await prefs.setString('driver_available', available);
    await prefs.setString('driver_ambulance', ambulance);
    await prefs.setString('driver_userRatings', userRatings);
    await prefs.setString('driver_createdAt', createdAt);
    await prefs.setString('driver_updatedAt', updatedAt);
  }

  Future<Map<String, String>> getDriverData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getString('_id') ?? '',
      'name': prefs.getString('driver_name') ?? '',
      'email': prefs.getString('driver_email') ?? '',
      'contactNumber': prefs.getString('driver_contactNumber') ?? '',
      'age': prefs.getString('driver_age') ?? '',
      'drivingExperience': prefs.getString('driver_drivingExperience') ?? '',
      'govtIdNumber': prefs.getString('driver_govtIdNumber') ?? '',
      'assignedShift': prefs.getString('driver_assignedShift') ?? '',
      'latitude': prefs.getString('driver_latitude') ?? '',
      'longitude': prefs.getString('driver_longitude') ?? '',
      'accessToken': prefs.getString('driver_accessToken') ?? '',
      'refreshToken': prefs.getString('driver_refreshToken') ?? '',
    };
  }

  Future<void> clearDriverData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('driver_id');
    await prefs.remove('driver_name');
    await prefs.remove('driver_email');
    await prefs.remove('driver_contactNumber');
    await prefs.remove('driver_age');
    await prefs.remove('driver_drivingExperience');
    await prefs.remove('driver_govtIdNumber');
    await prefs.remove('driver_assignedShift');
    await prefs.remove('driver_latitude');
    await prefs.remove('driver_longitude');
    await prefs.remove('driver_accessToken');
    await prefs.remove('driver_refreshToken');
  }
}