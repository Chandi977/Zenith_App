import 'package:flutter/material.dart';

import 'new_driver_page.dart';
import 'package:ambulance_tracker/services/drivers.dart';

class ShowDrivers extends StatefulWidget {
  const ShowDrivers({super.key});

  @override
  _ShowDriversState createState() => _ShowDriversState();
}

class _ShowDriversState extends State<ShowDrivers> {
  @override
  Widget build(BuildContext context) {
    List<List<Widget>> tabCats = sortDrivers();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("All drivers"),
          backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
          bottom: const TabBar(tabs: [
            Tab(
              icon: Icon(Icons.location_on),
            ),
            Tab(
              text: "Available",
            ),
            Tab(text: "Working"),
            Tab(text: "Offline"),
          ]),
          actions: <Widget>[
            IconButton(
                icon: const Icon(
                  Icons.person_add_alt_1,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NewDriversCode()),
                    )),
          ],
        ),
        body: TabBarView(children: [
          const Column(),
          SingleChildScrollView(
            child: Column(
              children: tabCats[0],
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: tabCats[2],
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: tabCats[1],
            ),
          ),
        ]),
      ),
    );
  }

  Widget driverCard(String name, Color col, String status, String regId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
          width: MediaQuery.of(context).size.width - 50,
          height: MediaQuery.of(context).size.height / 6,
          child: Card(
            color: col,
            child: Column(children: [
              const Row(
                children: [
                  // Image.network(
                  //   "https://upload.wikimedia.org/wikipedia/commons/thumb/5/59/User-avatar.svg/1024px-User-avatar.svg.png")
                ],
              ),
              Text(name),
              Text(regId),
              Text(status)
            ]),
          )),
    );
  }

  List<List<Widget>> sortDrivers() {
    List<List<Widget>> lst = [];

    List<Widget> available = [];
    List<Widget> offline = [];
    List<Widget> working = [];

    for (var e in drivers) {
      if (e['isFree'] && !e['isAvailable']) {
        offline.add(driverCard(e['name'], const Color.fromRGBO(235, 233, 228, 1),
            "Offline", e["reg_id"]));
      } else if (e['isFree']) {
        available.add(driverCard(e['name'], const Color.fromRGBO(217, 250, 195, 1),
            "Available", e["reg_id"]));
      } else if (!e['isFree'] || !e['isAvailable']) {
        working.add(driverCard(
            e['name'], const Color.fromRGBO(250, 152, 152, 1), "Busy", e["reg_id"]));
      }
      lst.add(available);
      lst.add(offline);
      lst.add(working);
    }

    return lst;
  }
}
