import 'package:flutter/material.dart';
import 'package:ambulance_tracker/User/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _authService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading user data'));
        } else {
          final userData = snapshot.data!;
          print(userData['accessToken']);
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Id: ${userData['_id']}'),
                  Text('Name: ${userData['name']}'),
                  Text('Email: ${userData['email']}'),
                  Text('Access Token: ${userData['accessToken']}'),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}