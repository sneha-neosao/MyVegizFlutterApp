import 'dart:async';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/services/notification_service.dart';
import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await locationService.requestPermissionAndFetchLocation();
    } catch (e) {
      debugPrint("Location Error: $e");
    }

    // Keep splash screen visible for a pleasant duration
    await Future.delayed(const Duration(milliseconds: 2800));

    final isLoggedIn = await SecureStorage.isLoggedIn();

    try {
      await NoficationService.requestNotificationPermission();
    } catch (e) {
      debugPrint("Notification Permission Error: $e");
    }

    if (!mounted) return;

    if (isLoggedIn) {
      context.go(AppRoutePath.home);
    } else {
      context.go(AppRoutePath.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen Splash Background Image
          Image.asset(
            'assets/images/splash image.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          // Center Animated Logo
          /*Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 270.w,
              fit: BoxFit.contain,
            )
                .animate()
                .fade(duration: 700.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.65, 0.65),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                )
                .then(delay: 200.ms)
                .shimmer(
                  duration: 1400.ms,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
          ),*/

          // Bottom Circular Progress Indicator
          Positioned(
            bottom: 54.h,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 28.w,
                height: 28.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFFC8019),
                  ),
                ),
              ),
            )
                .animate()
                .fade(delay: 500.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}


