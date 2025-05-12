import 'package:flutter/material.dart';
import 'package:ambulance_tracker/constants.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback press;
  final Color color, textColor;

  const RoundedButton({
    super.key,
    required this.text,
    required this.press,
    this.color = kPrimaryColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: size.width * 0.8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: newElevatedButton(),
      ),
    );
  }

  Widget newElevatedButton() {
    return ElevatedButton(
      onPressed: press,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        textStyle: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor),
      ),
    );
  }
}
