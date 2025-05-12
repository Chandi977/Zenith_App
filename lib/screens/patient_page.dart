import 'package:ambulance_tracker/services/MapUtils.dart';
import 'package:ambulance_tracker/services/current_location.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  _PatientPageState createState() => _PatientPageState();
}

String currLoc = "";
var details = [];
String date_time = "", address = "";
var loc = [];

class _PatientPageState extends State<PatientPage> {
  @override
  void initState() {
    super.initState();
    currentLoc();
  }

  @override
  Widget build(BuildContext context) {
    // No need to call currentLoc() in build every time
    if (loc.isEmpty) {
      currentLoc();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
      ),
      backgroundColor: const Color.fromRGBO(222, 224, 252, 1),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              child: const Text("Refresh location"),
              onPressed: () async {
                currentLoc();

                setState(() {
                  // These values are updated when the location is refreshed
                  date_time = currLoc.split("{}")[0];
                  address = currLoc.split("{}")[2];
                  loc = currLoc.split("{}")[1].split(" , ");
                });
              },
            ),
            Card(
              child: Column(
                children: [
                  Text("Date: $date_time"),
                  Text("Address: $address"),
                ],
              ),
            ),
            ElevatedButton(
              child: const Text("See nearby hospitals in GMap"),
              onPressed: () async {
                if (loc.isNotEmpty) {
                  MapUtils.openMap(double.parse(loc[0]), double.parse(loc[1]));
                }
              },
            ),
            Container(
              child: SingleChildScrollView(
                child: Column(
                  children: getHosps(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void currentLoc() async {
    currLoc = await getLoc();
    date_time = currLoc.split("{}")[0];
    address = currLoc.split("{}")[2];
    loc = currLoc.split("{}")[1].split(" , ");
  }

  List<Widget> getHosps() {
    List<Widget> lst = [];
    for (int i = 1; i <= 4; i++) {
      lst.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 50,
          height: MediaQuery.of(context).size.height / 7,
          child: Card(
            child: Column(
              children: [
                Text(
                  "Hospital $i",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Text("Hospital Location"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        Fluttertoast.showToast(
                          msg: "Hospital chosen, you'll be notified about the ambulance",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Fluttertoast.showToast(
                          msg: "Hospital rejected",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      },
                    ),
                    const Icon(Icons.location_on)
                  ],
                ),
              ],
            ),
          ),
        ),
      ));
    }

    return lst;
  }
}
