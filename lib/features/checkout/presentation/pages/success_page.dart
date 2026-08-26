import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';

class SuccessPage extends StatelessWidget {
  final bool isFoodOrder;
  const SuccessPage({super.key, this.isFoodOrder = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated Checkmark
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.green.shade600,
                  ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                      ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 12),
              Text(
                isFoodOrder
                    ? 'Your delicious food is being prepared.'
                    : 'Your grocery items are on their way to you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
              const Spacer(),
              /*
              // Track Order Button (Only for Food Orders)
              if (isFoodOrder)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushReplacement(AppRoutePath.orderTracking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Track Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5, end: 0),
              if (isFoodOrder) const SizedBox(height: 16),
              */
              // Continue Shopping Button
              TextButton(
                onPressed: () {
                  context.go(AppRoutePath.home);
                },
                child: Text(
                  'Continue Shopping',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
