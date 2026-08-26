// import 'package:flutter/material.dart';
// import '../../../core/utils/responsive_utils.dart';

// /// API-driven "What's on Your Mind?" horizontal scroller.
// ///
// /// [items] – list of maps from the API, each containing:
// ///   • `name`  (String) – display label
// ///   • `image` (String) – network image URL
// ///   • `slug`  (String?) – optional route slug (not used for navigation here)
// class WhatsOnYourMindSection extends StatelessWidget {
//   final List<Map<String, dynamic>> items;
//   final String title;
//   final String subtitle;

//   const WhatsOnYourMindSection({
//     super.key,
//     required this.items,
//     this.title = "WHAT'S ON YOUR MIND?",
//     this.subtitle = "Satisfy your cravings with the best choices",
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (items.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.w),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 15.sp,
//                   fontWeight: FontWeight.w900,
//                   letterSpacing: 1.1,
//                   color: Colors.black87,
//                 ),
//               ),
//               SizedBox(height: 2.h),
//               Text(
//                 subtitle,
//                 style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 14.h),
//         SizedBox(
//           height: 125.h,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: EdgeInsets.symmetric(horizontal: 12.w),
//             itemCount: items.length,
//             itemBuilder: (context, index) {
//               final item = items[index];
//               final String name = item['name']?.toString() ?? '';
//               final String imageUrl = item['image']?.toString() ?? '';

//               return Container(
//                 width: 85.w,
//                 margin: EdgeInsets.symmetric(horizontal: 6.w),
//                 child: Column(
//                   children: [
//                     Container(
//                       height: 75.w,
//                       width: 75.w,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.white,
//                         border: Border.all(
//                           color: Colors.black.withOpacity(0.03),
//                           width: 1,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.06),
//                             blurRadius: 8,
//                             offset: const Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       clipBehavior: Clip.antiAlias,
//                       child: imageUrl.isNotEmpty
//                           ? Image.network(
//                               imageUrl,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) =>
//                                   Icon(
//                                     Icons.fastfood,
//                                     color: Colors.orange.shade200,
//                                     size: 32.w,
//                                   ),
//                             )
//                           : Icon(
//                               Icons.fastfood,
//                               color: Colors.orange.shade200,
//                               size: 32.w,
//                             ),
//                     ),
//                     SizedBox(height: 8.h),
//                     Text(
//                       name,
//                       style: TextStyle(
//                         fontSize: 11.5.sp,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
