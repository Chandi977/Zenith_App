import 'dart:async';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

late loc.LocationData _currentPosition;
String _address = "";
late GoogleMapController mapController;
late Marker marker;
loc.Location location = loc.Location();
CameraPosition _cameraPosition =
const CameraPosition(target: LatLng(0, 0), zoom: 10.0);

LatLng _initialCameraPosition = const LatLng(0.5937, 0.9629);

Future<String> getLoc() async {
  bool serviceEnabled;
  loc.PermissionStatus permissionGranted;

  try {
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return "null"; // Location service is not enabled
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return "null"; // Permission not granted
      }
    }

    String details = "";

    _currentPosition = await location.getLocation();
    DateTime now = DateTime.now();

    details += DateFormat('EEE d MMM kk:mm:ss ').format(now);

    _initialCameraPosition =
        LatLng(_currentPosition.latitude!, _currentPosition.longitude!);

    Placemark place = await _getAddress(
        _currentPosition.latitude!, _currentPosition.longitude!);

    _address =
    "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

    details += "{}";
    details += "${_currentPosition.latitude} , ${_currentPosition.longitude}";
    details += "{}";
    details += _address;

    return details;
  } catch (e) {
    print("Error fetching location or address: $e");
    return "Error: Could not fetch location";
  }
}

Future<Placemark> _getAddress(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      return placemarks[0];
    } else {
      return Placemark(
          street: "Unknown",
          locality: "Unknown",
          administrativeArea: "Unknown",
          country: "Unknown");
    }
  } catch (e) {
    print("Error getting address: $e");
    return Placemark(
        street: "Error",
        locality: "Unknown",
        administrativeArea: "Unknown",
        country: "Unknown");
  }
}