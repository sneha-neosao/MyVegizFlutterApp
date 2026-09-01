import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/network_images.dart';
import '../../../routes/app_route_path.dart';
import '../bloc/vendor_entity_category/vendor_entity_category_bloc.dart';
import '../bloc/vendor_entity_category/vendor_entity_category_state.dart';

class VendorEntityCategorySection extends StatelessWidget {
  final String searchQuery;
  const VendorEntityCategorySection({super.key, this.searchQuery = ''});

  String _getCategoryAsset(String? name) {
    if (name == null) return NetworkImages.pizza;
    final categoryLower = name.toLowerCase();
    if (categoryLower.contains("pizza") ||
        categoryLower.contains("restaurant")) {
      return NetworkImages.pizza;
    } else if (categoryLower.contains("burger")) {
      return NetworkImages.burger;
    } else if (categoryLower.contains("biryani")) {
      return NetworkImages.biryani;
    } else if (categoryLower.contains("dosa")) {
      return NetworkImages.dosa;
    } else if (categoryLower.contains("cake")) {
      return NetworkImages.cake;
    } else if (categoryLower.contains("sweet")) {
      return NetworkImages.sweetCorner;
    } else if (categoryLower.contains("beverage") ||
        categoryLower.contains("fruit")) {
      return NetworkImages.beverages;
    }
    return NetworkImages.pizza; // default fallback
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorEntityCategoryBloc, VendorEntityCategoryState>(
      builder: (context, state) {
        if (state.categories.isEmpty) return const SizedBox.shrink();

        var activeCategories = state.categories
            .where((cat) => cat.isActive == true)
            .toList();
        if (searchQuery.isNotEmpty) {
          activeCategories = activeCategories
              .where(
                (cat) => (cat.entityCategory ?? '').toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }
        if (activeCategories.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      // "EXPLORE BY SEGMENT",
                      "What's in your mind?",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // SizedBox(height: 2.h),
                  // Text(
                  //   // "Handpicked gourmet categories from the best hubs",
                  //   "Satisfy your cravings with our best choices",
                  //   style: TextStyle(
                  //     fontSize: 12.sp,
                  //     color: Colors.grey.shade600,
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 125.w,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                itemCount: activeCategories.length,
                itemBuilder: (context, index) {
                  final cat = activeCategories[index];
                  final localAssetPath = _getCategoryAsset(cat.entityCategory);
                  final hasNetworkImage =
                      cat.image != null && cat.image!.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      context.push(
                        AppRoutePath.entityCategoryVendors,
                        extra: {
                          "uuid": cat.uuId ?? '',
                          "title": cat.entityCategory ?? 'Outlets',
                        },
                      );
                    },
                    child: Container(
                      width: 85.w,
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Column(
                        children: [
                          Container(
                            height: 75.w,
                            width: 75.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black.withOpacity(0.03),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasNetworkImage
                                ? Image.network(
                                    cat.image!,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.network(
                                              localAssetPath,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.fastfood,
                                                    color:
                                                        Colors.orange.shade200,
                                                    size: 32.w,
                                                  ),
                                            ),
                                  )
                                : Image.network(
                                    localAssetPath,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.fastfood,
                                          color: Colors.orange.shade200,
                                          size: 32.w,
                                        ),
                                  ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            cat.entityCategory ?? "",
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
