import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ambulance_tracker/screens/Welcome/welcome_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  final List<Marker> _ambulanceMarkers = [];
  final TextEditingController _searchController = TextEditingController();
  double _currentZoom = 14.0;

  LatLng? _ambulanceLocation;
  final List<Polyline> _polylines = [];
  Timer? _ambulanceLocationTimer;
  String _eta = "";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _ambulanceLocationTimer?.cancel();
    super.dispose();
  }
  bool _sosInProgress = false;



  Future<void> logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
          (route) => false,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        await fetchNearbyAmbulances();
      } else if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to fetch your location.')),
        );
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    } catch (e) {
      print('Error fetching current location: $e');
    }
  }
  void _drawPolyline(List<dynamic> points) {
    final polylinePoints = points.map((p) => LatLng(p['lat'], p['lng'])).toList();
    final polyline = Polyline(
      polylineId: PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: polylinePoints,
    );
    setState(() {
      _polylines.clear();
      _polylines.add(polyline);
    });
  }


  Future<void> fetchNearbyAmbulances() async {
    final String apiUrl = '${dotenv.env['API_BASE_URL']}/ambulance/nearest';
    if (_currentLocation == null) return;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ambulanceMarkers.clear();
          for (var ambulance in data['ambulances']) {
            _ambulanceMarkers.add(
              Marker(
                markerId: MarkerId(ambulance['_id']),
                position: LatLng(ambulance['latitude'], ambulance['longitude']),
                infoWindow: InfoWindow(title: ambulance['name']),
              ),
            );
          }
        });
      } else {
        print('Failed to fetch ambulances: ${response.body}');
      }
    } catch (e) {
      print('Error fetching ambulances: $e');
    }
  }

  Future<void> _simulateDriverPath(String ambulanceId) async {
    if (_ambulanceLocation == null || _currentLocation == null) return;

    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('Google Maps API key is missing');
      return;
    }

    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_ambulanceLocation!.latitude},${_ambulanceLocation!.longitude}'
        '&destination=${_currentLocation!.latitude},${_currentLocation!.longitude}'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final points = data['routes'][0]['overview_polyline']['points'];
        final decodedPoints = _decodePolyline(points);
        _drawPolyline(decodedPoints);
      }
    } catch (e) {
      print('Error simulating driver path: $e');
    }
  }
  Future<void> _sendSOS() async {
    if (_sosInProgress) return;
    _sosInProgress = true;

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is not available')),
      );
      _sosInProgress = false;
      return;
    }

    final String apiUrl = '${dotenv.env['API_BASE_URL']}/users/send-sos';

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      // print(token);
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authorization token is missing')),
        );
        return;
      }

      final userData = await AuthService().getUserData();
      final userId = userData['_id'] ?? '';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'currentLocation': {
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] == null) {
          throw Exception('Invalid response data');
        }

        final data = responseData['data'];
        final status = data['status'] ?? 'Unknown';

        _showConfirmationPopup(
          'SOS Request Sent',
          'Ambulance assigned successfully. Status: $status',
        );

        _startTrackingAmbulance(data['_id']);
        _simulateDriverPath(data['_id']);
      } else {
        final errorMessage = json.decode(response.body)['message'] ?? 'Request failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _sosInProgress = false;
    }
  }


  void _showConfirmationPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAmbulanceLocation(String ambulanceId) async {
    print(ambulanceId);
    final String apiUrl = '${dotenv.env['API_BASE_URL']}/ambulanceDriver/ambulanceById/$ambulanceId';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _ambulanceLocation = LatLng(data['latitude'], data['longitude']);
        });
      } else {
        print('Failed to fetch ambulance location: ${response.body}');
      }
    } catch (e) {
      print('Error fetching ambulance location: $e');
    }
  }


  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylinePoints = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polylinePoints;
  }

  Future<void> _calculateETA() async {

    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_ambulanceLocation!.latitude},${_ambulanceLocation!.longitude}&destination=${_currentLocation!.latitude},${_currentLocation!.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final points = data['routes'][0]['overview_polyline']['points'];
        final decodedPoints = _decodePolyline(points);
        _drawPolyline(decodedPoints);

        final duration = data['routes'][0]['legs'][0]['duration']['text'];
        setState(() {
          _eta = duration;
        });
      }
    } catch (e) {
      print('Error calculating ETA: $e');
    }
  }

  void _startTrackingAmbulance(String ambulanceId) {
    _ambulanceLocationTimer?.cancel();
    _ambulanceLocationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _fetchAmbulanceLocation(ambulanceId);
      if (_ambulanceLocation != null) {
        _mapController?.animateCamera(CameraUpdate.newLatLng(_ambulanceLocation!));
        await _calculateETA();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Tracker'),
        backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
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
          if (_currentLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: _currentZoom,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: _currentLocation!,
                  infoWindow: const InfoWindow(title: 'Your Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
                ..._ambulanceMarkers,
              },
              polylines: Set<Polyline>.of(_polylines),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            )
          else
            const Center(child: CircularProgressIndicator()),

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    try {
                      if (_searchController.text.isEmpty) {
                        throw Exception('Search query is empty');
                      }

                      List<Location> locations = await locationFromAddress(_searchController.text);
                      if (locations.isNotEmpty) {
                        Location location = locations.first;
                        LatLng searchedLocation = LatLng(location.latitude, location.longitude);
                        _mapController?.animateCamera(CameraUpdate.newLatLng(searchedLocation));
                        setState(() {
                          _currentLocation = searchedLocation;
                        });
                        await fetchNearbyAmbulances();
                      } else {
                        throw Exception('No locations found');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location not found or invalid input')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomInButton',
                  onPressed: () {
                    if (_mapController != null) {
                      _currentZoom += 1;
                      _mapController!.animateCamera(CameraUpdate.zoomTo(_currentZoom));
                    }
                  },
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomOutButton',
                  onPressed: () {
                    if (_mapController != null) {
                      _currentZoom -= 1;
                      _mapController!.animateCamera(CameraUpdate.zoomTo(_currentZoom));
                    }
                  },
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _sendSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Request Ambulance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (_eta.isNotEmpty)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: Text(
                  'ETA: $_eta',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}