import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_vegiz_flutter/features/grocery_subCtegory/bloc/homePage/homePage_bloc.dart';
import 'package:my_vegiz_flutter/features/grocery_subCtegory/bloc/homePage/homePage_event.dart';
import 'package:my_vegiz_flutter/features/grocery_subCtegory/bloc/homePage/homePage_state.dart';
import 'package:my_vegiz_flutter/features/mainCetegories/bloc/mainCategories_bloc.dart';
import 'package:my_vegiz_flutter/features/mainCetegories/bloc/mainCategories_event.dart';
import 'package:my_vegiz_flutter/features/mainCetegories/bloc/mainCategories_state.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/custom_bottom_nav_bar.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../mainCetegories/presentation/category_cards.dart';
import '../widgets/section1_mind.dart';
import '../widgets/section2_groceries.dart';
import '../../data/models/entity_category_model.dart';
import '../../data/models/grocery_category_model.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import '../../bloc/entity_category/entity_category_bloc.dart';
import '../../bloc/entity_category/entity_category_event.dart';
import '../../bloc/entity_category/entity_category_state.dart';
import '../../bloc/grocery_category/grocery_category_bloc.dart';
import '../../bloc/grocery_category/grocery_category_event.dart';
import '../../bloc/grocery_category/grocery_category_state.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/services/notification_service.dart';
import 'package:my_vegiz_flutter/core/api/api/api_helper.dart';
import 'package:my_vegiz_flutter/core/api/api/api_url.dart';
import 'package:my_vegiz_flutter/core/models/app_update_model.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/features/address/presentation/widgets/swiggy_location_sheet.dart';
import '../../../grocery_category/presentation/grocery_category_page.dart';
import '../../../food_category/presentation/food_category_page.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/food_cart_bloc.dart';

