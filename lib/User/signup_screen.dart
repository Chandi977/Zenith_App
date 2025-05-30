import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ambulance_tracker/User/home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  File? avatarImage;
  bool isLoading = false;
  bool isOtpSent = false;

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
          'userType': 'user',
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

  Future<void> pickAvatarImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          avatarImage = file;
        });
      }
    } on FormatException catch (e) {
      debugPrint('Format error: ${e.message}');
      showMessage('Invalid image format');
    } catch (e) {
      debugPrint('Error picking file: $e');
      showMessage('Error selecting image');
    }
  }

  Future<void> registerUser() async {
    final String registerUrl = '${dotenv.env['API_BASE_URL']}/users/register';

    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        otpController.text.trim().isEmpty) {
      showMessage("Full Name, Email, Username, Password, and OTP are required");

      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
      showMessage("Please enter a valid email address");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(registerUrl));
      request.fields['fullName'] = fullNameController.text.trim();
      request.fields['email'] = emailController.text.trim();
      request.fields['username'] = usernameController.text.trim();
      request.fields['password'] = passwordController.text.trim();
      request.fields['otp'] = otpController.text.trim();

      if (addressController.text.isNotEmpty) {
        request.fields['address'] = addressController.text.trim();
      }
      if (mobileNumberController.text.isNotEmpty) {
        request.fields['mobileNumber'] = mobileNumberController.text.trim();
      }

      if (avatarImage != null) {
        final mimeType = lookupMimeType(avatarImage!.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            avatarImage!.path,
            contentType: MediaType.parse(mimeType ?? 'application/octet-stream'),
            filename: basename(avatarImage!.path),
          ),
        );
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(resBody);

      if (!mounted) return;

      if (response.statusCode == 201 && jsonResponse['success'] == true) {
        showMessage("User registered successfully");
        Navigator.pushReplacement(
          this.context,
          MaterialPageRoute(builder: (context) => const HomePage()),
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

  void showMessage(String message) {
    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.deepPurple),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.deepPurple, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Signup"),
        backgroundColor: Colors.deepPurple,
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
            TextField(
              controller: otpController,
              decoration: inputDecoration("OTP"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fullNameController,
              decoration: inputDecoration("Full Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: inputDecoration("Username"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: inputDecoration("Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: inputDecoration("Address (Optional)"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mobileNumberController,
              decoration: inputDecoration("Mobile Number (Optional)"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: pickAvatarImage,
                child: avatarImage != null
                    ? ClipOval(
                  child: Image.file(
                    avatarImage!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                )
                    : Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 50, color: Colors.deepPurple),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: registerUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
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
                "Sign Up",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}