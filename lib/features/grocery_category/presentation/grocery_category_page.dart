import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/features/grocery_subCtegory/data/models/homePage_model.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/widgets/shimmer_placeholder.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../../../routes/app_route_path.dart';
import '../../grocery_subCtegory/presentation/grocery_subCategory_page.dart';
import '../../grocery_subCtegory/bloc/homePage/homePage_bloc.dart';
import '../../grocery_subCtegory/bloc/homePage/homePage_event.dart';
import '../../grocery_subCtegory/bloc/homePage/homePage_state.dart';
import '../../mainCetegories/bloc/mainCategories_bloc.dart';
import '../../mainCetegories/bloc/mainCategories_event.dart';
import '../../../core/utils/responsive_utils.dart';

import '../../food_category/widget/veg_nonveg_filter.dart';
import 'package:my_vegiz_flutter/features/cart/data/cart_data.dart';

class GroceryCategoryPage extends StatefulWidget {
  final String? initialTabSlug;
  final String? initialCategorySlug;
  final String mainCategorySlug;
  final bool isHomeTab;
  final bool fromCart;
  final bool isFood;

  const GroceryCategoryPage({
    super.key,
    this.initialTabSlug,
    this.initialCategorySlug,
    this.mainCategorySlug = 'grocery-vegetables',
    this.isHomeTab = false,
    this.fromCart = false,
    this.isFood = false,
  });

  @override
  State<GroceryCategoryPage> createState() => _GroceryCategoryPageState();
}

