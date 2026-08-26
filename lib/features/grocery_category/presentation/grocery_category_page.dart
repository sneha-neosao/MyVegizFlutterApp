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

            final hasServerAllTab = rawTabs.any(
              (tab) =>
                  tab.slug == '' ||
                  tab.slug == 'all' ||
                  tab.tabName?.toLowerCase().trim() == 'all',
            );

            final List<HomeTabModel> tabs;
            if (hasServerAllTab) {
              tabs = rawTabs;
            } else {
              // Combine all sections for the "All" tab (unique by slug to avoid duplicates)
              final allSections = <HomeSectionModel>[];
              final seenSlugs = <String>{};
              for (var tab in rawTabs) {
                if (tab.homeSections != null) {
                  for (var section in tab.homeSections!) {
                    if (section.slug == null ||
                        !seenSlugs.contains(section.slug)) {
                      allSections.add(section);
                      if (section.slug != null) seenSlugs.add(section.slug!);
                    }
                  }
                }
              }

              final mainCatImage = state.homePageModel.data?.mainCategory?.mainCategoryImage;
              final allTabIcon = (mainCatImage != null && mainCatImage.isNotEmpty)
                  ? mainCatImage
                  : 'https://cdn-icons-png.flaticon.com/512/3050/3050212.png';

              final allTab = HomeTabModel(
                id: -1,
                tabName: 'All',
                slug: '', // Empty slug for "All" data
                homeIcon: allTabIcon,
                homeSections: allSections,
              );

              tabs = [allTab, ...rawTabs];
            }

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

                  final scaffold = Scaffold(
                    backgroundColor: Colors.white,
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
                      bottom: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: const Color(0xFF03B875),
                        indicatorWeight: 1,
                        labelColor: const Color(0xFF03B875),
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13.sp,
                        ),

                        onTap: (index) {
                          final selectedTab = tabs[index];
                          logger.d(
                            '🥦 GroceryCategoryPage: Tab switched to "${selectedTab.tabName}" (slug="${selectedTab.slug}")',
                          );
                        },

                        tabs: tabs.map((tab) {
                          return Tab(
                            iconMargin: EdgeInsets.only(bottom: 6.h),
                            icon: ClipOval(
                              child:
                                  (tab.homeIcon != null &&
                                      tab.homeIcon!.isNotEmpty)
                                  ? Image.network(
                                      tab.homeIcon!,
                                      width: 28.w,
                                      height: 28.w,
                                      fit: BoxFit.fill,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Icon(Icons.category, size: 28.w),
                                    )
                                  : Icon(Icons.category, size: 28.w),
                            ),
                            text: tab.tabName ?? '',
                          );
                        }).toList(),
                      ),
                    ),

                    // 🔥 SAME UI, no change
                    body: TabBarView(
                      controller: tabController,
                      children: tabs.map((tab) {
                        return GrocerySubCategoryPage(
                          tabData: tab,
                          onRefresh: _onRefresh,
                          searchQuery: _searchQuery,
                          activeFilter: _activeFilter,
                          initialCategorySlug: tab.slug == widget.initialTabSlug
                              ? widget.initialCategorySlug
                              : null,
                        );
                      }).toList(),
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
                },
              ),
            );
          }

          return const SizedBox();
        },
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

//
//             return DefaultTabController(
//               length: tabs.length,
//               child: Scaffold(
//                 backgroundColor: Colors.white,
//                 appBar: CustomHomeAppBar(
//                   bottom: TabBar(
//                     isScrollable: true,
//                     tabAlignment: TabAlignment.start,
//                     indicatorColor: const Color(0xFFFC8019), // Swiggy Orange
//                     indicatorWeight: 1,
//                     labelColor: const Color(0xFFFC8019),
//                     unselectedLabelColor: Colors.grey.shade600,
//                     labelStyle: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: 12,
//                     ),
//                     unselectedLabelStyle: const TextStyle(
//                       fontWeight: FontWeight.w500,
//                       fontSize: 13,
//                     ),
//                     tabs: tabs.map((tab) {
//                       return Tab(
//                         iconMargin: const EdgeInsets.only(bottom: 6),
//                         icon: ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child:
//                               (tab.homeIcon != null && tab.homeIcon!.isNotEmpty)
//                               ? Image.network(
//                                   tab.homeIcon!,
//                                   width: 28,
//                                   height: 28,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (context, error, stackTrace) =>
//                                       const Icon(Icons.category, size: 28),
//                                 )
//                               : const Icon(Icons.category, size: 28),
//                         ),
//                         text: tab.tabName ?? '',
//                       );
//                     }).toList(),
//                   ),
//                 ),
//                 body: TabBarView(
//                   children: tabs.map((tab) {
//                     return GrocerySubCategoryPage(tabData: tab);
//                   }).toList(),
//                 ),
//               ),
//             );
//           }
//           return const SizedBox();
//         },
//       ),
//     );
//   }
// }
