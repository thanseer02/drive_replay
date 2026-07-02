import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'onboarding_screen.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';
  
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24.spMin),
              child: Image.asset(
                'assets/images/logo.png',
                width: 120.spMin,
                height: 120.spMin,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 24.spMin),
            Text(
              'Drive Replay',
              style: AppStyles.tsS32W700CFFFFFF,
            ),
            SizedBox(height: 8.spMin),
            Text(
              'Your Smart Black Box',
              style: AppStyles.tsS16W400CFFFFFF,
            ),
          ],
        ),
      ),
    );
  }
}
