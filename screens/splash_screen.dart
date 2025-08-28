import 'dart:async';

import 'package:doobi/firebase_initializer.dart';
import 'package:doobi/screens/main_screen.dart';
import 'package:doobi/screens/userinfo_screen.dart';
import 'package:doobi/services/navigation_service.dart';
import 'package:doobi/services/user_service.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  double _loadingProgress = 0.0;
  bool _isNavigating = false;

  final UserService _userService = UserService();
  final NavigationService _navigationService = NavigationService();

  @override
  void initState() {
    super.initState();
    AppLogger.event('Splash screen initialized');

    // Set fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Setup animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Initialize app
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Start loading animation
      _startLoadingAnimation();

      // Wait a bit to ensure UI is rendered before heavy operations
      await Future.delayed(Duration(milliseconds: 500));

      // Check if user exists and navigate accordingly
      await _checkExistingUser();
    } catch (e) {
      AppLogger.error('Error in app initialization', e);
      // Ensure we at least navigate to user info on error
      _navigateToUserInfoScreen();
    }
  }

  void _startLoadingAnimation() {
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _loadingProgress += 0.02;

        if (_loadingProgress >= 1.0) {
          timer.cancel();
          // Navigation is handled by _checkExistingUser()
        }
      });
    });
  }

  Future<void> _checkExistingUser() async {
    try {
      // Prevent multiple navigation attempts
      if (_isNavigating) return;

      // Get user from database
      final existingUser = await _userService.getUser();
      AppLogger.debug(
        'User check result: ${existingUser != null ? "User exists" : "No user found"}',
      );

      // Wait for loading animation to reach at least 70%
      while (mounted && _loadingProgress < 0.7) {
        await Future.delayed(Duration(milliseconds: 50));
      }

      // Only navigate if mounted and not already navigating
      if (mounted && !_isNavigating) {
        _isNavigating = true;

        // Navigate to the appropriate screen based on user existence
        if (existingUser != null) {
          _navigateToMainScreen();
        } else {
          // Wait for loading animation to complete
          while (mounted && _loadingProgress < 1.0) {
            await Future.delayed(Duration(milliseconds: 50));
          }
          _navigateToUserInfoScreen();
        }
      }
    } catch (e) {
      AppLogger.error('Error checking user', e);
      // Handle error - ensure we still navigate to UserInfoScreen
      if (mounted && !_isNavigating) {
        _isNavigating = true;
        _navigateToUserInfoScreen();
      }
    }
  }

  void _navigateToMainScreen() {
    AppLogger.event('Navigating to main screen');
    Navigator.of(context).pushReplacement(
      _navigationService.customPageTransition(page: MainScreen()),
    );
  }

  void _navigateToUserInfoScreen() {
    AppLogger.event('Navigating to user info screen');
    // 전역 firebase 인스턴스 사용
    Navigator.of(context).pushReplacement(
      _navigationService.customPageTransition(
        page: UserInfoScreen(firebase: globalFirebaseInitializer),
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.debug('Disposing splash screen');
    // Reset system UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromRGBO(255, 236, 179, 1),
                const Color.fromRGBO(255, 249, 196, 1),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Lottie.asset(
                  "lottie/study.json",
                  width: 250,
                  height: 250,
                ),
              ),

              SizedBox(height: 20),

              Text(
                AppStrings.appName,
                style: GoogleFonts.indieFlower(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black12,
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                ),
              ),

              Text(
                AppStrings.appTagline,
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 40),

              // Loading component
              Container(
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: AppColors.primary.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    minHeight: 15,
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Loading text
              Text(
                AppStrings.loading,
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
