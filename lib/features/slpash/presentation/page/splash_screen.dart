import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/services/notification_service.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    final controller = VideoPlayerController.asset('assets/videos/splash.mp4');
    _controller = controller;

    Duration splashDuration = const Duration(milliseconds: 3000);

    try {
      await controller.initialize();
      controller.setLooping(false);
      await controller.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
      if (controller.value.duration > Duration.zero) {
        splashDuration = controller.value.duration;
      }
    } catch (e) {
      debugPrint("Splash video initialization error: $e");
    }

    // Step 1: Play the video directly to completion without permission interruptions
    await Future.delayed(splashDuration);

    if (!mounted) return;

    // Step 2: Now that splash video ended, request all permissions
    await _requestPermissions();

    if (!mounted) return;

    // Step 3: Navigate to Home or Login
    await _navigateToNextScreen();
  }

  Future<void> _requestPermissions() async {
    try {
      await locationService.requestPermissionAndFetchLocation();
    } catch (e) {
      debugPrint("Location Permission Error: $e");
    }

    try {
      await NoficationService.requestNotificationPermission();
    } catch (e) {
      debugPrint("Notification Permission Error: $e");
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final isLoggedIn = await SecureStorage.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      context.go(AppRoutePath.home);
    } else {
      context.go(AppRoutePath.login);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/login_bg.png'), context);
    precacheImage(const AssetImage('assets/images/signup_bg.png'), context);
    precacheImage(const AssetImage('assets/images/bottom_img.png'), context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: (_isVideoInitialized &&
                controller != null &&
                controller.value.isInitialized)
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width > 0
                      ? controller.value.size.width
                      : (controller.value.aspectRatio > 0
                          ? controller.value.aspectRatio
                          : 16),
                  height: controller.value.size.height > 0
                      ? controller.value.size.height
                      : 9,
                  child: VideoPlayer(controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
