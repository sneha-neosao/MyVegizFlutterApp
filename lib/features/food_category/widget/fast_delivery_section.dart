// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:myviggiesnew/features/food_category/widget/veg_nonveg_filter.dart';
// import '../../../core/utils/responsive_utils.dart';
// import '../../../routes/app_route_path.dart';

// class FastDeliverySection extends StatelessWidget {
//   final List<Map<String, dynamic>> filteredRestaurants;

//   const FastDeliverySection({super.key, required this.filteredRestaurants});

//   @override
//   Widget build(BuildContext context) {
//     if (filteredRestaurants.isEmpty) return const SizedBox.shrink();

//     // Sort restaurants by deliveryTime safely
//     final fastRestaurants = filteredRestaurants.toList()
//       ..sort(
//         (a, b) => (a['deliveryTime']?.toString() ?? "30 mins").compareTo(
//           b['deliveryTime']?.toString() ?? "30 mins",
//         ),
//       );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.w),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'FAST DELIVERY',
//                 style: TextStyle(
//                   fontSize: 15.sp,
//                   fontWeight: FontWeight.w900,
//                   letterSpacing: 1.1,
//                   color: Colors.black87,
//                 ),
//               ),
//               SizedBox(height: 2.h),
//               Text(
//                 'Speedy delivery from top-rated restaurants near you',
//                 style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 12.h),
//         SizedBox(
//           height: 195.h,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: EdgeInsets.symmetric(horizontal: 12.w),
//             itemCount: fastRestaurants.length,
//             itemBuilder: (context, index) {
//               final restaurant = fastRestaurants[index];
//               return _buildFastDeliveryCard(context, restaurant);
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFastDeliveryCard(
//     BuildContext context,
//     Map<String, dynamic> restaurant,
//   ) {
//     final bool isVeg = restaurant['isVeg'] as bool? ?? true;
//     final String image = restaurant['image']?.toString() ?? "";
//     final String offerText =
//         restaurant['offerText']?.toString() ?? "DEALS AVAILABLE";
//     final String cleanOffer = offerText.split(' on ')[0].toUpperCase();

//     return GestureDetector(
//       onTap: () {
//         context.push(AppRoutePath.restaurantDetails, extra: restaurant);
//       },
//       child: Container(
//         width: 170.w,
//         margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16.w),
//           border: Border.all(color: Colors.black.withOpacity(0.03), width: 1.0),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               spreadRadius: 1,
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//             // BoxShadow(
//             //   color: Colors.black.withOpacity(0.01),
//             //   spreadRadius: 0,
//             //   blurRadius: 2,
//             //   offset: const Offset(0, 1),
//             // ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.vertical(
//                     top: Radius.circular(16.w),
//                   ),
//                   child: image.isNotEmpty
//                       ? Image.asset(
//                           image,
//                           height: 100.h,
//                           width: 170.w,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) =>
//                               Container(
//                                 height: 100.h,
//                                 width: 170.w,
//                                 color: Colors.orange.shade50,
//                                 child: Icon(
//                                   Icons.fastfood,
//                                   color: Colors.orange.shade200,
//                                   size: 32.w,
//                                 ),
//                               ),
//                         )
//                       : Container(
//                           height: 100.h,
//                           width: 170.w,
//                           color: Colors.orange.shade50,
//                           child: Icon(
//                             Icons.fastfood,
//                             color: Colors.orange.shade200,
//                             size: 32.w,
//                           ),
//                         ),
//                 ),
//                 // Smooth Three-color gradient overlay at bottom of image
//                 Positioned(
//                   bottom: 0,
//                   left: 0,
//                   right: 0,
//                   child: Container(
//                     height: 45.h,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.bottomCenter,
//                         end: Alignment.topCenter,
//                         colors: [
//                           Colors.black.withOpacity(0.85),
//                           Colors.black.withOpacity(0.4),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 // High-Contrast Offer Text Overlay
//                 Positioned(
//                   bottom: 6.h,
//                   left: 8.w,
//                   child: Text(
//                     cleanOffer,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 11.5.sp,
//                       fontWeight: FontWeight.w900,
//                       letterSpacing: 0.5,
//                       shadows: [
//                         Shadow(
//                           color: Colors.black.withOpacity(0.6),
//                           blurRadius: 4,
//                           offset: const Offset(0, 1),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Veg/Non-Veg floating badge
//                 Positioned(
//                   top: 8.h,
//                   right: 8.w,
//                   child: Container(
//                     padding: EdgeInsets.all(4.w),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.95),
//                       borderRadius: BorderRadius.circular(6.w),
//                       boxShadow: const [
//                         BoxShadow(color: Colors.black12, blurRadius: 4),
//                       ],
//                     ),
//                     child: isVeg ? const VegIcon() : const NonVegIcon(),
//                   ),
//                 ),
//               ],
//             ),
//             Padding(
//               padding: EdgeInsets.all(8.w),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     restaurant['name']?.toString() ?? 'Restaurant',
//                     style: TextStyle(
//                       fontSize: 13.sp,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   SizedBox(height: 2.h),
//                   Row(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 4.w,
//                           vertical: 2.h,
//                         ),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF24963F),
//                           borderRadius: BorderRadius.circular(4.w),
//                         ),
//                         child: Row(
//                           children: [
//                             Text(
//                               (restaurant['rating'] ?? 4.0).toString(),
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 10.sp,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             SizedBox(width: 1.w),
//                             Icon(Icons.star, color: Colors.white, size: 9.w),
//                           ],
//                         ),
//                       ),
//                       SizedBox(width: 4.w),
//                       Text(
//                         '•',
//                         style: TextStyle(color: Colors.grey, fontSize: 10.sp),
//                       ),
//                       SizedBox(width: 4.w),
//                       Text(
//                         restaurant['deliveryTime']?.toString() ?? '30 mins',
//                         style: TextStyle(
//                           color: Colors.black87,
//                           fontSize: 10.sp,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 4.h),
//                   Text(
//                     restaurant['cuisines']?.toString() ?? 'Cuisines',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 9.sp,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   SizedBox(height: 2.h),
//                   Row(
//                     children: [
//                       Icon(Icons.location_on, color: Colors.grey, size: 10.w),
//                       SizedBox(width: 2.w),
//                       Expanded(
//                         child: Text(
//                           '${restaurant['distance'] ?? '1.5 km'} (${(restaurant['location']?.toString() ?? 'Nagpur').split(',')[0]})',
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 9.sp,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
