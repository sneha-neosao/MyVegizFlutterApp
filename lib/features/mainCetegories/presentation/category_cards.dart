import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import '../data/models/mainCategory_model.dart';
import '../../../routes/app_route_path.dart';
import '../bloc/mainCategories_bloc.dart';
import '../bloc/mainCategories_state.dart';

const List<List<Color>> _categoryGradients = [
  [Color(0xFFFF5E2B), Color(0xFFFF9068)], // Orange (Food)
  [Color(0xFF00B25C), Color(0xFF2AE08E)], // Green (Grocery)
  [Color(0xFF1E88E5), Color(0xFF64B5F6)], // Blue
  [Color(0xFFD81B60), Color(0xFFF06292)], // Pink
  [Color(0xFF8E24AA), Color(0xFFBA68C8)], // Purple
  [Color(0xFFFFB300), Color(0xFFFFD54F)], // Yellow
  [Color(0xFF00ACC1), Color(0xFF4DD0E1)], // Cyan
  [Color(0xFF7CB342), Color(0xFFAED581)], // Light Green
];

/// Returns the route path + optional extra for a given category slug.
/// - `food` → food category page
/// - any other slug → grocery category page with the slug passed as extra
Map<String, dynamic> _resolveRoute(String slug) {
  if (slug == 'food') {
    return {'path': AppRoutePath.foodCategory, 'extra': null};
  }
  return {
    'path': AppRoutePath.groceryCategory,
    'extra': {'mainCategorySlug': slug},
  };
}

List<Color> _resolveGradient(String slug, int index) {
  final cleanedSlug = slug.toLowerCase();
  if (cleanedSlug == 'food') {
    return _categoryGradients[0]; // Orange
  } else if (cleanedSlug.contains('grocery') || cleanedSlug.contains('veg')) {
    return _categoryGradients[1]; // Green
  }
  return _categoryGradients[index % _categoryGradients.length];
}

class CategoryCards extends StatelessWidget {
  final String searchQuery;
  const CategoryCards({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCategoriesBloc, MainCategoriesState>(
      builder: (context, state) {
        if (state is MainCategoriesLoading) {
          // Shimmer is handled at the HomePage level for a full-screen effect.
          return const SizedBox.shrink();
        } else if (state is MainCategoriesError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else if (state is MainCategoriesLoaded) {
          // Filter to active categories only, then apply search query if present
          var categories = (state.data.data ?? [])
              .where((c) => c.isActive)
              .toList();

          if (searchQuery.isNotEmpty) {
            categories = categories
                .where(
                  (c) => (c.mainCategoryName)
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()),
                )
                .toList();
          }

          if (categories.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildCategoryGrid(context, categories),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Datum> categories) {
    final List<Widget> children = [];
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final gradient = _resolveGradient(category.slug, i);

      children.add(
        _buildCard(
          context: context,
          category: category,
          gradientColors: gradient,
          animationDelay: i * 80,
        ),
      );

      if (i < categories.length - 1) {
        children.add(SizedBox(height: 16.h));
      }
    }

    return Column(children: children);
  }

  Widget _buildCard({
    required BuildContext context,
    required Datum category,
    required List<Color> gradientColors,
    int animationDelay = 0,
  }) {
    final route = _resolveRoute(category.slug);
    final String path = route['path'] as String;
    final dynamic extra = route['extra'];

    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40.w),
          bottomRight: Radius.circular(40.w),
          topRight: Radius.zero,
          bottomLeft: Radius.zero,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (extra != null) {
              context.push(path, extra: extra);
            } else {
              context.push(path);
            }
          },
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 16.w,
                  top: 16.h,
                  bottom: 16.h,
                  right: 120.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.mainCategoryName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.shortDescription,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                top: 0,
                child: Container(
                  width: 120.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40.w),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: category.mainCategoryImage.isEmpty
                      ? const SizedBox()
                      : Image.network(
                          category.mainCategoryImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(
      delay: Duration(milliseconds: animationDelay + 100),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}