class HomePage extends StatefulWidget {
  final bool fromCart;
  final bool isFood;
  const HomePage({
    super.key,
    this.fromCart = false,
    this.isFood = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static bool _hasShownSwiggySheetThisLaunch = false;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  bool _isDialogOpen = false;
  double? _lastFetchedLat;
  double? _lastFetchedLng;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _updateFirebaseToken();
    _checkAppUpdate();

    _startLocationInitialization();
    _listenLocationService();
  }

  Future<void> _updateFirebaseToken() async {
    try {
      final token = await NoficationService.getToken();
      if (token != null && token.isNotEmpty) {
        await SecureStorage.saveFirebaseToken(token);
        await NoficationService.updateTokenOnServer();
      }
    } catch (e) {
      logger.e('Error updating Firebase token on HomePage init: $e');
    }
  }

  bool _isServerVersionHigher(String current, String server) {
    if (server.trim().isEmpty) return false;
    try {
      final cleanCurrent = current
          .split('+')
          .first
          .replaceAll(RegExp(r'[^0-9.]'), '')
          .split('.');
      final cleanServer = server
          .split('+')
          .first
          .replaceAll(RegExp(r'[^0-9.]'), '')
          .split('.');

      final maxLen = cleanCurrent.length > cleanServer.length
          ? cleanCurrent.length
          : cleanServer.length;

      for (int i = 0; i < maxLen; i++) {
        final currentPart =
            i < cleanCurrent.length ? int.tryParse(cleanCurrent[i]) ?? 0 : 0;
        final serverPart =
            i < cleanServer.length ? int.tryParse(cleanServer[i]) ?? 0 : 0;

        if (serverPart > currentPart) return true;
        if (serverPart < currentPart) return false;
      }
      return false;
    } catch (_) {
      return server.trim() != current.trim();
    }
  }

  Future<void> _checkAppUpdate() async {
    try {
      final apiHelper = getIt<ApiHelper>();
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.appVersion,
      );
      final appUpdateResponse = AppUpdateResponse.fromJson(response);

      if (appUpdateResponse.data == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      AppVersion? serverVersion;
      if (Platform.isAndroid) {
        serverVersion = appUpdateResponse.data!.androidAppVersion;
      } else if (Platform.isIOS) {
        serverVersion = appUpdateResponse.data!.iosAppVersion;
      }

      if (serverVersion != null &&
          serverVersion.version.isNotEmpty &&
          _isServerVersionHigher(currentVersion, serverVersion.version)) {
        if (mounted) {
          _showUpdateDialog(serverVersion);
        }
      }
    } catch (e) {
      logger.e('Error checking app update: $e');
    }
  }

  void _showUpdateDialog(AppVersion serverVersion) {
    showDialog(
      context: context,
      barrierDismissible: !serverVersion.forceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !serverVersion.forceUpdate,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 70.w,
                    width: 70.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC8019).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update,
                      color: const Color(0xFFFC8019),
                      size: 30.w,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  Text(
                    "Update Available",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  Text(
                    serverVersion.updateMessage.isNotEmpty
                        ? serverVersion.updateMessage
                        : "A new version of the app is available. Please update for a better experience.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      if (!serverVersion.forceUpdate)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),

                      if (!serverVersion.forceUpdate) SizedBox(width: 12.w),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (serverVersion.storeLink.isNotEmpty) {
                              final uri = Uri.tryParse(serverVersion.storeLink);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFC8019),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Update",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _fetchAllHomeData(double lat, double lng) {
    _lastFetchedLat = lat;
    _lastFetchedLng = lng;
    logger.i('🏠 HomePage: Fetching home data for lat=$lat, lng=$lng');
    final grocerySlug = _resolveGrocerySlug(context);
    context.read<HomePageBloc>().add(
      FetchHomePageData(
        mainCategorySlug: grocerySlug,
        lat: lat,
        lng: lng,
      ),
    );
  }

  Future<void> _initLocation() async {
    final bool isEnabled = await locationService.isServiceEnabled();

    if (!isEnabled) {
      if (mounted) _showEnableLocationDialog();
    } else {
      try {
        await locationService.requestPermissionAndFetchLocation(force: true);
        final loc = locationService.locationNotifier.value;
        if (loc != null) {
          _fetchAllHomeData(loc.lat, loc.lng);
        }
      } catch (e) {
        logger.e('📍 HomePage: Initial location fetch failed — $e');
      }
    }
  }

  Future<void> _startLocationInitialization() async {
    locationService.locationNotifier.removeListener(_onLocationChanged);
    locationService.locationNotifier.addListener(_onLocationChanged);

    // 1. Try to load saved location
    final savedLocation = await locationService.loadSavedLocation();
    if (savedLocation != null) {
      _fetchAllHomeData(savedLocation.lat, savedLocation.lng);

      // On app re-open, show the Swiggy-style confirmation sheet once
      if (!_hasShownSwiggySheetThisLaunch && mounted) {
        _hasShownSwiggySheetThisLaunch = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SwiggyLocationSheet.show(context);
          }
        });
      }
      return;
    }

    // 2. Check if in-memory location exists
    final inMemoryLoc = locationService.locationNotifier.value;
    if (inMemoryLoc != null) {
      _fetchAllHomeData(inMemoryLoc.lat, inMemoryLoc.lng);
      return;
    }

    // 3. First login / fresh launch: fetch device GPS location
    await _initLocation();
  }

