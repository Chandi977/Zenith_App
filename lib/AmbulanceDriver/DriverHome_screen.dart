import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ambulance_tracker/User/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ambulance_tracker/AmbulanceDriver/Driver_login.dart';
import 'package:ambulance_tracker/screens/Welcome/welcome_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  LatLng? _currentLocation;
  final Location _location = Location();
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  late final String _updateLocationUrl;
  Map<String, dynamic>? _currentSosRequest;
  Timer? _sosCheckTimer;

  String driverName = '';
  String driverEmail = '';
  String profileImage = '';

  @override
  void initState() {
    super.initState();
    _updateLocationUrl = '${dotenv.env['API_BASE_URL']}/ambulanceDriver';
    _getDriverData();
    _getCurrentLocation();
    _startLocationUpdates();
    _startSosRequestCheck();
  }

  @override
  void dispose() {
    _sosCheckTimer?.cancel();
    super.dispose();
  }

  void _startSosRequestCheck() {
    _sosCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForSosRequests();
    });
  }

  Future<void> _checkForSosRequests() async {
    try {
      final userData = await AuthService().getUserData();
      final driverId = userData['_id'];

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/ambulanceDriver/$driverId/sos-requests'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            _currentSosRequest = data['data'];
          });
          if (_currentSosRequest != null && _currentSosRequest!['userLocation'] != null) {
            _drawRouteToUser(
              LatLng(
                _currentSosRequest!['userLocation']['latitude'],
                _currentSosRequest!['userLocation']['longitude'],
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking SOS requests: $e');
    }
  }

  Future<void> _drawRouteToUser(LatLng userLocation) async {
    if (_currentLocation == null) return;

    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('Google Maps API key is missing');
      return;
    }

    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
        '&destination=${userLocation.latitude},${userLocation.longitude}'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);
          _drawPath(decodedPoints, Colors.blue);
        }
      }
    } catch (e) {
      print('Error drawing route: $e');
    }
  }

  Future<void> _updateTripStatus(String status) async {
    try {
      final userData = await AuthService().getUserData();
      final driverId = userData['_id'];

      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/ambulanceDriver/update-trip'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'driverId': driverId,
          'requestId': _currentSosRequest!['_id'],
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        if (status == 'completed') {
          setState(() {
            _currentSosRequest = null;
            _polylines.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip completed successfully')),
          );
        } else {
          final data = json.decode(response.body);
          setState(() {
            _currentSosRequest = data['data'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to: ${status.toUpperCase()}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> updateLocation(String driverId, double latitude, double longitude) async {
    final response = await http.patch(
      Uri.parse('$_updateLocationUrl'.replaceFirst('{driverId}', driverId)),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'latitude': latitude, 'longitude': longitude}),
    );
  }

// // After
//   Future<void> updateLocation(String driverId, double latitude, double longitude) async {
//   final response = await http.patch(
//   Uri.parse('$_updateLocationUrl'.replaceFirst('{driverId}', driverId)),
//   headers: {'Content-Type': 'application/json'},
//   body: json.encode({'latitude': latitude, 'longitude': longitude}),
//   );
//   }
  Future<void> logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Clear all stored user data
    await prefs.clear();

    // Navigate to the login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
          (route) => false,
    );
  }

  Future<void> _getDriverData() async {
    final authService = AuthService();
    final userData = await authService.getUserData();
    setState(() {
      driverName = userData['name'] ?? 'Unknown Driver';
      driverEmail = userData['email'] ?? 'unknown@example.com';
      profileImage = userData['profileImage'] ?? '';
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        _isLoading = false;
      });
      _updateDriverLocation(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("Failed to get current location: $e");
    }
  }

  void _startLocationUpdates() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final locationData = await _location.getLocation();
        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
        _updateDriverLocation(locationData.latitude!, locationData.longitude!);
      } catch (e) {
        _showError("Error fetching location: $e");
      }
    });
  }

  void _handleRequestReceived(String requestId, LatLng userLocation) async {
    await _assignDriverAndNotify(requestId);

    LatLng hospitalLocation = await _getBestHospital(userLocation);

    await _updateRouteWithTraffic(_currentLocation!, hospitalLocation);
  }

  Future<void> _updateDriverLocation(double latitude, double longitude) async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      final driverId = userData['_id']; // Fetch driver ID from shared preferences

      if (driverId == null || driverId.isEmpty) {
        _showError("Driver ID not found");
        return;
      }

      final response = await http.patch(
        Uri.parse('$_updateLocationUrl/$driverId/location'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'latitude': latitude, 'longitude': longitude}),
      );

      if (response.statusCode != 200) {
        _showError("Failed to update driver location: ${response.body}");
      }
    } catch (e) {
      _showError("Error updating driver location: $e");
    }
  }

  Future<void> _assignDriverAndNotify(String requestId) async {
    try {
      final String apiUrl = '${dotenv.env['API_BASE_URL']}/ambulanceDriver/assign';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'requestId': requestId}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final assignedDriver = jsonResponse['data']['assignedDriver'];

        // Notify the driver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request assigned to driver: $assignedDriver')),
        );
      } else {
        _showError("Failed to assign driver: ${response.body}");
      }
    } catch (e) {
      _showError("Error assigning driver: $e");
    }
  }

  Future<void> _updateRouteWithTraffic(LatLng start, LatLng destination) async {
    try {
      final String apiUrl = '${dotenv.env['TRAFFIC_API_URL']}';
      final response = await http.get(Uri.parse('$apiUrl?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&traffic_model=best_guess'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final routePoints = _decodePolyline(jsonResponse['routes'][0]['overview_polyline']['points']);
        final trafficCondition = jsonResponse['routes'][0]['legs'][0]['traffic_condition'];

        // Set route color based on traffic
        Color routeColor = trafficCondition == 'heavy' ? Colors.red : Colors.green;

        _drawPath(routePoints, routeColor);
      } else {
        _showError("Failed to fetch traffic data: ${response.body}");
      }
    } catch (e) {
      _showError("Error fetching traffic data: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylinePoints = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylinePoints;
  }


  Future<LatLng> _getBestHospital(LatLng userLocation) async {
    try {
      final String apiUrl = '${dotenv.env['API_BASE_URL']}/hospitals/nearest';
      final response = await http.get(
        Uri.parse('$apiUrl?latitude=${userLocation.latitude}&longitude=${userLocation.longitude}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final hospitalData = jsonResponse['data']['hospital'];

        if (hospitalData != null) {
          return LatLng(
            hospitalData['latitude'],
            hospitalData['longitude'],
          );
        } else {
          throw Exception("No hospital found in the vicinity.");
        }
      } else {
        throw Exception("Failed to fetch hospital data: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching hospital location: $e");
    }
  }



  void _drawPath(List<LatLng> routePoints, Color routeColor) {
    if (routePoints.isEmpty) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('path'),
          points: routePoints,
          color: routeColor,
          width: 5,
        ),
      };
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DriverLoginScreen()),
          (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Home"),
        backgroundColor: Colors.red,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<Map<String, String>>(
              future: AuthService().getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const DrawerHeader(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const DrawerHeader(child: Text('Error loading profile'));
                } else {
                  final userData = snapshot.data!;
                  return UserAccountsDrawerHeader(
                    accountName: Text(userData['name'] ?? 'Unknown User'),
                    accountEmail: Text(userData['email'] ?? 'unknown@example.com'),
                    currentAccountPicture: CircleAvatar(
                      backgroundImage: userData['profileImage'] != null
                          ? NetworkImage(userData['profileImage']!)
                          : const AssetImage('assets/images/user_profile.png') as ImageProvider,
                    ),
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(143, 148, 251, 1),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await logout(context);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(0, 0),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            polylines: _polylines,
          ),
          if (_currentSosRequest != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Emergency Request',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentSosRequest!['status'] ?? 'En Route',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20),
                        const SizedBox(width: 8),
                        Text('Patient: ${_currentSosRequest!['userName'] ?? 'Unknown'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('Contact: ${_currentSosRequest!['userContact'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _updateTripStatus('arrived'),
                          icon: const Icon(Icons.local_hospital),
                          label: const Text('Arrived at Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _updateTripStatus('completed'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}