// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../cart/data/cart_data.dart';
// import '../../../routes/app_route_path.dart';

// class TopPicksSection extends StatelessWidget {
//   final List<Map<String, dynamic>> topPicks;

//   const TopPicksSection({super.key, required this.topPicks});

//   @override
//   Widget build(BuildContext context) {
//     if (topPicks.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: Text(
//             'Top Picks',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: 250,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: topPicks.length,
//             itemBuilder: (context, index) {
//               final item = topPicks[index];
//               final title = item['title'];
//               final oldPriceStr = item['oldPrice'] ?? '';
//               final priceStr = item['price'] ?? '';
//               final isVeg = item['isVeg'] ?? true;
//               final image = item['image'] ?? 'assets/Top_Picks.jpeg';
//               final slug = item['slug'] ?? '';

//               double parsedPrice = 0.0;
//               final pStr = priceStr.toString().replaceAll(
//                 RegExp(r'[^\d.]'),
//                 '',
//               );
//               parsedPrice = double.tryParse(pStr) ?? 0.0;

//               return GestureDetector(
//                 onTap: () {
//                   context.push(AppRoutePath.productDetails, extra: slug);
//                 },
//                 child: Container(
//                   width: 220,
//                   margin: const EdgeInsets.only(right: 16),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     color: Colors.grey.shade900,
//                   ),
//                   child: Stack(
//                     children: [
//                       Positioned.fill(
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: Image.asset(image, fit: BoxFit.cover),
//                         ),
//                       ),
//                       Positioned.fill(
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(16),
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.black.withValues(alpha: 0.9),
//                                 Colors.transparent,
//                                 Colors.transparent,
//                               ],
//                               begin: Alignment.bottomCenter,
//                               end: Alignment.topCenter,
//                               stops: const [0.0, 0.4, 1.0],
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 12,
//                         left: 12,
//                         right: 12,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               width: 14,
//                               height: 14,
//                               decoration: BoxDecoration(
//                                 border: Border.all(
//                                   color: isVeg ? Colors.green : Colors.red,
//                                 ),
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                               child: Center(
//                                 child: isVeg
//                                     ? const CircleAvatar(
//                                         backgroundColor: Colors.green,
//                                         radius: 4,
//                                       )
//                                     : const Icon(
//                                         Icons.circle,
//                                         color: Colors.red,
//                                         size: 8,
//                                       ),
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               title,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     if (oldPriceStr.isNotEmpty)
//                                       Text(
//                                         oldPriceStr,
//                                         style: TextStyle(
//                                           color: Colors.grey.shade400,
//                                           fontSize: 12,
//                                           decoration:
//                                               TextDecoration.lineThrough,
//                                         ),
//                                       ),
//                                     const SizedBox(height: 2),
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 4,
//                                         vertical: 2,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: const Color(0xFFFFC000),
//                                         borderRadius: BorderRadius.circular(4),
//                                       ),
//                                       child: Text(
//                                         priceStr,
//                                         style: const TextStyle(
//                                           color: Colors.black,
//                                           fontSize: 12,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 GestureDetector(
//                                   onTap: () {
//                                     addToCart(
//                                       CartItem(
//                                         image: image,
//                                         title: title,
//                                         price: parsedPrice,
//                                         quantity: 1,
//                                       ),
//                                     );
//                                     context.push(AppRoutePath.cart);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 20,
//                                       vertical: 8,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: const Text(
//                                       'ADD',
//                                       style: TextStyle(
//                                         color: Colors.green,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 14,
//                                       ),
//                                     ),
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