  /// 🔥 NEW: Real-time listener
  void _listenLocationService() {
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) async {
      logger.i('📍 Service Status Changed: $status');

      if (status == ServiceStatus.enabled) {
        logger.i('📍 Location turned ON');

        // ✅ Auto close dialog immediately
        if (_isDialogOpen && mounted) {
          // Use rootNavigator: true to ensure we target the dialog
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
            _isDialogOpen = false;
          }
        }

        // Fetch location
        await locationService.requestPermissionAndFetchLocation();
      } else {
        logger.w('📍 Location turned OFF');

        // Show dialog only if not already open
        if (!_isDialogOpen && mounted) {
          _showEnableLocationDialog();
        }
      }
    });
  }

  void _showEnableLocationDialog() {
    if (_isDialogOpen) return; // 🔥 prevent duplicate dialogs

    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.w),
        ),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.deepOrange),
            SizedBox(width: 10.w),
            const Text('Location is Off'),
          ],
        ),
        content: const Text(
          'Your device location is disabled. Please enable it to help us find the best veggies near you!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              logger.i('📍 HomePage: Location prompt dismissed');
              Navigator.pop(context);
            },
            child: Text(
              'MAYBE LATER',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              logger.i('📍 HomePage: User clicked Enable Location');
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              // No need to call _initLocation() here; the stream listener
              // in _listenLocationService will handle the status change.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.w),
              ),
            ),
            child: const Text(
              'ENABLE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Safety reset
      _isDialogOpen = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _serviceStatusStream?.cancel();
    locationService.locationNotifier.removeListener(_onLocationChanged);
    super.dispose();
  }

  /// Returns the slug of the first non-food active category from the API.
  /// Falls back to 'grocery-vegetables' for backward compatibility.
  String _resolveGrocerySlug(BuildContext context) {
    final catState = context.read<MainCategoriesBloc>().state;
    if (catState is MainCategoriesLoaded) {
      final nonFood = (catState.data.data ?? [])
          .where((c) => c.isActive && c.slug != 'food')
          .toList();
      if (nonFood.isNotEmpty) return nonFood.first.slug;
    }
    return 'grocery-vegetables';
  }

  void _onLocationChanged() {
    if (!mounted) return;

    final loc = locationService.locationNotifier.value;
    if (loc != null) {
      if (_lastFetchedLat == loc.lat && _lastFetchedLng == loc.lng) {
        logger.d('🏠 HomePage: Location coordinates unchanged (${loc.lat}, ${loc.lng}), skipping duplicate fetch');
        return;
      }
      logger.i('🏠 HomePage: Location changed to ${loc.label} (${loc.lat}, ${loc.lng}) — reloading home data!');
      _fetchAllHomeData(loc.lat, loc.lng);
    }
  }

  Future<void> _onRefresh() async {
    // logger.i(
    //   '🔄 HomePage: Pull-to-refresh triggered — refreshing main categories',
    // );
    final loc = locationService.locationNotifier.value;
    final grocerySlug = _resolveGrocerySlug(context);
    context.read<HomePageBloc>().add(
      FetchHomePageData(
        mainCategorySlug: grocerySlug,
        lat: loc?.lat ?? 0.0,
        lng: loc?.lng ?? 0.0,
      ),
    );
    // Wait for the primary check (HomePageBloc)
    await context.read<HomePageBloc>().stream.firstWhere(
      (state) => state is! HomePageLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    // isFoodCart = false; // Removed to prevent resetting global cart mode on every build
    // logger.d('🏗️ HomePage: build() called');
    final homePageState = context.watch<HomePageBloc>().state;
    final categoriesState = context.watch<MainCategoriesBloc>().state;
    final isNotServiceable = homePageState is HomePageError &&
        homePageState.message.toLowerCase().contains('area is not serviceable');

    return BlocListener<HomePageBloc, HomePageState>(
      listener: (context, state) {
        if (state is HomePageLoaded) {
          // If area is serviceable, fetch the rest of the home data
          context.read<MainCategoriesBloc>().add(FetchMainCategories());
          context.read<EntityCategoryBloc>().add(const FetchEntityCategoriesEvent());
          context.read<GroceryCategoryBloc>().add(const FetchGroceryCategoriesEvent());

          // Fetch cart from server so bottom nav badge shows correct count
          final loc = locationService.locationNotifier.value;
          final lat = loc?.lat ?? 0.0;
          final lng = loc?.lng ?? 0.0;
          // Grocery cart
          getIt<CartBloc>().add(GetCartListEvent(lat: lat, lng: lng));
          // Food cart
          getIt<FoodCartBloc>().add(GetCartListEvent(lat: lat, lng: lng));
        }
      },
      child: isNotServiceable
          ? PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (widget.fromCart) {
                  context.go(AppRoutePath.cart, extra: widget.isFood);
                } else {
                  SystemNavigator.pop();
                }
              },
              child: const Scaffold(
                backgroundColor: Colors.white,
                appBar: CustomHomeAppBar(
                  showSearch: false,
                ),
                body: _NotServiceableBody(),
                bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
              ),
            )
          : Builder(
              builder: (context) {
                if (categoriesState is MainCategoriesLoading || categoriesState is MainCategoriesInitial) {
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
                    child: const Scaffold(
                      backgroundColor: Colors.white,
                      appBar: CustomHomeAppBar(
                        showSearch: false,
                      ),
                      body: _HomeShimmer(),
                      bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
                    ),
                  );
                }

                // If only vegetables/groceries exist (no food category active)
                if (categoriesState is MainCategoriesLoaded) {
                  final activeCategories = (categoriesState.data.data ?? [])
                      .where((c) => c.isActive)
                      .toList();
                  final hasFood = activeCategories.any((c) => c.slug == 'food');
                  final hasVegetables = activeCategories.any((c) => c.slug != 'food');

                  if (!hasFood && hasVegetables) {
                    final grocerySlug = _resolveGrocerySlug(context);
                    return GroceryCategoryPage(
                      isHomeTab: true,
                      mainCategorySlug: grocerySlug,
                      fromCart: widget.fromCart,
                      isFood: widget.isFood,
                    );
                  }

                  // If only food exists (no vegetable/grocery category active)
                  if (hasFood && !hasVegetables) {
                    return FoodCategoryPage(
                      isHomeTab: true,
                      fromCart: widget.fromCart,
                      isFood: widget.isFood,
                    );
                  }
                }

                // Default Home Layout (when food is present or both are present)
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
                  child: Scaffold(
                    backgroundColor: Colors.white,
                    appBar: const CustomHomeAppBar(
                      showSearch: false,
                    ),
                    body: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: _HomeBody(searchQuery: _searchQuery),
                      ),
                    ),
                    bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
                  ),
                );
              },
            ),
    );
  }
}

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Cards Shimmer (Vertical Stacked Cards matching CategoryCards)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  ShimmerPlaceholder.rounded(
                    height: 120.h,
                    borderRadius: 24.w,
                  ),
                  SizedBox(height: 16.h),
                  ShimmerPlaceholder.rounded(
                    height: 120.h,
                    borderRadius: 24.w,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Section 1: What's on your mind? Shimmer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder.rounded(height: 20.h, width: 220.w),
                  SizedBox(height: 8.h),
                  ShimmerPlaceholder.rounded(height: 14.h, width: 280.w),
                ],
              ),
            ),
            SizedBox(height: 16.h),
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
                        ShimmerPlaceholder.circular(
                          width: 72.w,
                          height: 72.w,
                        ),
                        SizedBox(height: 8.h),
                        ShimmerPlaceholder.rounded(height: 12.h, width: 55.w),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24.h),

            // Divider Shimmer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Divider(color: Colors.grey[100], thickness: 4),
            ),
            SizedBox(height: 24.h),

            // Section 2: Groceries Shimmer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerPlaceholder.rounded(height: 22.w, width: 22.w),
                      SizedBox(width: 8.w),
                      ShimmerPlaceholder.rounded(height: 15.h, width: 140.w),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  ShimmerPlaceholder.rounded(height: 20.h, width: 240.w),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 130.h,
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
                          height: 85.w,
                          width: 105.w,
                          borderRadius: 16.w,
                        ),
                        SizedBox(height: 8.h),
                        ShimmerPlaceholder.rounded(height: 12.h, width: 85.w),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms);
  }
}

