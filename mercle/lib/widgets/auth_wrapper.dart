import 'package:flutter/material.dart';
import 'package:mercle/services/auth_service.dart';
import 'package:mercle/features/onboarding/phoneverification.dart';
import 'package:mercle/features/face-scan/screens/facescan-home.dart';
import 'package:mercle/features/onboarding/splashscreen.dart';
import 'package:mercle/navbar.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isOnboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuthenticated = await AuthService.isAuthenticated();
      final isOnboardingComplete = await AuthService.isOnboardingComplete();

      if (isAuthenticated) {
        // Verify token is still valid by making a test call
        final userResult = await AuthService.getCurrentUser();
        final tokenValid =
            userResult['success'] && !userResult.containsKey('requiresAuth');

        setState(() {
          _isAuthenticated = tokenValid;
          _isOnboardingComplete = isOnboardingComplete;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isAuthenticated = false;
          _isOnboardingComplete = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isOnboardingComplete = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen(); // Show splash while checking auth
    }

    if (_isAuthenticated && _isOnboardingComplete) {
      return const NavBar(); // User completed everything, go to main app
    } else if (_isAuthenticated) {
      return const FaceScanSetup(); // User is authenticated but needs face scan
    } else {
      return const PhoneVerificationScreen(); // User needs to authenticate
    }
  }
}
