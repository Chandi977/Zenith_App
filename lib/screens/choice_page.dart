import 'package:ambulance_tracker/Animation/FadeAnimation.dart';
import 'package:ambulance_tracker/screens/patient_page.dart';
import 'package:flutter/material.dart';

import 'driver_page.dart';
import 'hospital_page.dart';

class ChoicePage extends StatelessWidget {
  const ChoicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 400,
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/background.png'),
                        fit: BoxFit.fill)),
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
                              "Role",
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
                padding: const EdgeInsets.all(20.0),
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
                              color: Color.fromRGBO(143, 148, 251, .2),
                              blurRadius: 20.0,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeAnimation(
                      2,
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                              const PatientPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "User",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeAnimation(
                      2,
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                              const HospitalPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Hospital Reception",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeAnimation(
                      2,
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                              const DriverPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Driver",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
