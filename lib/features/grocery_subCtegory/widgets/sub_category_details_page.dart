// import 'package:flutter/material.dart';
//
// import '../../grocery_category/widget/grocery_product_card.dart';
// import '../../home/data/allDummy_data.dart';
//
// class SubCategoryDetailsPage extends StatefulWidget {
//   final String title;
//   final List<GroceryCategory> categories;
//
//   const SubCategoryDetailsPage({
//     super.key,
//     required this.title,
//     required this.categories,
//   });
//
//   @override
//   State<SubCategoryDetailsPage> createState() => _SubCategoryDetailsPageState();
// }
//
// class _SubCategoryDetailsPageState extends State<SubCategoryDetailsPage> {
//   int _selectedIndex = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         shadowColor: Colors.grey.shade200,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           widget.title,
//           style: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search, color: Colors.black),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Left Side (Sub Categories)
//           Container(
//             width: 85,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(
//                 right: BorderSide(color: Colors.grey.shade200, width: 1),
//               ),
//             ),
//             child: ListView.builder(
//               itemCount: widget.categories.length,
//               itemBuilder: (context, index) {
//                 final category = widget.categories[index];
//                 final isSelected = index == _selectedIndex;
//                 return GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectedIndex = index;
//                     });
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 16,
//                       horizontal: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? const Color(0xFFE8F5E9)
//                           : Colors
//                                 .transparent, // Highlight selected item with light green
//                       border: Border(
//                         left: BorderSide(
//                           color: isSelected ? Colors.green : Colors.transparent,
//                           width: 4,
//                         ),
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircleAvatar(
//                           radius: 20,
//                           backgroundColor: Colors.grey.shade100,
//                           child: Icon(
//                             category.icon,
//                             color: Colors.black54,
//                             size: 20,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           category.name,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: isSelected
//                                 ? FontWeight.bold
//                                 : FontWeight.normal,
//                             color: isSelected
//                                 ? Colors.green.shade800
//                                 : Colors.grey.shade700,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           // Right Side (Products)
//           Expanded(
//             child: Container(
//               color: const Color(0xFFF9F9F9),
//               child: widget.categories.isEmpty
//                   ? const Center(child: Text("No products"))
//                   : GridView.builder(
//                       padding: const EdgeInsets.all(12),
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 2,
//                             childAspectRatio: 0.65,
//                             crossAxisSpacing: 10,
//                             mainAxisSpacing: 10,
//                           ),
//                       itemCount:
//                           widget.categories[_selectedIndex].products.length,
//                       itemBuilder: (context, index) {
//                         final product =
//                             widget.categories[_selectedIndex].products[index];
//                         return GroceryProductCard(
//                           image: product.imageAsset,
//                           title: product.name,
//                           rating: product.rating,
//                           price: product.price,
//                           originalPrice: product.originalPrice,
//                         );
//                       },
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
