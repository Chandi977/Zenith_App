import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NewDriversCode extends StatefulWidget {
  const NewDriversCode({super.key});

  @override
  _NewDriversCodeState createState() => _NewDriversCodeState();
}

class _NewDriversCodeState extends State<NewDriversCode> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final visitorsController = TextEditingController();
  final timeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 48),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: RichText(
                    text: const TextSpan(
                      text: "Add New Drivers",
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    text: "Details",
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: RichText(
                          text: const TextSpan(
                            text: "Name",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Enter name";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color.fromRGBO(143, 148, 251, 1),
                                width: 2.0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          hintText: "Driver's Name",
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: RichText(
                          text: const TextSpan(
                            text: "Registration ID",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: visitorsController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Enter the ID";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color.fromRGBO(143, 148, 251, 1),
                                width: 2.0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          hintText: "Reg. ID",
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: RichText(
                          text: const TextSpan(
                            text: "Years of experience",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: timeController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter the years of experience";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color.fromRGBO(143, 148, 251, 1),
                                width: 2.0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          hintText: "Enter years of experience",
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          Fluttertoast.showToast(
                            msg: "Driver added",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Add Driver"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
