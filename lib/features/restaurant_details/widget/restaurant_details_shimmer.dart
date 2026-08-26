import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../widgets/shimmer_placeholder.dart';

class RestaurantDetailsShimmer extends StatelessWidget {
  const RestaurantDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final double safeArea = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Mockup
            Container(
              height: 250.h + safeArea,
              width: double.infinity,
              color: const Color(0xFF101014),
              padding: EdgeInsets.fromLTRB(16.w, safeArea + 16.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerPlaceholder.circular(width: 40.w, height: 40.w),
                      ShimmerPlaceholder.circular(width: 40.w, height: 40.w),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder.rounded(height: 24.h, width: 200.w),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            ShimmerPlaceholder.rounded(height: 16.h, width: 40.w),
                            SizedBox(width: 8.w),
                            ShimmerPlaceholder.rounded(height: 16.h, width: 80.w),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        const Divider(),
                        SizedBox(height: 12.h),
                        ShimmerPlaceholder.rounded(height: 16.h, width: 150.w),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar & Filters Mockup
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  ShimmerPlaceholder.rounded(height: 48.h, borderRadius: 12.w),
                  SizedBox(height: 12.h),
                  Row(
                    children: List.generate(3, (index) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ShimmerPlaceholder.rounded(
                        height: 32.h, 
                        width: index == 0 ? 80.w : 60.w,
                        borderRadius: 8.w,
                      ),
                    )),
                  ),
                ],
              ),
            ),
            
            // Menu Items Mockup
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: List.generate(3, (index) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerPlaceholder.rounded(height: 20.h, width: 150.w),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        ],
                      ),
                      const Divider(),
                    ],
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
