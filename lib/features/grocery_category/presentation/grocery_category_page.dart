import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/features/grocery_subCtegory/data/models/homePage_model.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/widgets/shimmer_placeholder.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../../../routes/app_route_path.dart';
import '../../../config/injector_conf.dart';
import '../../grocery_subCtegory/presentation/grocery_subCategory_page.dart';
import '../../grocery_subCtegory/widgets/grocery_banner_slider.dart';
import '../../grocery_subCtegory/bloc/homePage/homePage_bloc.dart';
import '../../grocery_subCtegory/bloc/homePage/homePage_event.dart';
import '../../grocery_subCtegory/bloc/homePage/homePage_state.dart';
import '../../grocery_subCtegory/bloc/categoryProducts/category_products_bloc.dart';
import '../../grocery_subCtegory/bloc/categoryProducts/category_products_event.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../food_category/widget/veg_nonveg_filter.dart';
import '../../orders/data/models/today_active_order_model.dart';
import '../../orders/data/repository/grocery_order_repo.dart';

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
  TodayActiveOrderItemModel? _activeOrder;
  bool _hasFetchedActiveOrder = false;

  void _fetchData() {
    final loc = locationService.locationNotifier.value;
    final lat = loc?.lat ?? 0.0;
    final lng = loc?.lng ?? 0.0;
    
    final targetTabSlug = (!widget.isHomeTab &&
            widget.initialTabSlug != null &&
            widget.initialTabSlug!.isNotEmpty)
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

  Future<void> _fetchTodayActiveOrders() async {
    try {
      final repo = getIt<GroceryOrderRepository>();
      final result = await repo.getTodayActiveOrders(page: 1, limit: 5).timeout(
        const Duration(milliseconds: 1500),
      );
      result.fold(
        (failure) {
          logger.d('No active orders or fetch failed: ${failure.message}');
          if (mounted) {
            setState(() {
              _activeOrder = null;
              _hasFetchedActiveOrder = true;
            });
          }
        },
        (ordersResponse) {
          if (mounted) {
            setState(() {
              _activeOrder = ordersResponse.data.isNotEmpty
                  ? ordersResponse.data.first
                  : null;
              _hasFetchedActiveOrder = true;
            });
          }
        },
      );
    } catch (e) {
      logger.d('Active order fetch completed or timed out: $e');
      if (mounted) {
        setState(() {
          _activeOrder = null;
          _hasFetchedActiveOrder = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTodayActiveOrders();
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
    _fetchData();
    await _fetchTodayActiveOrders();

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
          if (state is HomePageLoading || state is HomePageInitial || !_hasFetchedActiveOrder) {
            return _buildGroceryShimmer();
          } else if (state is HomePageError) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48.w,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Error: ${state.message}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: _onRefresh,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFC8019),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.w),
                              ),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else if (state is HomePageLoaded) {
            final rawTabs = state.homePageModel.data?.homeTabs ?? [];

            if (rawTabs.isEmpty) {
              return _buildGroceryShimmer();
            }

            // Take at most 2 category cards for the header
            final List<HomeTabModel> cards = rawTabs.take(2).toList();

            // Extract top banners
            final banners = <BannerModel>[];
            for (var tab in rawTabs) {
              if (tab.homeSections != null) {
                for (var section in tab.homeSections!) {
                  if (section.sectionType == 'banner' &&
                      section.banners != null &&
                      section.banners!.isNotEmpty) {
                    banners.addAll(section.banners!);
                  }
                }
              }
            }

            // Combine non-banner sections for below the cards
            final allSections = <HomeSectionModel>[];
            final seenSlugs = <String>{};
            for (var tab in rawTabs) {
              if (tab.homeSections != null) {
                for (var section in tab.homeSections!) {
                  if (section.sectionType != 'banner' &&
                      (section.slug == null ||
                          !seenSlugs.contains(section.slug))) {
                    allSections.add(section);
                    if (section.slug != null) seenSlugs.add(section.slug!);
                  }
                }
              }
            }
            final allTabData = HomeTabModel(
              id: -1,
              tabName: 'All',
              slug: '',
              homeSections: allSections,
            );

            final double cardHeight = 96.h;
            final double cardSpacing = 8.h;
            final double verticalPadding = 12.h;
            final double ongoingCardHeight = (_activeOrder != null) ? 60.h : 0.0;
            final double ongoingCardSpacing = (_activeOrder != null && cards.isNotEmpty) ? 8.h : 0.0;

            final double totalHeaderHeight = (cards.isEmpty && _activeOrder == null)
                ? 0.0
                : (cardHeight * cards.length) +
                    (cardSpacing * (cards.isNotEmpty ? cards.length - 1 : 0)) +
                    ongoingCardHeight +
                    ongoingCardSpacing +
                    verticalPadding;

            final Widget? pinnedCardsWidget = (cards.isNotEmpty || _activeOrder != null)
                ? Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          if (i > 0) SizedBox(height: cardSpacing),
                          SizedBox(
                            height: cardHeight,
                            child: _buildCategoryCard(
                              tab: cards[i],
                              index: i,
                              onTap: () {
                                logger.d(
                                  '🥦 GroceryCategoryPage: Tapped category card "${cards[i].tabName}" (slug="${cards[i].slug}") -> Opening products page',
                                );
                                _navigateToProductsPage(cards[i]);
                              },
                            ),
                          ),
                        ],
                        if (_activeOrder != null) ...[
                          SizedBox(height: 8.h),
                          _buildOngoingOrderCard(_activeOrder!),
                        ],
                      ],
                    ),
                  )
                : null;

            final topSlivers = <Widget>[
              if (banners.isNotEmpty && _searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h, bottom: 6.h),
                    child: GroceryBannerSlider(banners: banners),
                  ),
                ),
            ];

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
                body: GrocerySubCategoryPage(
                  tabData: allTabData,
                  topSlivers: topSlivers,
                  pinnedHeader: pinnedCardsWidget,
                  pinnedHeaderHeight: cards.isNotEmpty ? totalHeaderHeight : null,
                  onRefresh: _onRefresh,
                  searchQuery: _searchQuery,
                  activeFilter: _activeFilter,
                  initialCategorySlug: widget.initialCategorySlug,
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
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _navigateToProductsPage(HomeTabModel card) {
    final loc = locationService.locationNotifier.value;
    final lat = loc?.lat ?? 0.0;
    final lng = loc?.lng ?? 0.0;

    final catModel = CategoryModel(
      id: card.id,
      uuId: card.uuId,
      categoryName: card.tabName,
      slug: card.slug,
      categoryImage: card.homeIcon,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<CategoryProductsBloc>(
              create: (context) => getIt<CategoryProductsBloc>()
                ..add(
                  FetchProductsAndFiltersEvent(
                    homeTabId: card.id,
                    homeTabUuId: card.uuId,
                    categorySlug: null,
                    subCategoryUuId: null,
                    lat: lat,
                    lng: lng,
                    resetFilters: true,
                  ),
                ),
            ),
          ],
          child: HomeTabSubcategoryProductPage(
            category: catModel,
            tabData: card,
            searchQuery: _searchQuery,
            activeFilter: _activeFilter,
            onRefresh: _onRefresh,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required HomeTabModel tab,
    required int index,
    required VoidCallback onTap,
  }) {
    final List<List<Color>> fallbackGradients = [
      [const Color(0xFF26C66D), const Color(0xFF1EA95B)], // Fresh Green
      [const Color(0xFFA8232A), const Color(0xFFDB4C57)], // Apple Red
    ];
    final cardGradient = fallbackGradients[index % fallbackGradients.length];
    final bool hasImage = tab.homeIcon != null && tab.homeIcon!.isNotEmpty;

    return Container(
      height: 105.h,
      decoration: BoxDecoration(
        color: cardGradient.first,
        borderRadius: BorderRadius.circular(18.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.25),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full card background image
              if (hasImage)
                Image.network(
                  tab.homeIcon!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: cardGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cardGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

              // Gradient overlay to make text and button crisp & readable
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.72),
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.05),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),

              // Name and Button overlay on top of the image (no selection indicator)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 18.w,
                  vertical: 14.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab.tabName ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.6),
                            offset: const Offset(0, 1.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Shop Now",
                            style: TextStyle(
                              color: const Color(0xFF1A202C),
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: const Color(0xFF1A202C),
                            size: 13.w,
                          ),
                        ],
                      ),
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

  Widget _buildOngoingOrderCard(TodayActiveOrderItemModel order) {
    final status = order.orderStatus.toUpperCase();
    String statusSubtitle = 'Your order is confirmed';

    if (status == 'PLACED' || status == 'RECEIVED' || status == 'CONFIRMED' || status == 'PENDING') {
      statusSubtitle = 'Your order is confirmed';
    } else if (status == 'PREPARING' || status == 'PACKED' || status == 'ACCEPTED' || status == 'READY') {
      statusSubtitle = 'Your order is packed';
    } else if (status == 'OUT_FOR_DELIVERY' || status == 'ON_THE_WAY' || status == 'DISPATCHED') {
      statusSubtitle = 'Your order is on the way';
    } else if (status == 'DELIVERED' || status == 'COMPLETED') {
      statusSubtitle = 'Your order is delivered';
    } else {
      statusSubtitle = 'Your order is ${order.orderStatus.replaceAll('_', ' ').toLowerCase()}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(AppRoutePath.orderDetails, extra: order.uuId);
        },
        borderRadius: BorderRadius.circular(16.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF1FAF4),
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(color: const Color(0xFFD3EEDC), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF03B875).withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left Icon
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        color: const Color(0xFF0E7F47),
                        size: 22.sp,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time_filled,
                            color: const Color(0xFF0E7F47),
                            size: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Order Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ongoing Order',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A2B),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      statusSubtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5A796A),
                      ),
                    ),
                  ],
                ),
              ),
              // View Details Button
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.w),
                  border: Border.all(color: const Color(0xFF98DBB3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0E7F47),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 11.sp,
                      color: const Color(0xFF0E7F47),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.025,
          duration: 900.ms,
          curve: Curves.easeInOut,
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
