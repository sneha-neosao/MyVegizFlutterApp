import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import '../../../core/utils/network_images.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../routes/app_route_path.dart';
import '../bloc/vendor_entity_category/vendor_entity_category_bloc.dart';
import '../bloc/vendor_entity_category/vendor_entity_category_event.dart';
import '../bloc/vendor_entity_category/vendor_entity_category_state.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_state.dart';
import '../data/models/vendor_entity_category_model.dart';
import '../widget/veg_nonveg_filter.dart';
import '../widget/filter_widget.dart';

class VenderEntityCategoryPage extends StatefulWidget {
  final String initialCategoryUuid;
  final String categoryName;

  const VenderEntityCategoryPage({
    super.key,
    required this.initialCategoryUuid,
    required this.categoryName,
  });

  @override
  State<VenderEntityCategoryPage> createState() =>
      _VenderEntityCategoryPageState();
}

class _VenderEntityCategoryPageState extends State<VenderEntityCategoryPage> {
  late String _currentCategoryUuid;
  late String _currentCategoryName;
  String _activeFilter = 'all';
  SwiggyFilterState _filterState = SwiggyFilterState();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  String _searchQuery = '';

  String _getFoodTypeQueryParam() {
    if (_activeFilter == 'veg' || _filterState.vegNonVeg == 'veg') {
      return 'veg';
    }
    if (_activeFilter == 'nonveg' ||
        _filterState.vegNonVeg == 'non_veg' ||
        _filterState.vegNonVeg == 'nonveg') {
      return 'nonveg';
    }
    return 'both';
  }

