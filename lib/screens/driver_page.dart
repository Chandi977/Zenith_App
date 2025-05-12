import 'package:flutter/material.dart';
import 'package:sliding_switch/sliding_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  _DriverPageState createState() => _DriverPageState();
}

var locationData = [];
String currLoc = "";
String address = "";
bool isWorking = false;
bool isAvailable = true;

class _DriverPageState extends State<DriverPage> {
  bool isLoading = false; // Track loading state for location fetching

  @override
  void initState() {
    super.initState();
    currentLoc(); // Fetch the location once when the widget is created.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver page"),
        backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: MediaQuery.of(context).size.height / 8,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Image.network(
                                "https://static.wikia.nocookie.net/pokemon/images/8/88/Char-Eevee.png/revision/latest?cb=20190625223735"),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Name: _______________"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Available: ",
                    style: TextStyle(fontSize: 20),
                  ),
                  SlidingSwitch(
                    value: isAvailable,
                    width: 200,
                    onChanged: (bool value) {
                      setState(() {
                        isAvailable = value;
                      });
                      Fluttertoast.showToast(
                          msg: !value
                              ? "You won't be called for help till you are free"
                              : "You'll be notified when we need your help",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          textColor: Colors.white,
                          fontSize: 16.0);
                    },
                    onTap: () {},
                    onDoubleTap: () {},
                    onSwipe: () {},
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Working: ",
                  style: TextStyle(fontSize: 28),
                ),
                SlidingSwitch(
                  value: isWorking,
                  width: 200,
                  onChanged: (bool value) {
                    setState(() {
                      isWorking = value;
                      if (isWorking) {
                        isAvailable = false; // Unavailable when working
                      }
                    });
                  },
                  onTap: () {},
                  onDoubleTap: () {},
                  onSwipe: () {},
                ),
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              height: MediaQuery.of(context).size.height / 2,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator()) // Show loading spinner when fetching data
                  : !isWorking
                  ? patientData()
                  : Card(
                child: Image.network(
                    "https://img.freepik.com/free-vector/lazy-raccoon-sleeping-cartoon_125446-631.jpg?size=338&ext=jpg"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget patientData() {
    return GestureDetector(
      onTap: () async {
        setState(() {
          isLoading = true; // Set loading state to true
        });
        await currentLoc(); // Ensure location is fetched
        address = await getAddress(locationData[0], locationData[1]); // Fetch the address
        locationData = [0, 0]; // Simulate location (use actual location data here)

        setState(() {
          isLoading = false; // Set loading state to false after fetching location
        });
      },
      child: Card(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Current Patient",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Image.network(
                "https://www.zyrgon.com/wp-content/uploads/2019/06/googlemaps-Zyrgon.jpg"),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(address),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Location: 0, 0"), // Use real coordinates here
            ),
          ],
        ),
      ),
    );
  }

  Future<void> currentLoc() async {
    currLoc = await getLoc(); // Fetch location
    print(currLoc); // Use or store the location as needed
    locationData = [0, 0]; // Use actual location data here
  }

  Future<String> getLoc() async {
    loc.Location location = loc.Location();
    loc.LocationData currentLocation = await location.getLocation();
    return '${currentLocation.latitude}, ${currentLocation.longitude}'; // Example return
  }

  Future<String> getAddress(double lat, double lon) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    return placemarks.isNotEmpty ? placemarks.first.street ?? 'No address found' : 'No address found';
  }
}