import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import '../../bloc/grocery_category/grocery_category_bloc.dart';
import '../../bloc/grocery_category/grocery_category_state.dart';
import '../../data/models/grocery_category_model.dart';
import '../../../../routes/app_route_path.dart';
import '../../../../core/utils/responsive_utils.dart';

class Section2Groceries extends StatelessWidget {
  final String searchQuery;
  const Section2Groceries({super.key, this.searchQuery = ''});

  String _resolveTabSlug(String? title) {
    if (title == null) return '';
    final cleaned = title.toLowerCase();
    if (cleaned.contains('leafy-greens')) return 'leafy-greens';
    if (cleaned.contains('dry fruits') || cleaned.contains('dry-fruits')) return 'dry-fruits';
    if (cleaned.contains('snacks')) return 'snacks';
    if (cleaned.contains('sweets')) return 'sweets';
    if (cleaned.contains('soft-drinks') || cleaned.contains('soft_drinks') || cleaned.contains('cold drinks') || cleaned.contains('cold-drinks') || cleaned.contains('ice cream')) return 'soft-drinks';
    if (cleaned.contains('bakery')) return 'bakery';
    if (cleaned.contains('frozen')) return 'frozen';
    
    return cleaned.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroceryCategoryBloc, GroceryCategoryState>(
      builder: (context, state) {
        if (state is GroceryCategoryLoading || state is GroceryCategoryInitial) {
          return _buildShimmerLoading();
        }

        if (state is GroceryCategoryError) {
          return const SizedBox.shrink();
        }

        List<GroceryCategoryModel> items = [];
        if (state is GroceryCategoryLoaded) {
          items = state.categories;
        }

        if (searchQuery.isNotEmpty) {
          items = items
              .where((item) => (item.categoryName ?? '')
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
              .toList();
        }

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        // Dynamic Main Category Name
        final String sectionTitle = items.first.mainCategoryName ?? "Grocery & Vegetables";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.green,
                        size: 20.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        sectionTitle,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   "Groceries delivered in minutes",
                  //   style: TextStyle(
                  //     fontSize: 18.sp,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              color: Colors.white,
              // padding: EdgeInsets.symmetric(vertical: 8.h),
              child: SizedBox(
                height: 170.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final cat = items[index];
                    final tabSlug = _resolveTabSlug(cat.homeSectionTitle);

                    return GestureDetector(
                      onTap: () {
                        context.push(
                          AppRoutePath.groceryCategory,
                          extra: {
                            'mainCategorySlug': 'grocery-vegetables',
                            'initialTabSlug': tabSlug,
                            'initialCategorySlug': cat.slug,
                          },
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Column(
                          children: [
                            Container(
                              width: 110.w,
                              height: 120.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.w),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: cat.categoryImage != null && cat.categoryImage!.isNotEmpty
                                  ? Image.network(
                                      cat.categoryImage!,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return ShimmerPlaceholder.rounded(
                                          height: 100.w,
                                          width: 120.w,
                                          borderRadius: 12.w,
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(Icons.image, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 100.w,
                              child: Text(
                                cat.categoryName ?? '',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerPlaceholder.rounded(
                    height: 20.w,
                    width: 20.w,
                    borderRadius: 4.w,
                  ),
                  SizedBox(width: 8.w),
                  ShimmerPlaceholder.rounded(
                    height: 12.h,
                    width: 120.w,
                    borderRadius: 2.w,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ShimmerPlaceholder.rounded(
                height: 18.h,
                width: 220.w,
                borderRadius: 4.w,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 155.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: 4,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  children: [
                    ShimmerPlaceholder.rounded(
                      height: 100.w,
                      width: 120.w,
                      borderRadius: 12.w,
                    ),
                    const SizedBox(height: 8),
                    ShimmerPlaceholder.rounded(
                      height: 13.h,
                      width: 80.w,
                      borderRadius: 2.w,
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
