import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ambulance_tracker/AmbulanceDriver/DriverHome_screen.dart';
import 'package:ambulance_tracker/AmbulanceDriver/AmbulanceAuth_service.dart';
import 'package:ambulance_tracker/AmbulanceDriver/Driver_Register.dart';
import 'package:geolocator/geolocator.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  _DriverLoginScreenState createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool isOtpSent = false;

  Future<void> sendOtp() async {
    final String otpUrl = '${dotenv.env['API_BASE_URL']}/otp/send';

    if (emailController.text.isEmpty) {
      _showError("Email is required");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(otpUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text.trim(),
          'userType': 'ambulance',
          'otpPurpose': 'login',
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        setState(() {
          isOtpSent = true;
        });
        _showMessage("OTP sent successfully");
      } else {
        _showError(jsonResponse['message'] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loginDriver() async {
    final String loginUrl = '${dotenv.env['API_BASE_URL']}/ambulanceDriver/login';

    if (otpController.text.isEmpty || passwordController.text.isEmpty) {
      _showError("Please enter OTP and password");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Fetch current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text.trim(),
          'otp': otpController.text.trim(),
          'password': passwordController.text.trim(),
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final driverData = jsonResponse['data']['driver'] ?? {};
        final accessToken = jsonResponse['data']['accessToken'] ?? '';
        final refreshToken = jsonResponse['data']['refreshToken'] ?? '';

        final AuthService authService = AuthService();
        await authService.saveDriverData(
          id: driverData['_id'] ?? '',
          name: driverData['driverName'] ?? '',
          email: driverData['email'] ?? '',
          contactNumber: driverData['contactNumber'] ?? '',
          age: driverData['age']?.toString() ?? '',
          drivingExperience: driverData['drivingExperience']?.toString() ?? '',
          govtIdNumber: driverData['govtIdNumber'] ?? '',
          assignedShift: driverData['assignedShift'] ?? '',
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
          accessToken: accessToken,
          refreshToken: refreshToken,
          available: driverData['available']?.toString() ?? '',
          ambulance: driverData['ambulance']?.toString() ?? '',
          userRatings: driverData['userRatings']?.toString() ?? '',
          createdAt: driverData['createdAt'] ?? '',
          updatedAt: driverData['updatedAt'] ?? '',
        );

        _showMessage(jsonResponse['message']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        );
      } else {
        _showError(jsonResponse['message'] ?? "Login failed");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: 400,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 30,
                    width: 80,
                    height: 200,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/light-1.png'),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 140,
                    width: 80,
                    height: 150,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/light-2.png'),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    top: 40,
                    width: 80,
                    height: 150,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/clock.png'),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    child: Container(
                      margin: const EdgeInsets.only(top: 50),
                      child: const Center(
                        child: Text(
                          "Driver Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(255, 0, 0, .2),
                          blurRadius: 20.0,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Email or Phone number",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        if (isOtpSent) const Divider(color: Colors.grey),
                        if (isOtpSent)
                          TextField(
                            controller: otpController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter OTP",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        if (isOtpSent) const Divider(color: Colors.grey),
                        if (isOtpSent)
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Password",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: isLoading
                          ? null
                          : (isOtpSent ? loginDriver : sendOtp),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isOtpSent ? "Login" : "Send OTP"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DriverRegisterScreen(),
                          ),
                        );
                      },
                      child: const Text("Sign Up"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}