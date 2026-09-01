import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/features/food_category/widget/Vendor_Item_Details_Card.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../routes/app_route_path.dart';
import 'veg_nonveg_filter.dart';
import 'filter_widget.dart';
import '../data/models/vendor_home_section_model.dart';
import 'dart:async';

// ----------------------------------------------------
// 1. Swiggy Promo Banner
// ----------------------------------------------------
class SwiggyPromoBanner extends StatefulWidget {
  final List<HomeSectionBanner> banners;

  const SwiggyPromoBanner({super.key, this.banners = const []});

  @override
  State<SwiggyPromoBanner> createState() => _SwiggyPromoBannerState();
}

class _SwiggyPromoBannerState extends State<SwiggyPromoBanner> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    if (widget.banners.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          final int nextPage = (_currentPage + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 156.h,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          _currentPage = index;
        },
        itemCount: widget.banners.length,
        itemBuilder: (context, index) {
          final banner = widget.banners[index];
          final bool isDeliverable = banner.vendorId == null || (banner.isDeliverable ?? true);
          final bool isBannerActive = banner.isActive ?? true;

          final Widget bannerCard = GestureDetector(
            onTap: !isBannerActive || !isDeliverable
                ? () {
                    SnackbarUtils.showSuccessSnackbar(
                      context,
                      "restaurant is unavailable",
                    );
                  }
                : () {
                    if (banner.vendorId != null) {
                      context.push(
                        AppRoutePath.restaurantDetails,
                        extra: {
                          "id": banner.vendorId,
                          "name": banner.entityName ?? banner.title ?? "Restaurant",
                          "image": banner.image ?? "",
                          "isFromBanner": true,
                          "isServiceable": isDeliverable,
                          "isDeliverable": isDeliverable,
                        },
                      );
                    }
                  },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    banner.image ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.orange.shade50,
                      child: Icon(
                        Icons.fastfood,
                        color: Colors.orange.shade200,
                        size: 32.w,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12.h,
                    left: 16.w,
                    right: 16.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.title ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (banner.entityName != null &&
                            banner.entityName!.isNotEmpty)
                          Text(
                            banner.entityName!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (!isDeliverable)
                    Positioned(
                      top: 12.h,
                      left: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(4.w),
                        ),
                        child: Text(
                          "Currently Unavailable",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );

          if (!isBannerActive) {
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
              child: Opacity(opacity: 0.5, child: bannerCard),
            );
          }

          if (!isDeliverable) {
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: Opacity(opacity: 0.8, child: bannerCard),
            );
          }

          return bannerCard;
        },
      ),
    );
  }
}

class RecommendedFoodsSection extends StatelessWidget {
  final List<HomeSectionVendorItem> items;
  final String title;
  final String description;

