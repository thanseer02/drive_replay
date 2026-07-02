import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';
import '../../../widgets/button_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  static const String routeName = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.spMin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Icon(
                Icons.speed,
                size: 100.spMin,
                color: AppColors.primary,
              ),
              SizedBox(height: 32.spMin),
              Text(
                'Record Every Journey',
                style: AppStyles.tsS24W700CFFFFFF,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.spMin),
              Text(
                'Turn your phone into a smart dashcam. Analyze your driving, replay trips, and improve your score.',
                style: AppStyles.tsS16W400CFFFFFF,
                textAlign: TextAlign.center,
              ),
              Spacer(),
              PrimaryButton(
                text: 'Get Started',
                onPressed: () => context.go('/login'),
              ),
              SizedBox(height: 16.spMin),
            ],
          ),
        ),
      ),
    );
  }
}
