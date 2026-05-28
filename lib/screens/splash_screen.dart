import 'package:flutter/material.dart';
import 'package:guitar_app/screens/guitar_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

     Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GuitarScreen()),
        );      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          // gradient: RadialGradient(
          //   center: Alignment.center,
          //   radius: 1.4,
          //   colors: [
          //     Colors.black,
          //     Colors.black,
          //   ],
          //   stops: const [0.5, 1.0],
          // ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/guitar_app_logo.png',
            width: 266,
            height: 275,
            fit: BoxFit.contain,
          )

        ),
      ),
    );
  }
}