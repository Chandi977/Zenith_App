import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/Welcome/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Absolute Path: ${File("C:/Users/pappu/StudioProjects/ambulance_tracker/.env").absolute.path}');
  print('Env File Exists: ${File("C:/Users/pappu/StudioProjects/ambulance_tracker/.env").existsSync()}');
  await dotenv.load(fileName: ".env");
  // await dotenv.load(); // Load environment variables
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    ),
  );
}




