import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/features/food_category/widget/veg_nonveg_filter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../routes/app_route_path.dart';
import '../data/models/vendor_home_section_model.dart';

class TopExploreSection extends StatelessWidget {
  final List<HomeSectionVendor> restaurants;
  final List<HomeSectionVendor> offers;
  final String searchQuery;
  final String title;
  final String description;
  final String offersTitle;

  const TopExploreSection({
    super.key,
    required this.restaurants,
    required this.offers,
    this.searchQuery = '',
    this.title = 'TOP RESTAURANTS TO EXPLORE',
    this.description = "",
    this.offersTitle = 'Top Offers',
  });

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 30.h),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu_outlined,
                    color: Colors.grey.shade400,
                    size: 48.w,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No restaurants match your selection',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Try modifying or clearing your preference filter.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    List<Widget> children = [];
    int chunkSize = 3;

    // Add main header
    children.add(
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              description,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
    children.add(SizedBox(height: 16.h));

    // Loop through restaurants list and chunk them
    for (int i = 0; i < restaurants.length; i += chunkSize) {
      int end = (i + chunkSize < restaurants.length)
          ? i + chunkSize
          : restaurants.length;
      List<HomeSectionVendor> chunk = restaurants.sublist(i, end);

      // Add the restaurant cards in this chunk
      for (var restaurant in chunk) {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildTopExploreCard(context, restaurant),
          ),
        );
        children.add(SizedBox(height: 16.h));
      }

      // After displaying the first chunk (first 3 cards) and if there are more restaurants remaining,
      // insert the dynamic horizontally scrolling "Top Offers" promotional banner section!
      if (i == 0 && restaurants.length > 3) {
        children.add(_buildTopOffersSection(context));
        children.add(SizedBox(height: 24.h));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildTopExploreCard(
    BuildContext context,
    HomeSectionVendor restaurant,
  ) {
    final bool isEnabled = restaurant.isServiceable;

    final Widget cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
          // BoxShadow(
          //   color: Colors.black.withOpacity(0.01),
          //   spreadRadius: 0,
          //   blurRadius: 2,
          //   offset: const Offset(0, 1),
          // ),
        ],
      ),
      padding: EdgeInsets.all(12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Restaurant Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FoodTypeIcon(foodType: restaurant.foodType),
                    if (restaurant.isPopular == true) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFC8019).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4.w),
                        ),
                        child: Text(
                          'POPULAR',
                          style: TextStyle(
                            color: const Color(0xFFFC8019),
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  restaurant.entityName ?? '',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: (restaurant.avgRating ?? 0.0) >= 4.0
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(4.w),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: (restaurant.avgRating ?? 0.0) >= 4.0
                                ? const Color(0xFF0F8A5F)
                                : Colors.amber.shade700,
                            size: 10.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            (restaurant.avgRating ?? 0.0).toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: (restaurant.avgRating ?? 0.0) >= 4.0
                                  ? const Color(0xFF0F8A5F)
                                  : Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (restaurant.totalReviews != null && restaurant.totalReviews! > 0) ...[
                      SizedBox(width: 4.w),
                      Text(
                        '(${restaurant.totalReviews})',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (restaurant.distanceKm != null) ...[
                      SizedBox(width: 6.w),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 10.sp),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey.shade600,
                        size: 11.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        formatDistance(restaurant.distanceKm!),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Right Column: Famous Food Image
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.w),
                child: Image.network(
                  restaurant.entityImage ?? '',
                  height: 105.w,
                  width: 105.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 105.w,
                    width: 105.w,
                    color: Colors.orange.shade50,
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.orange.shade200,
                      size: 32.w,
                    ),
                  ),
                ),
              ),
              if (!isEnabled)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16.w),
                        bottomRight: Radius.circular(16.w),
                      ),
                    ),
                    child: Text(
                      'Out of Delivery Area',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              // Premium Green "EXPLORE" overlay button
              if (isEnabled)
                Positioned(
                  bottom: -6.h,
                  left: 12.w,
                  right: 12.w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF24963F).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Center(
                      child: Text(
                        'EXPLORE',
                        style: TextStyle(
                          color: const Color(0xFF24963F),
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );



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
                  "id": restaurant.id,
                  "name": restaurant.entityName ?? "Restaurant",
                  "image": restaurant.entityImage ?? "",
                  "isServiceable": isEnabled,
                  "isDeliverable": isEnabled,
                  "distanceKm": restaurant.distanceKm,
                },
              );
            },
      child: cardContent,
    );
  }

  Widget _buildTopOffersSection(BuildContext context) {
    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            offersTitle,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 220.w,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _buildOfferVerticalCard(context, offer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfferVerticalCard(
    BuildContext context,
    HomeSectionVendor offer,
  ) {
    final bool isEnabled = offer.isServiceable;

    final Widget cardContent = Container(
      width: 140.w,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.w),
                child: Image.network(
                  offer.entityImage ?? '',
                  height: 150.w,
                  width: 140.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150.w,
                    width: 140.w,
                    color: Colors.orange.shade50,
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.orange.shade200,
                      size: 32.w,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16.w),
                    ),
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
              const SizedBox.shrink(),
              if (!isEnabled)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: Center(
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
                          "UNAVAILABLE",
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
          SizedBox(height: 6.h),
          Text(
            offer.entityName ?? '',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
                decoration: BoxDecoration(
                  color: (offer.avgRating ?? 0.0) >= 4.0
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(4.w),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: (offer.avgRating ?? 0.0) >= 4.0
                          ? const Color(0xFF0F8A5F)
                          : Colors.amber.shade700,
                      size: 9.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      (offer.avgRating ?? 0.0).toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        color: (offer.avgRating ?? 0.0) >= 4.0
                            ? const Color(0xFF0F8A5F)
                            : Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              if (offer.totalReviews != null && offer.totalReviews! > 0) ...[
                SizedBox(width: 4.w),
                Text(
                  '(${offer.totalReviews})',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (offer.distanceKm != null) ...[
                SizedBox(width: 4.w),
                Text(
                  '•',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 9.sp),
                ),
                SizedBox(width: 4.w),
                Text(
                  formatDistance(offer.distanceKm!),
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            offer.foodType ?? 'Cuisines',
            style: TextStyle(fontSize: 10.5.sp, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );



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
                  "id": offer.id,
                  "name": offer.entityName ?? "Restaurant",
                  "image": offer.entityImage ?? "",
                  "isServiceable": isEnabled,
                  "isDeliverable": isEnabled,
                  "distanceKm": offer.distanceKm,
                },
              );
            },
      child: cardContent,
    );
  }
}
