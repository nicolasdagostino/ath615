import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/bottom_nav_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.fitness_center, color: Colors.white, size: 72),
              SizedBox(height: 20),
              Text(
                'ATH615',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 34,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Train hard. Stay consistent.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
