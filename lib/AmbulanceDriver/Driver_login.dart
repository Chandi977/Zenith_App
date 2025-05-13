import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    const String otpUrl = 'https://zenith-oy4b.onrender.com/api/v1/otp/send';

    if (emailController.text.isEmpty) {
      _showError("Please enter your email");
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
    const String loginUrl = 'https://zenith-oy4b.onrender.com/api/v1/ambulanceDriver/login';

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        otpController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'otp': otpController.text.trim(),
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        _showMessage("Login successful");
        // Navigate to the driver's home screen
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
      appBar: AppBar(title: const Text("Driver Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            if (isOtpSent)
              TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: "OTP"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : (isOtpSent ? loginDriver : sendOtp),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isOtpSent ? "Login" : "Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}