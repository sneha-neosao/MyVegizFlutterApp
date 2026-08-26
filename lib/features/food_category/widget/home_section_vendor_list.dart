import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../routes/app_route_path.dart';
import '../data/models/vendor_home_section_model.dart';
import 'veg_nonveg_filter.dart';

class HomeSectionVendorList extends StatelessWidget {
  final List<HomeSectionVendor> vendors;
  final String title;
  final String? description;

  const HomeSectionVendorList({
    super.key,
    required this.vendors,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  description!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 235.w,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              return _buildVendorCard(context, vendors[index]);
            },
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildVendorCard(BuildContext context, HomeSectionVendor vendor) {
    final bool isEnabled = vendor.isServiceable;

    return GestureDetector(
      onTap: !isEnabled
          ? () {
              SnackbarUtils.showSuccessSnackbar(
                context,
                "restaurant is unavailable",
              );
            }
          : () {
              context.push(
                AppRoutePath.restaurantDetails,
                extra: {
                  "id": vendor.id,
                  "name": vendor.entityName ?? "Restaurant",
                  "image": vendor.entityImage ?? "",
                  "isServiceable": isEnabled,
                  "isDeliverable": isEnabled,
                  "distanceKm": vendor.distanceKm,
                },
              );
            },
      child: Container(
        width: 155.w,
        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  vendor.entityImage ?? '',
                  height: 140.w,
                  width: 155.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140.w,
                    width: 155.w,
                    color: Colors.orange.shade50,
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.orange.shade200,
                      size: 32.w,
                    ),
                  ),
                ),
                if (!isEnabled)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          child: Text(
                            "UNAVAILABLE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vendor.entityName ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      FoodTypeIcon(foodType: vendor.foodType),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: (vendor.avgRating ?? 0.0) >= 4.0
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(4.w),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: (vendor.avgRating ?? 0.0) >= 4.0
                                  ? const Color(0xFF0F8A5F)
                                  : Colors.amber.shade700,
                              size: 11.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              (vendor.avgRating ?? 0.0).toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: (vendor.avgRating ?? 0.0) >= 4.0
                                    ? const Color(0xFF0F8A5F)
                                    : Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "•",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.access_time,
                        color: Colors.grey.shade600,
                        size: 11.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        "30-40 mins", // Placeholder or calculated time
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (vendor.distanceKm != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      formatDistance(vendor.distanceKm!),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
