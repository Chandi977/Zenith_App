import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ambulance_tracker/screens/Login/login_screen.dart';
import 'package:ambulance_tracker/Components/already_have_an_account_acheck.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Body(),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool isOtpSent = false;

  Future<void> sendOtp() async {
    final String otpApiUrl = '${dotenv.env['API_BASE_URL']}/otp/send';

    if (emailController.text.isEmpty) {
      _showError("Email is required to send OTP");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(otpApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text.trim(),
          'userType': 'user',
          'otpPurpose': 'register',
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

  Future<void> registerUser() async {
    final String registerApiUrl = '${dotenv.env['API_BASE_URL']}/users/register';

    if (fullNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        otpController.text.isEmpty) {
      _showError("All required fields must be filled");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(registerApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'password': passwordController.text.trim(),
          'address': addressController.text.trim(),
          'mobileNumber': mobileNumberController.text.trim(),
          'otp': otpController.text.trim(),
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 201) {
        _showMessage("User registered successfully");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        _showError(jsonResponse['message'] ?? "Registration failed");
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
    Size size = MediaQuery.of(context).size;
    return Container(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "SIGNUP",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
            ),
            SizedBox(height: size.height * 0.03),
            Image.asset(
              "assets/images/hands.png",
              width: size.width * 0.6,
            ),
            TextField(
              controller: fullNameController,
              decoration: InputDecoration(
                hintText: "Full Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Your Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: "Username",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                hintText: "Address (Optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: mobileNumberController,
              decoration: InputDecoration(
                hintText: "Mobile Number (Optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (isOtpSent) ...[
              SizedBox(height: size.height * 0.02),
              TextField(
                controller: otpController,
                decoration: InputDecoration(
                  hintText: "OTP",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.text,
              ),
            ],
            SizedBox(height: size.height * 0.03),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : (isOtpSent ? () => registerUser() : () => sendOtp()),
              child: Text(isLoading
                  ? "Please wait..."
                  : (isOtpSent ? "SIGNUP" : "SEND OTP")),
            ),
            SizedBox(height: size.height * 0.03),
            AlreadyHaveAnAccountCheck(
              login: false,
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}