  void _fetchData() {
    final loc = locationService.locationNotifier.value;

    // Don't fetch with (0, 0)
    if (loc == null || (loc.lat == 0.0 && loc.lng == 0.0)) {
      return;
    }

    final lat = loc.lat;
    final lng = loc.lng;
    final String? foodTypeParam = _getFoodTypeQueryParam();

    final blocState = context.read<VendorEntityCategoryBloc>().state;
    final validSortKeys =
        blocState.filters?.sortOptions
            ?.map((o) => o.key)
            .whereType<String>()
            .toList() ??
        [];
    final String? sortByParam = validSortKeys.contains(_filterState.sortBy)
        ? _filterState.sortBy
        : null;

    context.read<VendorEntityCategoryBloc>().add(
      FetchVendorEntityCategoriesEvent(
        lat: lat,
        lng: lng,
        entityCategoryUuid: _currentCategoryUuid,
        sortBy: sortByParam,
        foodType: foodTypeParam,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentCategoryUuid = widget.initialCategoryUuid;
    _currentCategoryName = widget.categoryName;
    context.read<VendorEntityCategoryBloc>().add(
      FetchVendorEntityCategoryFiltersEvent(),
    );
    locationService.locationNotifier.addListener(_fetchData);

    // Trigger initial fetch if location is already available
    final loc = locationService.locationNotifier.value;
    if (loc != null && !(loc.lat == 0.0 && loc.lng == 0.0)) {
      _fetchData();
    } else {
      locationService.requestPermissionAndFetchLocation().catchError((e) {
        // Silent error
      });
    }
  }

  @override
  void dispose() {
    locationService.locationNotifier.removeListener(_fetchData);
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

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
        // Resolve active category's name dynamically from state.categories based on _currentCategoryUuid
        String dynamicCategoryName = _currentCategoryName;
        for (final cat in state.categories) {
          if (cat.uuId == _currentCategoryUuid) {
            if (cat.entityCategory != null && cat.entityCategory!.isNotEmpty) {
              dynamicCategoryName = cat.entityCategory!;
            }
            break;
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.pop(),
            ),
            title: Text(
              dynamicCategoryName,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 18.sp,
                backgroundColor: Colors.transparent,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.black),
                onPressed: () {
                  context.push(AppRoutePath.wishlist);
                },
              ),
              BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  int totalItems = 0;
                  if (state is CartLoaded) {
                    totalItems = state.cartData.totalItems ?? 0;
                  } else if (state is CartActionSuccess && state.cartData != null) {
                    totalItems = state.cartData!.totalItems ?? 0;
                  } else if (state is CartLoading && state.cartData != null) {
                    totalItems = state.cartData!.totalItems ?? 0;
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                        onPressed: () {
                          context.go(AppRoutePath.cart);
                        },
                      ),
                      if (totalItems > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFC8019),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$totalItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchData();
                await Future.delayed(const Duration(milliseconds: 800));
                if (mounted) {
                  setState(() {});
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // 1. Swiggy-Style Search & Veg Switch Bar
                        // _buildSearchAndVegBar(dynamicCategoryName),
                        //
                        // SizedBox(height: 8.h),

                        // 2. Swiggy-Style Horizontal Category Scroll List
                        _buildHorizontalCategoryBar(state),

                        // 3. Swiggy-Style Filter & Sorting Pills Row
                        CommonFilterBar(
                          filterState: _filterState,
                          sortOptions: state.filters?.sortOptions ?? [],
                          foodTypes: state.filters?.foodTypes ?? [],
                          onFilterChanged: (newState) {
                            setState(() {
                              _filterState = newState;
                              if (newState.vegNonVeg == 'veg') {
                                _activeFilter = 'veg';
                              } else if (newState.vegNonVeg == 'nonveg' ||
                                  newState.vegNonVeg == 'non_veg') {
                                _activeFilter = 'nonveg';
                              } else if (newState.vegNonVeg == 'both' ||
                                  newState.vegNonVeg == 'all' ||
                                  newState.vegNonVeg == '') {
                                _activeFilter = 'all';
                              }
                            });
                            _fetchData();
                          },
                          show99Store: false,
                        ),

                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                  _buildVendorsSliver(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVendorsSliver(VendorEntityCategoryState state) {
    if (state.isCategoriesLoading) {
      return SliverToBoxAdapter(child: _buildShimmerLoading());
    }

    if (state.categoriesError != null) {
      return SliverToBoxAdapter(
        child: _buildErrorState(state.categoriesError!),
      );
    }

    // Show shimmer if we have no data yet (location not yet acquired, fetch hasn't run)
    if (state.categories.isEmpty) {
      return SliverToBoxAdapter(child: _buildShimmerLoading());
    }

    // Get vendors for the currently selected category from state.categories based on _currentCategoryUuid
    List<EntityCategoryVendor> outlets = [];
    for (final cat in state.categories) {
      if (cat.uuId == _currentCategoryUuid) {
        if (cat.vendors != null) {
          outlets = List<EntityCategoryVendor>.from(cat.vendors!);
        }
        break;
      }
    }

    // VEG / NONVEG FILTER (Page Level & Modal Filter level)
    outlets = outlets.where((v) {
      final hasVegItems =
          (v.foodType?.toLowerCase() == 'veg' ||
              v.foodType?.toLowerCase() == 'both') ||
          (v.vendorItems?.any(
                (item) => item.cuisineType?.toLowerCase() == 'veg',
              ) ??
              false);

      final hasNonVegItems =
          (v.foodType?.toLowerCase() == 'nonveg' ||
              v.foodType?.toLowerCase() == 'non-veg' ||
              v.foodType?.toLowerCase() == 'both') ||
          (v.vendorItems?.any(
                (item) =>
                    item.cuisineType?.toLowerCase() == 'nonveg' ||
                    item.cuisineType?.toLowerCase() == 'non-veg',
              ) ??
              false);

      // Page level veg toggle filter
      if (_activeFilter == 'veg' && !hasVegItems) return false;
      if (_activeFilter == 'nonveg' && !hasNonVegItems) return false;

      // Filter Modal level veg toggle filter
      if (_filterState.vegNonVeg == 'veg' && !hasVegItems) return false;
      if (_filterState.vegNonVeg == 'non_veg' && !hasNonVegItems) return false;

      // Filter Modal level rating filter
      final double rating = v.displayRating;
      if (_filterState.ratingFilter == '4.5_plus' && rating < 4.5) return false;
      if (_filterState.ratingFilter == '4.0_plus' && rating < 4.0) return false;

      // Filter Modal level delivery time filter (Bolt / 15 mins)
      final String deliveryTimeStr = v.displayDeliveryTime;
      final int deliveryTime =
          int.tryParse(deliveryTimeStr.split(' ')[0]) ??
          int.tryParse(deliveryTimeStr.split('-')[0]) ??
          30;
      if (_filterState.isFastDelivery && deliveryTime > 15) return false;

      return true;
    }).toList();

    // Sort list
    if (_filterState.sortBy == 'rating') {
      outlets.sort((a, b) => b.displayRating.compareTo(a.displayRating));
    } else if (_filterState.sortBy == 'delivery_time') {
      outlets.sort((a, b) {
        final aTime =
            int.tryParse(a.displayDeliveryTime.split(' ')[0]) ??
            int.tryParse(a.displayDeliveryTime.split('-')[0]) ??
            30;
        final bTime =
            int.tryParse(b.displayDeliveryTime.split(' ')[0]) ??
            int.tryParse(b.displayDeliveryTime.split('-')[0]) ??
            30;
        return aTime.compareTo(bTime);
      });
    }

    // Deliverable-first: stable secondary sort keeping inner order intact
    outlets.sort((a, b) {
      final aD = a.isServiceable ? 0 : 1;
      final bD = b.isServiceable ? 0 : 1;
      return aD.compareTo(bD);
    });

    // SEARCH FILTER
    if (_searchQuery.isNotEmpty) {
      outlets = outlets.where((v) {
        return (v.entityName ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (v.area ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (outlets.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverList.builder(
        itemCount: outlets.length,
        itemBuilder: (context, index) {
          return _buildRestaurantCard(outlets[index]);
        },
      ),
    );
  }

  Widget _buildSearchAndVegBar(String currentCategoryName) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // Elegant rounded input box
          Expanded(
            child: Container(
              height: 42.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12.w),
                  Icon(Icons.search, color: Colors.grey.shade400, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search for '$currentCategoryName'",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13.sp,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      style: TextStyle(color: Colors.black87, fontSize: 13.sp),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade500,
                        size: 18.w,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                  Icon(Icons.mic, color: const Color(0xFFFC8019), size: 20.w),
                  SizedBox(width: 12.w),
                ],
              ),
            ),
          ),
          // SizedBox(width: 8.w),
          // // Veg switch button matching screenshot
          // // VEG / NONVEG Toggle
          // GestureDetector(
          //   onTap: () {
          //     showFoodFilterBottomSheet(context, _activeFilter, (newFilter) {
          //       setState(() {
          //         _activeFilter = newFilter;
          //         if (newFilter == 'veg') {
          //           _filterState.vegNonVeg = 'veg';
          //         } else if (newFilter == 'nonveg') {
          //           _filterState.vegNonVeg = 'nonveg';
          //         } else {
          //           _filterState.vegNonVeg = 'both';
          //         }
          //       });
          //       _fetchData();
          //     });
          //   },
          //   child: Container(
          //     height: 40.h,
          //     padding: EdgeInsets.symmetric(horizontal: 6.w),
          //     constraints: BoxConstraints(minWidth: 54.w),
          //     decoration: BoxDecoration(
          //       color: _activeFilter == 'veg'
          //           ? const Color(0xFF0F8A5F).withValues(alpha: 0.06)
          //           : _activeFilter == 'nonveg'
          //           ? const Color(0xFFE43B3F).withValues(alpha: 0.06)
          //           : Colors.white,
          //       borderRadius: BorderRadius.circular(10.w),
          //       border: Border.all(
          //         color: _activeFilter == 'veg'
          //             ? const Color(0xFF0F8A5F)
          //             : _activeFilter == 'nonveg'
          //             ? const Color(0xFFE43B3F)
          //             : Colors.grey.shade300,
          //         width: 1.5,
          //       ),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withValues(alpha: 0.04),
          //           blurRadius: 4,
          //           offset: const Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Text(
          //           _activeFilter == 'nonveg' ? 'NON-VEG' : 'VEG',
          //           style: TextStyle(
          //             fontSize: 9.sp,
          //             fontWeight: FontWeight.w900,
          //             color: _activeFilter == 'veg'
          //                 ? const Color(0xFF0F8A5F)
          //                 : _activeFilter == 'nonveg'
          //                 ? const Color(0xFFE43B3F)
          //                 : Colors.grey.shade700,
          //             letterSpacing: 0.5,
          //           ),
          //         ),
          //         SizedBox(height: 3.h),
          //         _buildToggleSwitchSymbol(_activeFilter),
          //       ],
          //     ),
          //   ),
          // ),
        ],
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

  Widget _buildHorizontalCategoryBar(VendorEntityCategoryState state) {
    if (state.isCategoriesLoading) {
      return _buildCategoryShimmer();
    }

    final activeCategories = state.categories
        .where((cat) => cat.isActive == true)
        .toList();

    if (activeCategories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96.w,
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: activeCategories.length,
        itemBuilder: (context, index) {
          final cat = activeCategories[index];
          final isSelected = cat.uuId == _currentCategoryUuid;
          final localAssetPath = _getCategoryAsset(cat.entityCategory);
          final hasNetworkImage = cat.image != null && cat.image!.isNotEmpty;

          return GestureDetector(
            onTap: () {
              if (_currentCategoryUuid != cat.uuId) {
                setState(() {
                  _currentCategoryUuid = cat.uuId ?? '';
                  _currentCategoryName = cat.entityCategory ?? 'Outlets';
                });
                _fetchData();
              }
            },
            child: Container(
              width: 75.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 60.w,
                        width: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFC8019)
                                : Colors.black.withValues(alpha: 0.04),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: EdgeInsets.all(isSelected ? 2.0 : 0.0),
                          child: ClipOval(
                            child: hasNetworkImage
                                ? Image.network(
                                    cat.image!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.network(
                                              localAssetPath,
                                              fit: BoxFit.cover,
                                            ),
                                  )
                                : Image.network(
                                    localAssetPath,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.w),
                  Text(
                    cat.entityCategory ?? "",
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFFC8019)
                          : Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCuisineIndicator(bool isVeg) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? const Color(0xFF0F8A5F) : const Color(0xFFE43B3F),
          width: 1.2.w,
        ),
        borderRadius: BorderRadius.circular(2.w),
      ),
      padding: EdgeInsets.all(1.5.w),
      child: Container(
        decoration: BoxDecoration(
          color: isVeg ? const Color(0xFF0F8A5F) : const Color(0xFFE43B3F),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(EntityCategoryVendor vendor) {
    final String image =
        (vendor.entityImage != null && vendor.entityImage!.isNotEmpty)
        ? vendor.entityImage!
        : _getCategoryAsset(_currentCategoryName);
    final String title = vendor.entityName ?? "Outlet";
    final String location = vendor.area ?? '';
    final String city = vendor.city ?? "";

    final bool isDeliverable = vendor.isServiceable;
    final double rating = vendor.displayRating;
    final String deliveryTime = vendor.displayDeliveryTime;

    final double distance = vendor.displayDistance;
    final String formattedDistance = formatDistance(distance);

    final String cuisinesString = vendor.cuisinesString.isNotEmpty
        ? vendor.cuisinesString
        : _currentCategoryName;

    final hasVeg =
        (vendor.foodType?.toLowerCase() == 'veg' ||
            vendor.foodType?.toLowerCase() == 'both') ||
        (vendor.vendorItems?.any(
              (item) => item.cuisineType?.toLowerCase() == 'veg',
            ) ??
            false);
    final hasNonVeg =
        (vendor.foodType?.toLowerCase() == 'nonveg' ||
            vendor.foodType?.toLowerCase() == 'non-veg' ||
            vendor.foodType?.toLowerCase() == 'both') ||
        (vendor.vendorItems?.any(
              (item) =>
                  item.cuisineType?.toLowerCase() == 'nonveg' ||
                  item.cuisineType?.toLowerCase() == 'non-veg',
            ) ??
            false);

    final List<Widget> indicators = [];
    if (hasVeg) indicators.add(_buildCuisineIndicator(true));
    if (hasVeg && hasNonVeg) indicators.add(SizedBox(width: 3.w));
    if (hasNonVeg) indicators.add(_buildCuisineIndicator(false));

    // ─── Shared navigation: BOTH states open RestaurantDetailsPage ──────────
    void navigateToDetails() {
      context.push(
        AppRoutePath.restaurantDetails,
        extra: {
          "id": vendor.id,
          "name": title,
          "image": image,
          "location": "$location, $city",
          "foodType": hasVeg && hasNonVeg
              ? "both"
              : (hasVeg ? "veg" : "nonveg"),
          "isServiceable":
              isDeliverable, // false → cart/order disabled in details
          "isDeliverable": isDeliverable,
        },
      );
    }

    // ─── Card footer ────────────────────────────────────────────────────────
    final Widget footer = isDeliverable
        // Deliverable footer: green-accented delivery info
        ? Container(
            margin: EdgeInsets.only(top: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF4),
              borderRadius: BorderRadius.circular(8.w),
              border: Border.all(color: const Color(0xFFB2DFCC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: const Color(0xFF0F8A5F),
                  size: 12.w,
                ),
                SizedBox(width: 4.w),
                Text(
                  "$formattedDistance ",
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F8A5F),
                  ),
                ),
                // Container(
                //   margin: EdgeInsets.symmetric(horizontal: 6.w),
                //   width: 3.w,
                //   height: 3.w,
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF0F8A5F).withValues(alpha: 0.4),
                //     shape: BoxShape.circle,
                //   ),
                // ),
                // Icon(
                //   Icons.access_time_rounded,
                //   color: const Color(0xFF0F8A5F),
                //   size: 12.w,
                // ),
                // SizedBox(width: 3.w),
                // Text(
                //   deliveryTime,
                //   style: TextStyle(
                //     fontSize: 10.sp,
                //     fontWeight: FontWeight.w800,
                //     color: const Color(0xFF0F8A5F),
                //   ),
                // ),
              ],
            ),
          )
        // Non-deliverable footer: red/grey unavailability message
        : Container(
            margin: EdgeInsets.only(top: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(8.w),
              border: Border.all(color: const Color(0xFFFFBDBD), width: 0.8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_off_outlined,
                  color: Colors.red.shade400,
                  size: 12.w,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    "Currently unavailable in your delivery area",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );

    // ─── Core card widget ───────────────────────────────────────────────────
    final Widget cardContent = GestureDetector(
      onTap: isDeliverable
          ? navigateToDetails
          : () {
              SnackbarUtils.showSuccessSnackbar(
                context,
                "restaurant is unavailable",
              );
            },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: Colors.grey.shade100, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + badges ──────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.w),
                  child: Image.network(
                    image,
                    width: 105.w,
                    height: 105.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 105.w,
                      height: 105.w,
                      color: Colors.orange.shade50,
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.orange.shade200,
                        size: 24.w,
                      ),
                    ),
                  ),
                ),
                // "Out of Delivery Area" badge for non-deliverable
                if (!isDeliverable)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8.w),
                          bottomRight: Radius.circular(8.w),
                        ),
                      ),
                      child: Text(
                        'Out of Delivery Area',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                // Favourite heart button
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 0.5),
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 12.w,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            // ── Text content ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (indicators.isNotEmpty) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: indicators,
                              ),
                              SizedBox(width: 6.w),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDeliverable
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade400,
                        size: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Rating pill
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDeliverable
                          ? (rating == 0.0 || vendor.rating == null
                                ? const Color(0xFFE8F5E9)
                                : (rating >= 4.0
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFF8E1)))
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: isDeliverable
                              ? (rating == 0.0 || vendor.rating == null
                                    ? const Color(0xFF0F8A5F)
                                    : (rating >= 4.0
                                          ? const Color(0xFF0F8A5F)
                                          : Colors.amber.shade700))
                              : Colors.grey.shade400,
                          size: 11.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          rating == 0.0 || vendor.rating == null
                              ? "0"
                              : rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w900,
                            color: isDeliverable
                                ? (rating == 0.0 || vendor.rating == null
                                      ? const Color(0xFF0F8A5F)
                                      : (rating >= 4.0
                                            ? const Color(0xFF0F8A5F)
                                            : Colors.amber.shade800))
                                : Colors.grey.shade500,
                          ),
                        ),
                        if (vendor.totalReviews != null &&
                            vendor.totalReviews! > 0) ...[
                          SizedBox(width: 4.w),
                          Text(
                            "(${vendor.totalReviews})",
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isDeliverable
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  // Cuisines
                  Text(
                    cuisinesString,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey.shade400,
                        size: 12.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          "$location, $city",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Footer
                  footer,
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // ─── Non-deliverable: full-card grayscale + reduced opacity ─────────────
    if (!isDeliverable) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.75, child: cardContent),
      );
    }

    // ─── Deliverable: full-color card ────────────────────────────────────────
    return cardContent;
  }

  Widget _buildCategoryShimmer() {
    return SizedBox(
      height: 96.w,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 75.w,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                Container(
                  height: 60.w,
                  width: 60.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                ),
                SizedBox(height: 6.w),
                Container(
                  width: 45.w,
                  height: 8.h,
                  color: Colors.grey.shade100,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: List.generate(4, (index) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(color: Colors.grey.shade100, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 95.w,
                  height: 95.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120.w,
                        height: 12.h,
                        color: Colors.grey.shade100,
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        height: 16.h,
                        color: Colors.grey.shade100,
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: 80.w,
                        height: 10.h,
                        color: Colors.grey.shade100,
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: 140.w,
                        height: 10.h,
                        color: Colors.grey.shade100,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48.w),
            SizedBox(height: 12.h),
            Text(
              'Failed to load outlets',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              error,
              style: TextStyle(fontSize: 11.5.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                context.read<VendorEntityCategoryBloc>().add(
                  FetchVendorEntityCategoriesEvent(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC8019),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.w),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              color: Colors.grey.shade300,
              size: 48.w,
            ),
            SizedBox(height: 12.h),
            Text(
              'No Outlets Available',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'There are no active outlets in this category currently.',
              style: TextStyle(fontSize: 11.5.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