class _GroceryCategoryPageState extends State<GroceryCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'all';
  void _fetchData() {
    final loc = locationService.locationNotifier.value;
    final lat = loc?.lat ?? 0.0;
    final lng = loc?.lng ?? 0.0;
    
    final targetTabSlug = (widget.initialTabSlug != null && widget.initialTabSlug!.isNotEmpty)
        ? widget.initialTabSlug
        : null;

    logger.i(
      '🥦 GroceryCategoryPage: Fetching tab data (mainCategorySlug=${widget.mainCategorySlug}, tabSlug=$targetTabSlug, lat=$lat, lng=$lng, q=$_searchQuery)',
    );
    context.read<HomePageBloc>().add(
      FetchHomePageData(
        mainCategorySlug: widget.mainCategorySlug,
        homeTabSlug: targetTabSlug,
        lat: lat,
        lng: lng,
        q: _searchQuery.isNotEmpty ? _searchQuery : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // isFoodCart = false; // Removed to prevent resetting global cart mode
    logger.i('🥦 GroceryCategoryPage: initState - Relying on route provider for initial fetch');
  }

  @override
  void dispose() {
    logger.d('🥦 GroceryCategoryPage: dispose');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    logger.i('🔄 GroceryCategoryPage: Pull-to-refresh triggered');
    if (widget.isHomeTab) {
      context.read<MainCategoriesBloc>().add(FetchMainCategories());
    }
    _fetchData();
    await context.read<HomePageBloc>().stream.firstWhere(
      (state) => state is! HomePageLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<HomePageBloc, HomePageState>(
        builder: (context, state) {
          if (state is HomePageLoading || state is HomePageInitial) {
            return _buildGroceryShimmer();
          } else if (state is HomePageError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is HomePageLoaded) {
            final rawTabs = state.homePageModel.data?.homeTabs ?? [];

            if (rawTabs.isEmpty) {
              return _buildGroceryShimmer();
            }

            // Take at most 2 tabs as requested
            final List<HomeTabModel> tabs = rawTabs.take(2).toList();

            int initialIndex = 0;
            if (widget.initialTabSlug != null) {
              final idx = tabs.indexWhere(
                (t) => t.slug == widget.initialTabSlug,
              );
              if (idx != -1) {
                initialIndex = idx;
              }
            }

            return DefaultTabController(
              length: tabs.length,
              initialIndex: initialIndex,
              child: Builder(
                builder: (context) {
                  final tabController = DefaultTabController.of(context);

                  final scaffold = Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFC59E), // Slightly deeper warm orange right at the top
                          Color(0xFFFFE3D1), // Soft transition
                          Color(0xFFFFF4EC), // Very faint orange
                          Colors.white,      // Finished into white in compact space
                        ],
                        stops: [0.0, 0.08, 0.18, 0.32],
                      ),
                    ),
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: CustomHomeAppBar(
                        showSearch: false,
                        showFoodFilters: false,
                        activeFilter: _activeFilter,
                        onFilterTap: () {
                          showFoodFilterBottomSheet(context, _activeFilter, (
                            newFilter,
                          ) {
                            setState(() {
                              _activeFilter = newFilter;
                            });
                          });
                        },
                      ),
                      body: Column(
                        children: [
                          // Cards in Column (max 2 categories)
                          if (tabs.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              child: AnimatedBuilder(
                                animation: tabController,
                                builder: (context, _) {
                                  return Column(
                                    children: [
                                      for (int i = 0; i < tabs.length; i++) ...[
                                        if (i > 0) SizedBox(height: 10.h),
                                        _buildCategoryCard(
                                          tab: tabs[i],
                                          index: i,
                                          isSelected: tabController.index == i,
                                          onTap: () {
                                            tabController.animateTo(i);
                                            logger.d(
                                              '🥦 GroceryCategoryPage: Card selected "${tabs[i].tabName}" (slug="${tabs[i].slug}")',
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),

                          // SubCategory content
                          Expanded(
                            child: TabBarView(
                              controller: tabController,
                              children: tabs.map((tab) {
                                return GrocerySubCategoryPage(
                                  tabData: tab,
                                  onRefresh: _onRefresh,
                                  searchQuery: _searchQuery,
                                  activeFilter: _activeFilter,
                                  initialCategorySlug:
                                      tab.slug == widget.initialTabSlug
                                          ? widget.initialCategorySlug
                                          : null,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      bottomNavigationBar: widget.isHomeTab
                          ? const CustomBottomNavBar(currentIndex: 0)
                          : null,
                    ),
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
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCategoryCard({
    required HomeTabModel tab,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final List<List<Color>> gradients = [
      [const Color(0xFF26C66D), const Color(0xFF1EA95B)], // Fresh Green
      [const Color(0xFFA8232A), const Color(0xFFDB4C57)], // Apple Red
    ];
    final cardGradient = gradients[index % gradients.length];

    return Container(
      height: 96.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.w),
        border: isSelected
            ? Border.all(color: Colors.white, width: 2.2)
            : Border.all(color: Colors.white.withOpacity(0.3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: cardGradient.first.withOpacity(isSelected ? 0.35 : 0.18),
            blurRadius: isSelected ? 10 : 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 10.h,
                ),
                child: Row(
                  children: [
                    // Left Column: Name & Button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tab.tabName ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                isSelected ? 0.95 : 0.25,
                              ),
                              borderRadius: BorderRadius.circular(20.w),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isSelected ? "Selected" : "Shop Now",
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? cardGradient.last
                                            : Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.arrow_forward_rounded,
                                  color:
                                      isSelected
                                          ? cardGradient.last
                                          : Colors.white,
                                  size: 12.w,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Right Image (displayed directly without circular wrappers)
                    if (tab.homeIcon != null && tab.homeIcon!.isNotEmpty)
                      SizedBox(
                        width: 76.w,
                        height: 76.h,
                        child: Image.network(
                          tab.homeIcon!,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.category,
                                color: Colors.white,
                                size: 36,
                              ),
                        ),
                      )
                    else
                      Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 48.w,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroceryShimmer() {
    final shimmerScaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomHomeAppBar(
        showSearch: false,
      ),
      bottomNavigationBar: widget.isHomeTab
          ? const CustomBottomNavBar(currentIndex: 0)
          : null,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Banners or categories list
            ShimmerPlaceholder.rounded(height: 130.h, borderRadius: 16.w),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ShimmerPlaceholder.rounded(height: 100.h, borderRadius: 16.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ShimmerPlaceholder.rounded(height: 100.h, borderRadius: 16.w),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ShimmerPlaceholder.rounded(height: 100.h, borderRadius: 16.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ShimmerPlaceholder.rounded(height: 100.h, borderRadius: 16.w),
                ),
              ],
            ),
          ],
        ),
      ),
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
        child: shimmerScaffold,
      );
    }

    return shimmerScaffold;
  }
}
