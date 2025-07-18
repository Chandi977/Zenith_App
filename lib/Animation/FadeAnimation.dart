import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class FadeAnimation extends StatelessWidget {
  final double delay;
  final Widget child;

  const FadeAnimation(this.delay, this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    final tween = MovieTween()
      ..scene(
        begin: Duration.zero,
        end: const Duration(milliseconds: 500),
      ).tween("opacity", Tween(begin: 0.0, end: 1.0))
      ..scene(
        begin: Duration.zero,
        end: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      ).tween("translateY", Tween(begin: -30.0, end: 0.0));

    return CustomAnimationBuilder<Movie>(
      delay: Duration(milliseconds: (500 * delay).round()),
      duration: tween.duration,
      tween: tween,
      builder: (context, value, child) => Opacity(
        opacity: value.get("opacity"),
        child: Transform.translate(
          offset: Offset(0, value.get("translateY")),
          child: child,
        ),
      ),
      child: child,
    );
  }
}