import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import '../../../../routes/app_route_path.dart';
import '../../bloc/entity_category/entity_category_bloc.dart';
import '../../bloc/entity_category/entity_category_state.dart';
import '../../data/models/entity_category_model.dart';

class Section1Mind extends StatelessWidget {
  final String searchQuery;
  const Section1Mind({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EntityCategoryBloc, EntityCategoryState>(
      builder: (context, state) {
        if (state is EntityCategoryLoading || state is EntityCategoryInitial) {
          return const _Section1MindShimmer();
        }

        if (state is EntityCategoryError) {
          // Fallback to empty space on failure to maintain layout integrity
          return const SizedBox.shrink();
        }

        List<EntityCategoryModel> items = [];
        if (state is EntityCategoryLoaded) {
          items = state.categories;
        }

        if (searchQuery.isNotEmpty) {
          items = items
              .where(
                (item) => (item.entityCategory ?? '').toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: FutureBuilder<String?>(
                future: SecureStorage.getCustomerName(),
                builder: (context, snapshot) {
                  final fullName = snapshot.data;
                  final String firstName = (fullName != null && fullName.trim().isNotEmpty)
                      ? fullName.trim().split(' ').first
                      : '';
                  final String titleText = firstName.isNotEmpty
                      ? "$firstName, What's in your mind?"
                      : "What's in your mind?";
                  return Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            // Horizontal list scroll of Entity Categories
            SizedBox(
              height: 110.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _EntityCategoryCard(item: item);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EntityCategoryCard extends StatelessWidget {
  final EntityCategoryModel item;
  const _EntityCategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutePath.foodCategory);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: item.image == null || item.image!.isEmpty
                    ? Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: Colors.grey,
                        ),
                      )
                    : Image.network(
                        item.image!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return ShimmerPlaceholder.circular(
                            width: 80.w,
                            height: 80.w,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.fastfood_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              item.entityCategory ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section1MindShimmer extends StatelessWidget {
  const _Section1MindShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerPlaceholder.rounded(height: 22.h, width: 200.w),
              SizedBox(height: 10.h),
              ShimmerPlaceholder.rounded(height: 16.h, width: 280.w),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          height: 110.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: 5,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  children: [
                    ShimmerPlaceholder.circular(width: 80.w, height: 80.w),
                    SizedBox(height: 12.h),
                    ShimmerPlaceholder.rounded(height: 14.h, width: 60.w),
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