  const RecommendedFoodsSection({
    super.key,
    this.items = const [],
    this.title = 'Recommended Foods',
    this.description = 'Best Items',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      padding: EdgeInsets.only(top: 18.h, bottom: 18.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F7FF), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(color: const Color(0xFFE3EDFF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1E36).withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0E1E36),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(1.5.w),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 8.w,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              TextSpan(
                                text: description,
                                style: const TextStyle(
                                  color: Color(0xFF0E1E36),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    context.push(
                      AppRoutePath.recommendedFoodsList,
                      extra: {"items": items, "title": title},
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        "View All",
                        style: TextStyle(
                          color: const Color(0xFF0067FF),
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: const Color(0xFF0067FF),
                        size: 15.w,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // Horizontal List View
          SizedBox(
            height: 220.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return VendorProductCard(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VendorProductCard extends StatelessWidget {
  final HomeSectionVendorItem item;

  const VendorProductCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final double price = item.salePrice ?? 0.0;
    final bool isDeliverable = item.vendor?.isDeliverable ?? true;

    final Widget cardContent = GestureDetector(
      onTap: !isDeliverable || item.itemStatus == false
          ? () {
              SnackbarUtils.showSuccessSnackbar(
                context,
                item.itemStatus == false
                    ? "item is unavailable"
                    : "restaurant is unavailable",
              );
            }
          : () {
              VenderItemDetailsCard.show(context, item.id ?? 0, isDeliverable);
            },
      child: Container(
        width: 120.w,
        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Image stack with Add button
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 110.w,
                  width: 120.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.w),
                    child: Image.network(
                      item.primaryImage ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.orange.shade50,
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.orange.shade200,
                          size: 32.w,
                        ),
                      ),
                    ),
                  ),
                ),
                if (item.itemStatus != false)
                Positioned(
                  bottom: -8.h,
                  right: 8.w,
                  child: Container(
                    height: 26.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF24963F).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: const Color(0xFF24963F),
                        size: 16.w,
                      ),
                    ),
                  ),
                ),
                if (!isDeliverable || item.itemStatus == false)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16.w),
                      ),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          child: Text(
                            item.itemStatus == false ? "UNAVAILABLE" : "OUT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            // Veg Indicator dot & Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  child: FoodTypeIcon(foodType: item.cuisineType),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    item.itemName ?? '',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (item.avgRating != null && item.avgRating! > 0) ...[
              SizedBox(height: 3.h),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber.shade700,
                    size: 10.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    item.avgRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  if (item.totalReviews != null && item.totalReviews! > 0) ...[
                    SizedBox(width: 3.w),
                    Text(
                      "(${item.totalReviews})",
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            SizedBox(height: 4.h),
            // Price with crossed out original and yellow offer highlight
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFED835),
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 1.5.h,
                  ),
                  child: Text(
                    "₹${price.toInt()}",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            if (item.totalDeliveryTime != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.grey.shade600,
                    size: 11.w,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "${item.totalDeliveryTime} mins",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 2.h),
            // Vendor Name
            Text(
              item.vendor?.entityName ?? '',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (!isDeliverable) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.8, child: cardContent),
      );
    }

    return cardContent;
  }
}

// ----------------------------------------------------
// 3. More on Swiggy Section
// ----------------------------------------------------
// class MoreOnSwiggySection extends StatelessWidget {
//   const MoreOnSwiggySection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Dynamically retrieve premium restaurants list
//     final List<Map<String, dynamic>> vendors = premiumRestaurants;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.w),
//           child: Text(
//             "More Restaurants Near You",
//             style: TextStyle(
//               fontSize: 14.5.sp,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//         SizedBox(height: 8.h),
//         SizedBox(
//           height: 135.h,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: EdgeInsets.symmetric(horizontal: 12.w),
//             itemCount: vendors.length,
//             itemBuilder: (context, index) {
//               final vendor = vendors[index];
//               return GestureDetector(
//                 onTap: () {
//                   context.push(AppRoutePath.restaurantDetails, extra: vendor);
//                 },
//                 child: Container(
//                   width: 110.w,
//                   margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16.w),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.03),
//                         blurRadius: 8,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                     border: Border.all(
//                       color: Colors.black.withOpacity(0.04),
//                       width: 0.8,
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Vendor rounded top image
//                       ClipRRect(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(16.w),
//                         ),
//                         child: Image.asset(
//                           vendor['image'] as String,
//                           height: 85.h,
//                           width: 110.w,
//                           fit: BoxFit.contain,
//                           errorBuilder: (context, error, stackTrace) =>
//                               Container(
//                                 height: 85.h,
//                                 width: 110.w,
//                                 color: Colors.orange.shade50,
//                                 child: Icon(
//                                   Icons.restaurant,
//                                   color: Colors.orange.shade200,
//                                   size: 24.w,
//                                 ),
//                               ),
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 8.w,
//                           vertical: 6.h,
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               vendor['name'] as String,
//                               style: TextStyle(
//                                 fontSize: 10.5.sp,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             SizedBox(height: 2.h),
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.star,
//                                   color: const Color(0xFF24963F),
//                                   size: 10.w,
//                                 ),
//                                 SizedBox(width: 2.w),
//                                 Text(
//                                   "${vendor['rating']}",
//                                   style: TextStyle(
//                                     fontSize: 9.5.sp,
//                                     fontWeight: FontWeight.bold,
//                                     color: const Color(0xFF24963F),
//                                   ),
//                                 ),
//                                 Text(
//                                   " • ${vendor['deliveryTime']}",
//                                   style: TextStyle(
//                                     fontSize: 9.5.sp,
//                                     color: Colors.grey.shade600,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
