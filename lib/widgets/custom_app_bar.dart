import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_route_path.dart';
import '../core/utils/location_service.dart';
import '../core/utils/profile_image_notifier.dart';
import '../core/utils/responsive_utils.dart';

class CustomHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget? bottom;
  final bool showFoodFilters;
  final VoidCallback? onFilterTap;
  final String activeFilter;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final String? searchHintText;
  final bool showSearch;

  const CustomHomeAppBar({
    super.key,
    this.bottom,
    this.showFoodFilters = false,
    this.onFilterTap,
    this.activeFilter = 'all',
    this.searchController,
    this.onSearchChanged,
    this.onSearchClear,
    this.searchHintText,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 12,
      automaticallyImplyLeading: false,
      toolbarHeight: 56.h,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.location_on, color: const Color(0xFFFC8019), size: 24.w),
          SizedBox(width: 6.w),
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.push(AppRoutePath.selectLocation);
              },
              child: ValueListenableBuilder<LocationState?>(
                valueListenable: locationService.locationNotifier,
                builder: (context, locationState, child) {
                  final address = locationState?.address ?? 'Fetching location...';
                  return Text(
                    address,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 12.w),
          child: GestureDetector(
            onTap: () => context.push(AppRoutePath.profile),
            child: ValueListenableBuilder<String?>(
              valueListenable: profileImageNotifier,
              builder: (context, imagePath, _) {
                final hasImage = imagePath != null && imagePath.isNotEmpty;
                return Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: hasImage ? Colors.grey[200] : const Color(0xFFFC8019),
                    shape: BoxShape.circle,
                  ),
                  child: hasImage
                      ? ClipOval(
                          child: imagePath.startsWith('http')
                              ? Image.network(
                                  imagePath,
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                )
                              : Image.file(
                                  File(imagePath),
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                );
              },
            ),
          ),
        ),
      ],
      bottom: (!showSearch && bottom == null)
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(
                (showSearch ? 52.h : 0) + (bottom?.preferredSize.height ?? 0),
              ),
              child: Column(
                children: [
                  if (showSearch)
                    Padding(
                      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.h),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.w,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      onChanged: onSearchChanged,
                                      decoration: InputDecoration(
                                        hintText: searchHintText ?? 'Search for ',
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14.sp,
                                        ),
                                        suffixIcon: (searchController != null &&
                                                searchController!.text.isNotEmpty)
                                            ? GestureDetector(
                                                onTap: onSearchClear,
                                                child: Icon(
                                                  Icons.clear,
                                                  color: Colors.grey.shade500,
                                                  size: 18.w,
                                                ),
                                              )
                                            : null,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                          left: 16.w,
                                          right: 8.w,
                                          bottom: 10.h,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: double.infinity,
                                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFC8019),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.search,
                                          color: Colors.white,
                                          size: 18.w,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Search',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  /*
                  if (showFoodFilters) ...[
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: onFilterTap,
                      child: Container(
                        height: 40.h,
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        constraints: BoxConstraints(minWidth: 54.w),
                        decoration: BoxDecoration(
                          color: activeFilter == 'veg'
                              ? const Color(0xFF0F8A5F).withValues(alpha: 0.06)
                              : activeFilter == 'nonveg'
                              ? const Color(0xFFE43B3F).withValues(alpha: 0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10.w),
                          border: Border.all(
                            color: activeFilter == 'veg'
                                ? const Color(0xFF0F8A5F)
                                : activeFilter == 'nonveg'
                                ? const Color(0xFFE43B3F)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              activeFilter == 'nonveg' ? 'NON-VEG' : 'VEG',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w900,
                                color: activeFilter == 'veg'
                                    ? const Color(0xFF0F8A5F)
                                    : activeFilter == 'nonveg'
                                    ? const Color(0xFFE43B3F)
                                    : Colors.grey.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            _buildToggleSwitchSymbol(activeFilter),
                          ],
                        ),
                      ),
                    ),
                  ],
                  */
                  if (bottom != null) bottom!,
                ],
              ),
            ),
    );
  }

  Widget _buildToggleSwitchSymbol(String filter) {
    final bool isVeg = filter == 'veg';
    final bool isNonVeg = filter == 'nonveg';
    final bool isActive = isVeg || isNonVeg;

    return Container(
      width: 22.w,
      height: 12.h,
      decoration: BoxDecoration(
        color: isVeg
            ? const Color(0xFF0F8A5F)
            : isNonVeg
            ? const Color(0xFFE43B3F)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10.w),
      ),
      padding: EdgeInsets.symmetric(horizontal: 1.5.w),
      alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 8.w,
        height: 8.w,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight((showSearch ? 108.h : 56.h) + (bottom?.preferredSize.height ?? 0));
}
