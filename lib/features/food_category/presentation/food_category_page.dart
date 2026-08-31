import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/features/cart/data/cart_data.dart';
import 'package:my_vegiz_flutter/features/food_category/widget/filter_widget.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../../../routes/app_route_path.dart';
import '../../../core/utils/responsive_utils.dart';
import '../bloc/vendor_banner/vendor_banner_bloc.dart';
import '../bloc/vendor_banner/vendor_banner_event.dart';
import '../bloc/vendor_banner/vendor_banner_state.dart';
import '../data/models/vendor_banner_model.dart';
import '../bloc/vendor_entity_category/vendor_entity_category_bloc.dart';
import '../bloc/vendor_entity_category/vendor_entity_category_event.dart';
import '../bloc/vendor_home_section/vendor_home_section_bloc.dart';
import '../bloc/vendor_home_section/vendor_home_section_event.dart';
import '../bloc/vendor_home_section/vendor_home_section_state.dart';
import '../data/models/vendor_home_section_model.dart';
import '../widget/veg_nonveg_filter.dart';
import '../widget/vendor_entityCategory_section.dart';
import '../widget/top_explore_section.dart';
import '../widget/swiggy_specials_section.dart';
import '../widget/home_section_vendor_list.dart';
import '../widget/food_category_shimmer.dart';
import '../../mainCetegories/bloc/mainCategories_bloc.dart';
import '../../mainCetegories/bloc/mainCategories_event.dart';

import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/food_cart_bloc.dart';
import '../../home/presentation/pages/home_page.dart';

class FoodCategoryPage extends StatefulWidget {
  final bool isHomeTab;
  final bool fromCart;
  final bool isFood;

  const FoodCategoryPage({
    super.key,
    this.isHomeTab = false,
    this.fromCart = false,
    this.isFood = true,
  });

  @override
  State<FoodCategoryPage> createState() => _FoodCategoryPageState();
}

