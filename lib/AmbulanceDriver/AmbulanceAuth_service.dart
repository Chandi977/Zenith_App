import 'package:ambulance_tracker/AmbulanceDriver/AmbulanceShared_preferences.dart';

class AuthService {
  final SharedPreferenceService _prefsService = SharedPreferenceService();

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
    await _prefsService.saveDriverData(
      id: id,
      name: name,
      email: email,
      contactNumber: contactNumber,
      age: age,
      drivingExperience: drivingExperience,
      govtIdNumber: govtIdNumber,
      assignedShift: assignedShift,
      latitude: latitude,
      longitude: longitude,
      accessToken: accessToken,
      refreshToken: refreshToken,
      available: available,
      ambulance: ambulance,
      userRatings: userRatings,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<Map<String, String>> getDriverData() async {
    return await _prefsService.getDriverData();
  }

  Future<void> clearDriverData() async {
    await _prefsService.clearDriverData();
  }
}