import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ambulance_tracker/Animation/FadeAnimation.dart';
import 'package:ambulance_tracker/screens/choice_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool isOtpSent = false;

  Future<void> sendOtp() async {
    const String apiUrl = 'https://zenith-oy4b.onrender.com/api/v1/otp/send';

    if (emailController.text.isEmpty) {
      _showError("Please enter your email or username");
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
          'userType': 'user',
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

  Future<void> verifyOtpAndLogin() async {
    const String apiUrl = 'https://zenith-oy4b.onrender.com/api/v1/users/login';

    if (otpController.text.isEmpty || passwordController.text.isEmpty) {
      _showError("Please enter OTP and password");
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
          'otp': otpController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        _showMessage("Login successful");
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const ChoicePage(),
        ));
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
                    child: FadeAnimation(
                      1,
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/light-1.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 140,
                    width: 80,
                    height: 150,
                    child: FadeAnimation(
                      1.3,
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/light-2.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    top: 40,
                    width: 80,
                    height: 150,
                    child: FadeAnimation(
                      1.5,
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/clock.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    child: FadeAnimation(
                      1.6,
                      Container(
                        margin: const EdgeInsets.only(top: 50),
                        child: const Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
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
                  FadeAnimation(
                    1.8,
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
                              hintStyle:
                              TextStyle(color: Colors.grey.shade400),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          if (isOtpSent) const Divider(color: Colors.grey),
                          if (isOtpSent)
                            TextField(
                              controller: otpController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter OTP",
                                hintStyle:
                                TextStyle(color: Colors.grey.shade400),
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
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
                                hintStyle:
                                TextStyle(color: Colors.grey.shade400),
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeAnimation(
                    2,
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
                            : (isOtpSent ? verifyOtpAndLogin : sendOtp),
                        child: isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : Text(isOtpSent ? "Verify & Login" : "Send OTP"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  const FadeAnimation(
                    1.5,
                    Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}