class _FoodCategoryPageState extends State<FoodCategoryPage> {
  SwiggyFilterState _filterState = SwiggyFilterState();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  void _fetchInitialData() {
    final loc = locationService.locationNotifier.value;
    final lat = loc?.lat ?? 0.0;
    final lng = loc?.lng ?? 0.0;

    final bannerBloc = context.read<VendorBannerBloc>();
    if (bannerBloc.state.banners.isEmpty && !bannerBloc.state.isBannersLoading) {
      bannerBloc.add(FetchVendorBannersEvent(lat: lat, lng: lng));
    }

    final entityCatBloc = context.read<VendorEntityCategoryBloc>();
    if (entityCatBloc.state.categories.isEmpty && !entityCatBloc.state.isCategoriesLoading) {
      entityCatBloc.add(FetchVendorEntityCategoriesEvent());
    }

    final homeSectionBloc = context.read<VendorHomeSectionBloc>();
    if (homeSectionBloc.state.homeSections.isEmpty && !homeSectionBloc.state.isHomeSectionsLoading) {
      homeSectionBloc.add(const FetchVendorHomeSectionFiltersEvent());
      _fetchHomeSections();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    logger.i('🔄 FoodCategoryPage: Pull-to-refresh triggered — refreshing all APIs');
    final loc = locationService.locationNotifier.value;
    final lat = loc?.lat ?? 0.0;
    final lng = loc?.lng ?? 0.0;

    if (widget.isHomeTab) {
      context.read<MainCategoriesBloc>().add(FetchMainCategories());
    }

    context.read<VendorBannerBloc>().add(FetchVendorBannersEvent(lat: lat, lng: lng));
    context.read<VendorEntityCategoryBloc>().add(FetchVendorEntityCategoriesEvent());
    context.read<VendorHomeSectionBloc>().add(const FetchVendorHomeSectionFiltersEvent());
    _fetchHomeSections();

    getIt<CartBloc>().add(GetCartListEvent(lat: lat, lng: lng));
    getIt<FoodCartBloc>().add(GetCartListEvent(lat: lat, lng: lng));

    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _fetchHomeSections() {
    final loc = locationService.locationNotifier.value;
    if (loc == null || (loc.lat == 0.0 && loc.lng == 0.0)) return;

    final blocState = context.read<VendorHomeSectionBloc>().state;
    final validSortKeys = blocState.filters?.sortOptions
            ?.map((o) => o.key)
            .whereType<String>()
            .toList() ??
        [];

    final String? sortByParam = validSortKeys.contains(_filterState.sortBy)
        ? _filterState.sortBy
        : null;

    String foodTypeParam = 'both';
    if (_filterState.vegNonVeg == 'veg') {
      foodTypeParam = 'veg';
    } else if (_filterState.vegNonVeg == 'nonveg' ||
        _filterState.vegNonVeg == 'non_veg') {
      foodTypeParam = 'nonveg';
    }

    context.read<VendorHomeSectionBloc>().add(
          FetchVendorHomeSectionsEvent(
            lat: loc.lat,
            lng: loc.lng,
            sortBy: sortByParam,
            foodType: foodTypeParam,
          ),
        );
  }

  Widget _buildDynamicBannerCard(VendorBannerModel banner) {
    final bool isDeliverable =
        banner.vendorId == null || (banner.isDeliverable ?? true);
    final bool isBannerActive = banner.isActive ?? true;

    final Widget cardContent = GestureDetector(
      onTap: !isBannerActive || !isDeliverable
          ? () {
              SnackbarUtils.showSuccessSnackbar(
                context,
                "restaurant is unavailable",
              );
            }
          : () {
              if (banner.vendorId != null) {

                context.push(
                  AppRoutePath.restaurantDetails,
                  extra: {
                    "id": banner.vendorId,
                    "name": banner.vendorName ?? banner.title ?? "Restaurant",
                    "image": banner.image ?? "",
                    "isFromBanner": true,
                    "isServiceable": isDeliverable,
                    "isDeliverable": isDeliverable,
                  },
                );
              } else {
                ScaffoldMessenger.of(context).clearSnackBars();
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('Promo: ${banner.title ?? "Special Offer"}'),
                //     duration: const Duration(seconds: 2),
                //   ),
                // );
              }
            },
      child: Container(
        width: 280.w,
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.network(
              banner.image ?? "",
              height: 150.h,
              width: 280.w,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150.h,
                width: 280.w,
                color: Colors.orange.shade50,
                child: Icon(
                  Icons.fastfood,
                  color: Colors.orange.shade200,
                  size: 32.w,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12.h,
              left: 12.w,
              right: 12.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.title ?? "",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (banner.vendorName != null &&
                      banner.vendorName!.isNotEmpty) ...[
                    Text(
                      banner.vendorName!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!isDeliverable)
              Positioned(
                top: 12.h,
                left: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  child: Text(
                    "Currently Unavailable",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!isBannerActive) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: Opacity(opacity: 0.5, child: cardContent),
      );
    }

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

    return cardContent;
  }

  @override
  Widget build(BuildContext context) {
    isFoodCart = true; // Current flow is Food

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomHomeAppBar(
        showFoodFilters: false, // Commented: Hide the top veg toggle as requested
        activeFilter: _activeFilter,
        onFilterTap: () {
          // showFoodFilterBottomSheet(context, _activeFilter, (newFilter) {
          //   setState(() {
          //     _activeFilter = newFilter;
          //     if (newFilter == 'veg') {
          //       _filterState.vegNonVeg = 'veg';
          //     } else if (newFilter == 'nonveg') {
          //       _filterState.vegNonVeg = 'nonveg';
          //     } else {
          //       _filterState.vegNonVeg = 'both';
          //     }
          //   });
          //   _fetchHomeSections();
          // });
        },
        searchController: _searchController,
        onSearchChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        onSearchClear: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
        },
        searchHintText: 'Search restaurants, dishes...',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Builder(
            builder: (context) {
              final bannerState = context.watch<VendorBannerBloc>().state;
              final categoryState = context.watch<VendorEntityCategoryBloc>().state;
              final homeSectionState = context.watch<VendorHomeSectionBloc>().state;

              final bool isLoading = (bannerState.isBannersLoading && bannerState.banners.isEmpty) ||
                                     (categoryState.isCategoriesLoading && categoryState.categories.isEmpty) ||
                                     homeSectionState.isHomeSectionsLoading;

              if (isLoading) {
                return const FoodCategoryShimmer();
              }

              // --- Error state ---
              if (homeSectionState.homeSectionsError != null) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 80.h,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 56.w,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Unable to load content',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          homeSectionState.homeSectionsError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<VendorHomeSectionBloc>().add(
                              const FetchVendorHomeSectionFiltersEvent(),
                            );
                            _fetchHomeSections();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFC8019),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.w),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Dynamic section builder
              final List<Widget> dynamicSections = [];
              
              for (var section in homeSectionState.homeSections) {
                if (section.isActive != true) continue;

                if (section.sectionType == 'banner') {
                  if (_searchQuery.isEmpty) {
                    dynamicSections.add(SwiggyPromoBanner(banners: section.banners ?? []));
                  }
                } else if (section.sectionType == 'vendorItem') {
                  var items = section.vendorItems ?? [];
                  if (_searchQuery.isNotEmpty) {
                    items = items
                        .where(
                          (item) => (item.itemName ?? '')
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()),
                        )
                        .toList();
                  }
                  if (_activeFilter != 'all') {
                    items = items.where((item) {
                      final cType = item.cuisineType?.toLowerCase().trim();
                      if (_activeFilter == 'veg') {
                        return cType == 'veg';
                      } else if (_activeFilter == 'nonveg') {
                        return cType == 'nonveg' || cType == 'non-veg';
                      }
                      return true;
                    }).toList();
                  }
                  if (items.isNotEmpty) {
                    dynamicSections.add(RecommendedFoodsSection(
                      items: items,
                      title: section.title ?? 'Recommended Foods',
                      description: section.description ?? 'Best Items',
                    ));
                  }
                } else if (section.sectionType == 'vendor') {
                  var vendors = section.vendors ?? [];
                  if (_searchQuery.isNotEmpty) {
                    vendors = vendors
                        .where(
                          (v) => (v.entityName ?? '').toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
                  }
                  if (_activeFilter != 'all') {
                    vendors = vendors.where((v) {
                      final hasVegItems =
                          (v.foodType?.toLowerCase() == 'veg' ||
                          v.foodType?.toLowerCase() == 'both');
                      final hasNonVegItems =
                          (v.foodType?.toLowerCase() == 'nonveg' ||
                          v.foodType?.toLowerCase() == 'non-veg' ||
                          v.foodType?.toLowerCase() == 'both');
                      if (_activeFilter == 'veg') return hasVegItems;
                      if (_activeFilter == 'nonveg') return hasNonVegItems;
                      return true;
                    }).toList();
                  }
                  if (vendors.isNotEmpty) {
                    dynamicSections.add(HomeSectionVendorList(
                      vendors: vendors,
                      title: section.title ?? 'Top Restaurants',
                      description: section.description,
                    ));
                  }
                }
              }

              final bool isAnythingVisible =
                  categoryState.categories.any((cat) => cat.isActive == true) ||
                  dynamicSections.isNotEmpty;

              if (_searchQuery.isNotEmpty && !isAnythingVisible) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: EmptySearchState(query: _searchQuery),
                );
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),

                    // Dynamic Vendor Entity Categories (from API) - "What's in your mind?"
                    VendorEntityCategorySection(searchQuery: _searchQuery),

                    // Filter Bar (state filters applied to API-sourced content)
                    CommonFilterBar(
                      filterState: _filterState,
                      sortOptions: homeSectionState.filters?.sortOptions ?? [],
                      foodTypes: homeSectionState.filters?.foodTypes ?? [],
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
                        _fetchHomeSections();
                      },
                    ),

                    SizedBox(height: 8.h),

                    // All dynamic sections from the home-sections API
                    ...dynamicSections,

                    // --- Empty state when no sections returned ---
                    if (homeSectionState.homeSections.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 60.h,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.restaurant_menu_outlined,
                                size: 56.w,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No content available right now',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Pull down to refresh and check again.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: widget.isHomeTab
          ? const CustomBottomNavBar(currentIndex: 0)
          : null,
    );

    if (widget.isHomeTab) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (widget.fromCart) {
            context.go(AppRoutePath.cart, extra: widget.isFood);
          } else {
            SystemNavigator.pop();
          }
        },
        child: scaffold,
      );
    }

    return scaffold;
  }
}
