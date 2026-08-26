import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/data/models/vendor_list_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/food_cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_state.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import '../bloc/restaurant_details_bloc.dart';
import '../bloc/restaurant_details_event.dart';
import '../bloc/restaurant_details_state.dart';
import '../widget/filters_list.dart';
import '../widget/menu_accordion.dart';
import '../widget/restaurant_dark_header.dart';
import '../widget/sticky_search_bar.dart';
import '../widget/restaurant_details_shimmer.dart';
import '../../food_category/widget/Vendor_Item_Details_Card.dart';
import '../../../core/utils/network_images.dart';


class RestaurantDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? item;

  const RestaurantDetailsPage({super.key, this.item});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  late ScrollController _scrollController;
  bool _isScrolledToTop = false;
  String _activeFilter = 'all'; // 'all', 'veg', 'nonveg'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter selections that drive API calls
  String? _activeSortBy;
  String? _activeFoodType;

  final GlobalKey _store99Key = GlobalKey();
  List<GlobalKey> _categoryKeys = [];

  List<Map<String, dynamic>> _apiCategories = [];
  List<Map<String, dynamic>> _topPicks = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _categoryKeys = [];

    // Call Vendor List API and Details API if id is provided
    final vendorId = widget.item?["id"] ?? widget.item?["vendorId"];
    if (vendorId != null) {
      final parsedId = int.tryParse(vendorId.toString()) ?? vendorId;
      if (parsedId is int) {
        final loc = locationService.locationNotifier.value;
        context.read<RestaurantDetailsBloc>().add(
          FetchVendorListEvent(
            vendorId: parsedId,
            lat: loc?.lat,
            lng: loc?.lng,
          ),
        );
        context.read<RestaurantDetailsBloc>().add(
          FetchVendorDetailsEvent(
            vendorId: parsedId,
            lat: loc?.lat,
            lng: loc?.lng,
          ),
        );
        context.read<RestaurantDetailsBloc>().add(
          FetchVendorFiltersEvent(vendorId: parsedId),
        );
      }
    }
  }

  /// Re-fetches the vendor list using current filter selections.
  void _refetchVendorList() {
    final vendorId = widget.item?["id"] ?? widget.item?["vendorId"];
    if (vendorId == null) return;
    final parsedId = int.tryParse(vendorId.toString()) ?? vendorId;
    if (parsedId is! int) return;
    final loc = locationService.locationNotifier.value;
    context.read<RestaurantDetailsBloc>().add(
      FetchVendorListEvent(
        vendorId: parsedId,
        lat: loc?.lat,
        lng: loc?.lng,
        sortBy: _activeSortBy,
        foodType: _activeFoodType,
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      bool isScrolled = _scrollController.offset > 200;
      if (isScrolled != _isScrolledToTop) {
        setState(() {
          _isScrolledToTop = isScrolled;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    Navigator.pop(context); // close bottom sheet
    if (key.currentContext != null) {
      final RenderObject? renderObject = key.currentContext!.findRenderObject();
      if (renderObject != null) {
        final RenderAbstractViewport viewport = RenderAbstractViewport.of(
          renderObject,
        );
        if (viewport != null) {
          final targetOffset = viewport
              .getOffsetToReveal(renderObject, 0.0)
              .offset;
          // Subtract exactly 152 to account for the sticky header (bottomHeight 118 + approx statusBar)
          final finalOffset = (targetOffset - 152).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            finalOffset,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  void _showMenuBottomSheet() {
    final categoriesToRender = _apiCategories;
    if (categoriesToRender.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...categoriesToRender.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        String name = category['title'].toString();
                        int itemCount = 0;
                        if (category['items'] != null) {
                          itemCount = (category['items'] as List).length;
                        }
                        return _buildMenuBottomSheetItem(
                          title: name,
                          count: itemCount.toString(),
                          isNew: category['hasNewBadge'] == true,
                          onTap: () => _scrollTo(_categoryKeys[index]),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuBottomSheetItem({
    required String title,
    required String count,
    bool isNew = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetailsBottomSheet(int itemId) {
    final state = context.read<RestaurantDetailsBloc>().state;
    final vendor = (state.vendorResponse?.data != null &&
            state.vendorResponse!.data!.isNotEmpty)
        ? state.vendorResponse!.data!.first
        : null;
    final details = state.vendorDetailsResponse?.data;
    final bool isDeliverable = details?.isDeliverable ??
        vendor?.isDeliverable ??
        widget.item?["isDeliverable"] ??
        widget.item?["isServiceable"] ??
        true;

    VenderItemDetailsCard.show(context, itemId, isDeliverable);
  }

  void _mapResponseToUI(VendorListResponse response) {
    if (response.data == null || response.data!.isEmpty) {
      setState(() {
        _apiCategories = [];
        _topPicks = [];
        _categoryKeys = [];
      });
      return;
    }
    final vendor = response.data!.first;
    if (vendor.uuId != null && vendor.uuId!.isNotEmpty) {
      SecureStorage.saveSelectedVendorUuid(vendor.uuId!);
      if (vendor.entityName != null) {
        SecureStorage.saveSelectedVendorName(vendor.entityName!);
      }
      if (vendor.entityImage != null) {
        SecureStorage.saveSelectedVendorImage(vendor.entityImage!);
      }
    }
    final categories = vendor.menuCategories ?? [];

    List<Map<String, dynamic>> mappedCategories = [];
    List<Map<String, dynamic>> mappedTopPicks = [];

    for (var cat in categories) {
      List<Map<String, dynamic>> itemsList = [];
      final items = cat.vendorItems ?? [];

      for (var item in items) {
        final Map<String, dynamic> itemMap = {
          'id': item.id,
          'vendorId': vendor.id,
          'name': item.itemName ?? '',
          'slug': item.id?.toString() ?? '',
          'image': (item.primaryImage != null && item.primaryImage!.isNotEmpty)
              ? item.primaryImage!
              : NetworkImages.topPicksFallback,
          'isVeg': item.cuisineType?.toLowerCase() == 'veg',
          'cuisineType': item.cuisineType,
          'price': (item.salePrice ?? 0.0).toStringAsFixed(0),
          'description': item.description,
          'totalDeliveryTime': item.totalDeliveryTime,
          'avgRating': item.avgRating,
          'totalReviews': item.totalReviews,
          'cart_quantity': item.cartQuantity ?? 0,
          'isCustomize': item.isCustomize,
          'itemStatus': item.itemStatus ?? true,
          'customizedCategories': item.customizedCategories,
          'rawItem': item, // Store the raw item for customization sheet
        };
        itemsList.add(itemMap);

        // Treat popular/serviceable items as Top Picks
        if (itemMap['isVeg'] == true && mappedTopPicks.length < 5) {
          mappedTopPicks.add(itemMap);
        }
      }

      if (itemsList.isNotEmpty) {
        mappedCategories.add({
          'title': cat.menuCategoryName ?? '',
          'isExpanded': mappedCategories.isEmpty, // Expand first by default
          'items': itemsList,
        });
      }
    }

    setState(() {
      _apiCategories = mappedCategories;
      _topPicks = mappedTopPicks.isNotEmpty ? mappedTopPicks : _topPicks;
      _categoryKeys = List.generate(_apiCategories.length, (_) => GlobalKey());
    });
  }

  double _calculateExpandedHeight(BuildContext context, bool isDeliverable, bool showVegNonVegFilter) {
    final double safeArea = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 680;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isCompact = isSmallScreen || isLandscape;

    final double spacing12 = isCompact ? 4.0 : 8.0;
    final double spacing16 = isCompact ? 6.0 : 12.0;
    final double spacing10 = isCompact ? 4.0 : 8.0;
    final double cardPadding = isCompact ? 10.0 : 12.0;

    // Calculate required height for RestaurantDarkHeader (Simplified layout)
    double whiteCardHeight = cardPadding * 2; 
    whiteCardHeight += 28.0; // Name
    whiteCardHeight += 8.0;  // spacing
    whiteCardHeight += 26.0; // rating box
    whiteCardHeight += 8.0;  // spacing
    whiteCardHeight += 18.0; // category
    whiteCardHeight += 12.0; // spacing
    whiteCardHeight += 1.0;  // divider
    whiteCardHeight += 12.0; // spacing
    whiteCardHeight += 20.0; // outlet row
    whiteCardHeight += 8.0;  // spacing
    whiteCardHeight += 20.0; // address row

    if (!isDeliverable) {
      whiteCardHeight += isCompact ? 8.0 : 14.0; // spacing before red banner
      whiteCardHeight += 38.0; // red banner height (18 icon/text + 10 * 2 padding)
    }

    double totalHeaderHeight =
        safeArea +
        48.0 + // Back button & PopupMenuButton row height is 48.0
        spacing12 +
        whiteCardHeight +
        spacing10;

    // Add the bottom widget height (StickySearchBar [68.0] + FiltersList [50.0])
    final double bottomHeight = 122.0;
    final double expandedHeight = totalHeaderHeight + bottomHeight;

    if (isLandscape) {
      return expandedHeight.clamp(320.0, 440.0);
    }
    return expandedHeight.clamp(360.0, 560.0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RestaurantDetailsBloc, RestaurantDetailsState>(
      listener: (context, state) {
        if (state.vendorResponse != null) {
          _mapResponseToUI(state.vendorResponse!);
        }
      },
      child: BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
        builder: (context, state) {
          if (state.isVendorListLoading && _apiCategories.isEmpty) {
            return const RestaurantDetailsShimmer();
          }

          final vendor = (state.vendorResponse?.data != null && state.vendorResponse!.data!.isNotEmpty)
              ? state.vendorResponse!.data!.first
              : null;
          final details = state.vendorDetailsResponse?.data;

          final bool isDeliverable =
              details?.isDeliverable ??
              vendor?.isDeliverable ??
              widget.item?["isDeliverable"] ??
              widget.item?["isServiceable"] ??
              true;

          final Map<String, dynamic> mergedHeaderItem = {
            ...?widget.item,
            if (vendor != null) ...{
              "name": vendor.entityName,
              "image": vendor.entityImage,
              "isVeg": vendor.foodType?.toLowerCase() == 'veg',
              "isPopular": vendor.isPopular,
              "isServiceable": vendor.isServiceable,
              "foodType": vendor.foodType,
              "isDeliverable": vendor.isDeliverable,
              "distanceKm": vendor.distanceKm,
              "lat": vendor.lat,
              "lng": vendor.lng,
              "address": vendor.address,
              "area": vendor.area,
              "city": vendor.city,
              "avgRating": vendor.avgRating,
              "totalReviews": vendor.totalReviews,
            },
            if (details != null) ...{
              "id": details.id,
              "name": details.entityName,
              "image": details.entityImage,
              "entity_name": details.entityName,
              "entity_image": details.entityImage,
              "entity_contact": details.entityContact,
              "entity_category_name": details.entityCategoryName,
              "email": details.email,
              "city": details.city,
              "area": details.area,
              "address": details.address,
              "lat": details.lat,
              "lng": details.lng,
              "cuisines": details.cuisines,
              "delivery_packaging_type": details.deliveryPackagingType,
              "delivery_packaging_price": details.deliveryPackagingPrice,
              "is_serviceable": details.isServiceable,
              "isServiceable": details.isServiceable,
              "is_popular": details.isPopular,
              "food_type": details.foodType,
              "isDeliverable": details.isDeliverable,
              "distanceKm": details.distanceKm,
              "first_name": details.firstName,
              "middle_name": details.middleName,
              "last_name": details.lastName,
              "avgRating": details.avgRating,
              "totalReviews": details.totalReviews,
            },
            "isServiceable": isDeliverable,
            "isDeliverable": isDeliverable,
          };

          final String? foodType = vendor?.foodType ?? widget.item?["foodType"];
          final bool showVegNonVegFilter =
              foodType == null || foodType.toLowerCase() == 'both';

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverAppBar(
                            systemOverlayStyle: _isScrolledToTop
                                ? SystemUiOverlayStyle.dark.copyWith(
                                    statusBarColor: Colors.transparent,
                                  )
                                : SystemUiOverlayStyle.light.copyWith(
                                    statusBarColor: Colors.transparent,
                                  ),
                            backgroundColor: Colors.white,
                            expandedHeight: _calculateExpandedHeight(
                              context,
                              isDeliverable,
                              showVegNonVegFilter,
                            ),
                            floating: false,
                            pinned: true,
                            elevation: 0,
                            toolbarHeight: 0,
                            scrolledUnderElevation: 0,
                            automaticallyImplyLeading: true,
                            flexibleSpace: FlexibleSpaceBar(
                              background: RestaurantDarkHeader(
                                item: mergedHeaderItem,
                              ),
                            ),
                            bottom: PreferredSize(
                              preferredSize: Size.fromHeight(
                                122.0 + (_isScrolledToTop ? MediaQuery.of(context).padding.top : 0),
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: _isScrolledToTop
                                      ? Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        )
                                      : null,
                                  boxShadow: _isScrolledToTop
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: SafeArea(
                                  top: _isScrolledToTop,
                                  bottom: false,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                    StickySearchBar(
                                      isScrolledToTop: _isScrolledToTop,
                                      item: mergedHeaderItem,
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
                                    ),
                                    FiltersList(
                                      activeFilter: _activeFilter,
                                      showVegNonVegFilter: showVegNonVegFilter,
                                      activeSortBy: _activeSortBy,
                                      activeFoodType: _activeFoodType,
                                      sortOptions: state.filtersData?.sortOptions ?? [],
                                      foodTypes: state.filtersData?.foodTypes ?? [],
                                      onFilterChanged: (newFilter) {
                                        setState(() {
                                          _activeFilter = newFilter;
                                          if (newFilter == 'veg') {
                                            _activeFoodType = 'veg';
                                          } else if (newFilter == 'nonveg') {
                                            _activeFoodType = 'non-veg';
                                          } else {
                                            _activeFoodType = null;
                                          }
                                        });
                                        _refetchVendorList();
                                      },
                                      onSortChanged: (sortKey) {
                                        setState(() {
                                          _activeSortBy = sortKey;
                                        });
                                        _refetchVendorList();
                                      },
                                      onFoodTypeChanged: (foodTypeKey) {
                                        setState(() {
                                          _activeFoodType = foodTypeKey;
                                          if (foodTypeKey == 'veg') {
                                            _activeFilter = 'veg';
                                          } else if (foodTypeKey == 'non-veg' || foodTypeKey == 'nonveg') {
                                            _activeFilter = 'nonveg';
                                          } else {
                                            _activeFilter = 'all';
                                          }
                                        });
                                        _refetchVendorList();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: _buildMenuList(isDeliverable)),
                        ],
                      ),
                    ),
                    if (!isDeliverable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF3F3),
                          border: Border(
                            top: BorderSide(color: Color(0xFFFFBDBD), width: 1),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                color: Colors.red.shade400,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Delivery is not available in your area',
                                  style: TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned(
                  bottom: 30.h,
                  left: 0,
                  right: 0,
                  child: BlocBuilder<FoodCartBloc, CartState>(
                    builder: (context, cartState) {
                      if (cartState is CartLoaded &&
                          cartState.cartData.items != null &&
                          cartState.cartData.items!.isNotEmpty) {
                        final cart = cartState.cartData;
                        return Center(
                          child: GestureDetector(
                            onTap: () => context.push(AppRoutePath.cart, extra: true),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF5E2B), Color(0xFFFF9068)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(30.w),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5E2B).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'VIEW CART',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.sp,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 14.h,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${cart.grandTotal?.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().slideY(
                                begin: 1,
                                end: 0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutBack,
                              ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.black,
              onPressed: _showMenuBottomSheet,
              shape: const CircleBorder(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.menu_book, color: Colors.white, size: 20),
                  SizedBox(height: 2),
                  Text(
                    'MENU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuList(bool isDeliverable) {
    if (_apiCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 56,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Menu not available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This restaurant does not have any active menu items currently.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Filter categories dynamically based on active filter and search query
    final categoriesToRender = _apiCategories
        .map((cat) {
          final items = cat['items'] as List;
          final filteredItems = items.where((item) {
            // 1. Veg/NonVeg filter
            final isVeg = item['isVeg'] == true;
            if (_activeFilter == 'veg' && !isVeg) return false;
            if (_activeFilter == 'nonveg' && isVeg) return false;

            // 2. Search query filter
            if (_searchQuery.isNotEmpty) {
              final name = (item['name'] as String? ?? '').toLowerCase();
              if (!name.contains(_searchQuery.toLowerCase())) return false;
            }
            return true;
          }).toList();

          return {...cat, 'filteredItems': filteredItems};
        })
        .where((cat) => (cat['filteredItems'] as List).isNotEmpty)
        .toList();

    if (categoriesToRender.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No dishes found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We couldn't find any dishes matching '${_searchQuery}' or current filters.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Guard: ensure _categoryKeys always matches current categoriesToRender length
    if (_categoryKeys.length != categoriesToRender.length) {
      _categoryKeys = List.generate(
        categoriesToRender.length,
        (_) => GlobalKey(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...categoriesToRender.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final itemsToRender = category['filteredItems'] as List;

            return Container(
              key: _categoryKeys[index],
              child: CategoryAccordion(
                title: '${category['title']} (${itemsToRender.length})',
                subtitle: category['subtitle'],
                hasNewBadge: category['hasNewBadge'] ?? false,
                isExpanded: category['isExpanded'] ?? false,
                items: itemsToRender,
                onItemTap: _showItemDetailsBottomSheet,
                isDeliverable: isDeliverable,
                onTap: () {
                  setState(() {
                    for (var mainCat in _apiCategories) {
                      if (mainCat['title'] == category['title']) {
                        mainCat['isExpanded'] =
                            !(mainCat['isExpanded'] as bool);
                        break;
                      }
                    }
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
