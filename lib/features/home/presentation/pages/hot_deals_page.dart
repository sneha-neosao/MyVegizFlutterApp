// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../data/allDummy_data.dart';
// import '../../../grocery_category/widget/grocery_product_card.dart';
//
// class HotDealsPage extends StatelessWidget {
//   const HotDealsPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final hotDeals = hotDealsDummyData;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => context.pop(),
//         ),
//         title: const Text(
//           'Hot Deals',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search, color: Colors.black),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(
//               Icons.share,
//               color: Colors.black,
//             ), // Required share icon
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: hotDeals.isEmpty
//           ? const Center(child: Text("No Hot Deals currently available"))
//           : RefreshIndicator(
//               onRefresh: () async {
//                 // Hot deals currently uses local dummy data.
//                 // Replace with a BLoC event dispatch once the API is available.
//               },
//               child: GridView.builder(
//                 padding: const EdgeInsets.all(16),
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   childAspectRatio: 0.65,
//                   crossAxisSpacing: 16,
//                   mainAxisSpacing: 16,
//                 ),
//                 itemCount: hotDeals.length,
//                 itemBuilder: (context, index) {
//                   final product = hotDeals[index];
//                   return GroceryProductCard(
//                     image: product.imageAsset,
//                     title: product.name,
//                     rating: product.rating,
//                     totalReviews: (product.rating * 12).toInt(), // dummy for mock data
//                     views: product.views,
//                     price: product.price,
//                     originalPrice: product.originalPrice,
//                     slug: product.slug,
//                   );
//                 },
//               ),
//             ),
//     );
//   }
// }
