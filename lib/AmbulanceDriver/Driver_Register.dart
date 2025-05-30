import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ambulance_tracker/AmbulanceDriver/DriverHome_screen.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController drivingExpController = TextEditingController();
  final TextEditingController govtIdNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController assignedShiftController = TextEditingController();

  bool isLoading = false;
  bool isOtpSent = false;
  List<String> hospitalNames = [];
  final List<String> assignedShiftOptions = ["Morning", "Afternoon", "Night", "SOS"];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showMessage("Location services are disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showMessage("Location permissions are denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showMessage("Location permissions are permanently denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _fetchNearbyHospitals(position.latitude, position.longitude);
    } catch (e) {
      showMessage("Failed to fetch location: $e");
    }
  }

  Future<void> _fetchNearbyHospitals(double lat, double lng) async {
    final String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      showMessage("Google Maps API key is missing");
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=hospital&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List results = jsonResponse['results'] ?? [];
        setState(() {
          if (results.isNotEmpty) {
            hospitalNames = results.map((e) => e['name'] as String).toList();
          } else {
            showMessage("No hospitals found nearby");
          }
        });
      } else {
        showMessage("Failed to fetch hospitals");
      }
    } catch (e) {
      showMessage("Error fetching hospitals: $e");
    }
  }

  Future<void> sendOtp() async {
    final String apiUrl = '${dotenv.env['API_BASE_URL']}/otp/send';

    if (emailController.text.isEmpty) {
      showMessage("Please enter your email");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text.trim(),
          'userType': 'ambulance',
          'otpPurpose': 'register',
        }),
      );

      if (response.body.isNotEmpty) {
        final jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 && jsonResponse['success'] == true) {
          setState(() {
            isOtpSent = true;
          });
          showMessage("OTP sent successfully");
        } else {
          showMessage(jsonResponse['message'] ?? "Failed to send OTP");
        }
      } else {
        showMessage("Empty response from server");
      }
    } catch (e) {
      showMessage("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> registerDriver() async {
    final String registerUrl = '${dotenv.env['API_BASE_URL']}/ambulanceDriver/register';

    if (driverNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        contactNumberController.text.isEmpty ||
        ageController.text.isEmpty ||
        drivingExpController.text.isEmpty ||
        govtIdNumberController.text.isEmpty ||
        passwordController.text.isEmpty ||
        otpController.text.isEmpty ||
        hospitalController.text.isEmpty ||
        assignedShiftController.text.isEmpty) {
      showMessage("Please fill in all required fields");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'driverName': driverNameController.text.trim(),
          'email': emailController.text.trim(),
          'contactNumber': contactNumberController.text.trim(),
          'age': ageController.text.trim(),
          'drivingExperience': drivingExpController.text.trim(),
          'govtIdNumber': govtIdNumberController.text.trim(),
          'password': passwordController.text.trim(),
          'otp': otpController.text.trim(),
          'hospital': hospitalController.text.trim(),
          'assignedShift': assignedShiftController.text.trim(),
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && jsonResponse['success'] == true) {
        await saveDriverData(jsonResponse['data']);
        showMessage("Driver registered successfully");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        );
      } else {
        showMessage(jsonResponse['message'] ?? "Registration failed");
      }
    } catch (e) {
      if (mounted) showMessage("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveDriverData(Map<String, dynamic> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverName', data['driverName'] ?? '');
    await prefs.setString('email', data['email'] ?? '');
    await prefs.setString('contactNumber', data['contactNumber'] ?? '');
    await prefs.setString('age', data['age']?.toString() ?? '');
    await prefs.setString('drivingExperience', data['drivingExperience']?.toString() ?? '');
    await prefs.setString('govtIdNumber', data['govtIdNumber'] ?? '');
    await prefs.setString('assignedShift', data['assignedShift'] ?? '');
    await prefs.setString('accessToken', data['accessToken'] ?? '');
    await prefs.setString('refreshToken', data['refreshToken'] ?? '');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.red),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Registration"),
        backgroundColor: Colors.red,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                suffixIcon: IconButton(
                  icon: isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: isLoading ? null : sendOtp,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            if (isOtpSent) ...[
              TextField(
                controller: otpController,
                decoration: inputDecoration("OTP"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: driverNameController,
                decoration: inputDecoration("Driver Name"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactNumberController,
                decoration: inputDecoration("Contact Number"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                decoration: inputDecoration("Age"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: drivingExpController,
                decoration: inputDecoration("Driving Experience"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: govtIdNumberController,
                decoration: inputDecoration("Government ID Number"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: inputDecoration("Hospital"),
                items: hospitalNames.isNotEmpty
                    ? hospitalNames.map((hospital) {
                  return DropdownMenuItem(
                    value: hospital,
                    child: Text(hospital),
                  );
                }).toList()
                    : [const DropdownMenuItem(value: '', child: Text('No hospitals available'))],
                onChanged: (value) {
                  hospitalController.text = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: inputDecoration("Assigned Shift"),
                items: assignedShiftOptions.map((shift) {
                  return DropdownMenuItem(
                    value: shift,
                    child: Text(shift),
                  );
                }).toList(),
                onChanged: (value) {
                  assignedShiftController.text = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: inputDecoration("Password"),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: registerDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Text(
                  "Register Driver",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}