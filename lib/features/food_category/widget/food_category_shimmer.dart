import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../widgets/shimmer_placeholder.dart';

class FoodCategoryShimmer extends StatelessWidget {
  const FoodCategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          // "What's in your mind?" title shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ShimmerPlaceholder.rounded(height: 20.h, width: 200.w),
          ),
          SizedBox(height: 16.h),
          // Categories circular shimmer
          SizedBox(
            height: 110.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Column(
                    children: [
                      ShimmerPlaceholder.circular(width: 75.w, height: 75.w),
                      SizedBox(height: 8.h),
                      ShimmerPlaceholder.rounded(height: 12.h, width: 55.w),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
          // Filter bar shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ShimmerPlaceholder.rounded(
                    height: 32.h,
                    width: index == 0 ? 80.w : 40.w,
                    borderRadius: 8.w,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          // Horizontal Card Section Shimmer (e.g. Snack Points)
          _buildHorizontalCardShimmer(),
          SizedBox(height: 24.h),
          // Another Horizontal Card Section Shimmer
          _buildHorizontalCardShimmer(),
        ],
      ),
    );
  }

  Widget _buildHorizontalCardShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: ShimmerPlaceholder.rounded(height: 18.h, width: 150.w),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 220.w,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder.rounded(
                      height: 140.w,
                      width: 150.w,
                      borderRadius: 16.w,
                    ),
                    SizedBox(height: 8.h),
                    ShimmerPlaceholder.rounded(height: 14.h, width: 120.w),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        ShimmerPlaceholder.rounded(height: 12.h, width: 40.w),
                        SizedBox(width: 8.w),
                        ShimmerPlaceholder.rounded(height: 12.h, width: 60.w),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
