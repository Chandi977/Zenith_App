import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:ambulance_tracker/User/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      var status = await Permission.location.request();

      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        print('Current location fetched: ${position.latitude}, ${position.longitude}');
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        await fetchNearbyAmbulances();
      } else if (status.isDenied) {
        print('Location permission denied.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to fetch your location.')),
        );
      } else if (status.isPermanentlyDenied) {
        print('Location permission permanently denied.');
        openAppSettings(); // Redirect user to app settings
      }
    } catch (e) {
      print('Error fetching current location: $e');
    }
  }
  Future<void> fetchNearbyAmbulances() async {
    final String apiUrl = '${dotenv.env['API_BASE_URL']}/ambulance/nearest';

    if (_currentLocation == null) {
      print('Current location is not available.');
      return;
    }

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
                markerId: MarkerId(ambulance['id']),
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

  Future<void> _sendSOS() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is not available')),
      );
      return;
    }

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Request'),
          content: const Text('Are you sure you want to request an ambulance?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final String apiUrl = '${dotenv.env['API_BASE_URL']}/users/send-sos';

    try {
      final userData = await AuthService().getUserData();
      final userId = userData['userId'] ?? '';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'currentLocation': {
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
          },
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ambulance requested successfully')),
        );
        _startTrackingAmbulance('ambulanceId');
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
    }
  }

  Future<void> _fetchAmbulanceLocation(String ambulanceId) async {
    final String apiUrl = '${dotenv.env['API_BASE_URL']}/ambulance/location';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ambulanceId': ambulanceId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

  Future<void> _calculateETA() async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_ambulanceLocation!.latitude},${_ambulanceLocation!.longitude}&destination=${_currentLocation!.latitude},${_currentLocation!.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
              onTap: () {},
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
                      print('Error during location search: $e');
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
                  heroTag: 'zoomInButton', // Unique heroTag
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
                  heroTag: 'zoomOutButton', // Unique heroTag
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