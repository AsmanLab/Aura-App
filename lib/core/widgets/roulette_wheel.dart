import 'dart:math';
import 'package:flutter/material.dart';

class RouletteWheel extends StatefulWidget {
  final AnimationController controller;
  final bool isSpinning;

  const RouletteWheel({
    super.key,
    required this.controller,
    required this.isSpinning,
  });

  @override
  State<RouletteWheel> createState() => _RouletteWheelState();
}

class _RouletteWheelState extends State<RouletteWheel> {
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationAnimation = Tween<double>(begin: 0, end: 6 * pi).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant RouletteWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _rotationAnimation = Tween<double>(begin: 0, end: 6 * pi).animate(
        CurvedAnimation(
          parent: widget.controller,
          curve: Curves.easeInOutCubic,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wheel
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.green,
                  Colors.red,
                  Colors.green,
                  Colors.red,
                  Colors.green,
                  Colors.red,
                ],
                stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              ),
              border: Border.all(color: Colors.black26, width: 4),
            ),
            child: const Center(
              child: Icon(Icons.star, size: 32, color: Colors.white),
            ),
          ),

          // Pin
          Positioned(
            top: 0,
            child: Icon(
              Icons.arrow_drop_down,
              size: 40,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
