import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SimulateRouteScreen extends StatefulWidget {
  const SimulateRouteScreen({super.key});

  @override
  _SimulateRouteScreenState createState() => _SimulateRouteScreenState();
}

class _SimulateRouteScreenState extends State<SimulateRouteScreen> {
  GoogleMapController? _mapController;
  LatLng driverLocation = const LatLng(37.7749, -122.4194); // Example driver location
  LatLng userLocation = const LatLng(37.7849, -122.4094); // Example user location
  LatLng hospitalLocation = const LatLng(37.7949, -122.3994); // Example hospital location
  List<LatLng> routeToUser = [];
  List<LatLng> routeToHospital = [];
  Marker? vehicleMarker;
  Timer? simulationTimer;
  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeRoutes();
    _startSimulation();
  }

  @override
  void dispose() {
    simulationTimer?.cancel();
    super.dispose();
  }

  void _initializeRoutes() {
    // Example routes (replace with actual route points)
    routeToUser = [
      driverLocation,
      const LatLng(37.7799, -122.4144),
      const LatLng(37.7849, -122.4094),
    ];
    routeToHospital = [
      userLocation,
      const LatLng(37.7899, -122.4044),
      hospitalLocation,
    ];
  }

  void _startSimulation() {
    simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentStep < routeToUser.length) {
        _updateVehiclePosition(routeToUser[currentStep]);
        currentStep++;
      } else if (currentStep - routeToUser.length < routeToHospital.length) {
        _updateVehiclePosition(routeToHospital[currentStep - routeToUser.length]);
        currentStep++;
      } else {
        simulationTimer?.cancel();
      }
    });
  }

  void _updateVehiclePosition(LatLng position) {
    setState(() {
      vehicleMarker = Marker(
        markerId: const MarkerId('vehicle'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulate Route')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: driverLocation, zoom: 14),
        markers: {
          Marker(
            markerId: const MarkerId('driver'),
            position: driverLocation,
            infoWindow: const InfoWindow(title: 'Driver Location'),
          ),
          Marker(
            markerId: const MarkerId('user'),
            position: userLocation,
            infoWindow: const InfoWindow(title: 'User Location'),
          ),
          Marker(
            markerId: const MarkerId('hospital'),
            position: hospitalLocation,
            infoWindow: const InfoWindow(title: 'Hospital Location'),
          ),
          if (vehicleMarker != null) vehicleMarker!,
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('routeToUser'),
            points: routeToUser,
            color: Colors.blue,
            width: 5,
          ),
          Polyline(
            polylineId: const PolylineId('routeToHospital'),
            points: routeToHospital,
            color: Colors.green,
            width: 5,
          ),
        },
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}