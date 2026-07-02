import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../dashboard/view/dashboard_screen.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';
import '../../../widgets/button_widgets.dart';
import '../../../widgets/textfield_widgets.dart';
import '../view_model/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (authViewModel.isAuthenticated && mounted) {
      // Navigate to Home Dashboard (to be built)
      Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
    } else if (authViewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.spMin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: AppStyles.tsS32W700CFFFFFF,
              ),
              SizedBox(height: 8.spMin),
              Text(
                'Sign in to sync your trips',
                style: AppStyles.tsS16W400CFFFFFF,
              ),
              SizedBox(height: 32.spMin),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
              ),
              SizedBox(height: 16.spMin),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
              ),
              SizedBox(height: 32.spMin),
              PrimaryButton(
                text: 'Login',
                isLoading: isLoading,
                onPressed: _handleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