/// Extracted widget so [flutter_animate] runs only once on mount,
/// not on every parent rebuild (e.g., location change, refresh).
class EmptySearchState extends StatelessWidget {
  final String query;
  const EmptySearchState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 60.h),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64.w,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            "No results found",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "We couldn't find anything matching '$query'.\nTry checking your spelling or using different keywords.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted widget so [flutter_animate] runs only once on mount,
/// not on every parent rebuild (e.g., location change, refresh).
class _HomeBody extends StatelessWidget {
  final String searchQuery;
  const _HomeBody({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final categoriesState = context.watch<MainCategoriesBloc>().state;
    final foodState = context.watch<EntityCategoryBloc>().state;
    final groceryState = context.watch<GroceryCategoryBloc>().state;

    if (searchQuery.isNotEmpty) {
      bool hasCategoryMatch = false;
      if (categoriesState is MainCategoriesLoaded) {
        hasCategoryMatch = (categoriesState.data.data ?? []).any(
          (c) => (c.mainCategoryName).toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        );
      }

      bool hasFoodMatch = false;
      if (foodState is EntityCategoryLoaded) {
        hasFoodMatch = foodState.categories.any(
          (cat) => (cat.entityCategory ?? '').toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        );
      }

      bool hasGroceryMatch = false;
      if (groceryState is GroceryCategoryLoaded) {
        hasGroceryMatch = groceryState.categories.any(
          (cat) => (cat.categoryName ?? '').toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        );
      }

      if (!hasCategoryMatch && !hasFoodMatch && !hasGroceryMatch) {
        return EmptySearchState(query: searchQuery);
      }
    }

    bool showFoodSection = true;
    if (categoriesState is MainCategoriesLoaded) {
      final hasFoodCategory = (categoriesState.data.data ?? []).any(
        (c) => c.slug == 'food' && c.isActive,
      );
      if (!hasFoodCategory) {
        showFoodSection = false;
      }
    }

    if (showFoodSection && foodState is EntityCategoryLoaded) {
      List<EntityCategoryModel> items = foodState.categories;
      if (searchQuery.isNotEmpty) {
        items = items
            .where((item) => (item.entityCategory ?? '').toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }
      showFoodSection = items.isNotEmpty;
    } else if (foodState is EntityCategoryError) {
      showFoodSection = false;
    }

    bool showGrocerySection = true;
    if (categoriesState is MainCategoriesLoaded) {
      final hasGroceryCategory = (categoriesState.data.data ?? []).any(
        (c) => c.slug != 'food' && c.isActive,
      );
      if (!hasGroceryCategory) {
        showGrocerySection = false;
      }
    }

    if (showGrocerySection && groceryState is GroceryCategoryLoaded) {
      List<GroceryCategoryModel> items = groceryState.categories;
      if (searchQuery.isNotEmpty) {
        items = items
            .where((item) => (item.categoryName ?? '').toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }
      showGrocerySection = items.isNotEmpty;
    } else if (groceryState is GroceryCategoryError) {
      showGrocerySection = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        // Category Cards
        CategoryCards(searchQuery: searchQuery),

        if (showFoodSection) ...[
          SizedBox(height: 22.h),
          Section1Mind(searchQuery: searchQuery),
          SizedBox(height: 6.h),
        ],

        // Horizontal Line Divider
        if (searchQuery.isEmpty && showFoodSection && showGrocerySection)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Divider(color: Colors.grey[200], thickness: 4),
          ),

        if (showGrocerySection) ...[
          if (searchQuery.isEmpty) SizedBox(height: 22.h),
          Section2Groceries(searchQuery: searchQuery),
          SizedBox(height: 22.h),
        ],
      ]
          .animate(interval: 50.ms)
          .fade(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
    );
  }
}

class _NotServiceableBody extends StatelessWidget {
  const _NotServiceableBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 60.h),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC8019).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  Icons.shopping_bag,
                  size: 100.w,
                  color: const Color(0xFFFC8019),
                ),
                Positioned(
                  top: 20.h,
                  right: 40.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: 24.w,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.h),
            Text(
              'Delivery not available here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Your selected address is outside our current delivery zones. Choose a different location to start shopping.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(AppRoutePath.selectLocation);
                },
                icon: Icon(Icons.location_on, color: Colors.white, size: 20.w),
                label: Text(
                  'Change Location',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B9B4B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.w),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}
