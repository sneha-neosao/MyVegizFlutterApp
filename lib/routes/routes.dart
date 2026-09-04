import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/features/address/data/models/address_model.dart';
import 'package:my_vegiz_flutter/features/auth/presentation/signup_screen.dart';
import 'package:my_vegiz_flutter/features/food_category/data/models/vendor_home_section_model.dart';
import 'package:my_vegiz_flutter/features/food_category/presentation/food_category_page.dart';
import 'package:my_vegiz_flutter/features/food_category/presentation/vender_entity_category_page.dart';
import 'package:my_vegiz_flutter/features/grocery_category/presentation/grocery_category_page.dart';
import 'package:my_vegiz_flutter/features/home/presentation/pages/home_page.dart';
import 'package:my_vegiz_flutter/features/slpash/presentation/page/splash_screen.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/search/bloc/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../features/food_category/bloc/vendor_banner/vendor_banner_bloc.dart';
import '../features/food_category/bloc/vendor_banner/vendor_banner_event.dart';
import '../features/food_category/bloc/vendor_entity_category/vendor_entity_category_bloc.dart';
import '../features/food_category/bloc/vendor_entity_category/vendor_entity_category_event.dart';
import '../features/home/bloc/entity_category/entity_category_bloc.dart';
import '../features/home/bloc/grocery_category/grocery_category_bloc.dart';
import '../features/food_category/bloc/vendor_home_section/vendor_home_section_bloc.dart';
import '../features/food_category/bloc/vendor_home_section/vendor_home_section_event.dart';
import '../features/food_category/presentation/recommended_foods_page.dart';
import '../features/restaurant_details/bloc/restaurant_details_bloc.dart';
import '../config/injector_conf.dart';
import '../features/auth/bloc/login_blocs/login_bloc/sendOtp_bloc.dart';
import '../features/auth/bloc/login_blocs/verifyOtp_bloc/verifyOtp_bloc.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/loginVerifyOtp_screen.dart';
import '../features/auth/presentation/regiVerify_otp.dart';
import '../features/auth/bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_bloc.dart';
import '../features/mainCetegories/bloc/mainCategories_bloc.dart';
import '../features/grocery_subCtegory/bloc/homePage/homePage_bloc.dart';
import '../features/grocery_subCtegory/bloc/homePage/homePage_event.dart';
import '../features/grocery_subCtegory/bloc/categoryProducts/category_products_bloc.dart';
import './app_route_path.dart';
import '../features/profile/presentation/page/profile_screen.dart';
import '../features/profile/presentation/page/cms_page_screen.dart';
import '../features/profile/bloc/cms_page/cms_page_bloc.dart';
import '../features/profile/bloc/profile_blocs/profile_bloc.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/cart/bloc/cart_bloc.dart';
import '../features/cart/bloc/food_cart_bloc.dart';
import '../features/address/presentation/pages/address_list_page.dart';
import '../features/address/presentation/pages/map_location_page.dart';
import '../features/address/presentation/pages/location_details_page.dart';
import '../features/address/presentation/pages/select_location_page.dart';
import '../features/restaurant_details/presentation/restaurant_details_page.dart';
import '../widgets/page_loading_wrapper.dart';
import '../features/auth/bloc/signup_blocs/signup_bloc/signup_bloc.dart';
import '../features/productDetails/presentation/product_details_page.dart';
import '../features/productDetails/bloc/product_details_bloc.dart';

import '../features/checkout/presentation/pages/success_page.dart';

import '../features/checkout/presentation/pages/order_tracking_page.dart';
import '../features/orders/presentation/pages/orders_list_page.dart';
import '../features/orders/presentation/pages/order_details_page.dart';
import '../features/orders/bloc/food_order_bloc.dart';
import '../features/wishlist/presentation/pages/wishlist_page.dart';
import '../features/profile/presentation/page/rating_screen.dart';
import '../features/orders/presentation/pages/order_history_page.dart';
import '../features/wallet/presentation/pages/wallet_page.dart';

import '../features/cart/data/cart_data.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String initialRoute = AppRoutePath.login;
  late final GoRouter router;

  AppRoutes() {
    router = _createRouter();
  }

  GoRouter _createRouter() => GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: AppRoutePath.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutePath.home,
        builder: (context, state) {
          final fromCartStr = state.uri.queryParameters['fromCart'];
          final fromCart = fromCartStr == 'true';
          final isFoodStr = state.uri.queryParameters['isFood'];
          final isFood = isFoodStr == 'true';

          return MultiBlocProvider(
            providers: [
              // ⚠️ Do NOT add events here — home_page.dart handles the initial fetch
              // to prevent duplicate API calls.
              BlocProvider(
                create: (_) => getIt<MainCategoriesBloc>(),
              ),
              BlocProvider(
                create: (_) => getIt<EntityCategoryBloc>(),
              ),
              BlocProvider(
                create: (_) => getIt<GroceryCategoryBloc>(),
              ),
              BlocProvider<HomePageBloc>.value(
                value: getIt<HomePageBloc>(),
              ),
              BlocProvider<CategoryProductsBloc>(
                create: (_) => getIt<CategoryProductsBloc>(),
              ),
              BlocProvider(
                create: (_) => getIt<VendorBannerBloc>(),
              ),
              BlocProvider(
                create: (_) => getIt<VendorEntityCategoryBloc>(),
              ),
              BlocProvider(
                create: (_) => getIt<VendorHomeSectionBloc>(),
              ),
              BlocProvider(
                create: (_) => getIt<ProfileBloc>(),
              ),
            ],
            child: HomePage(fromCart: fromCart, isFood: isFood),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.search,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SearchBloc>(),
          child: const SearchPage(),
        ),
      ),
      GoRoute(
        path: AppRoutePath.restaurantDetails,
        builder: (context, state) {
          final item = state.extra as Map<String, dynamic>?;
          return _safe(
            BlocProvider(
              create: (_) => getIt<RestaurantDetailsBloc>(),
              child: RestaurantDetailsPage(item: item),
            ),
            backgroundColor: Colors.white,
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.login,
        builder: (context, state) => _safe(
          BlocProvider(
            create: (_) => getIt<SendOtpBloc>(),
            child: const LoginScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutePath.regiVerifyOtp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _safe(
            MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => getIt<RegiVerifyOtpBloc>(),
                ),
                BlocProvider(
                  create: (_) => getIt<RegisterBloc>(),
                ),
              ],
              child: RegiverifyOtp(
                name: extra['name'] as String? ?? '',
                email: extra['email'] as String? ?? '',
                mobile: extra['mobile'] as String? ?? '',
                verificationId: extra['verificationId'] as String?,
                resendToken: extra['resendToken'] as int?,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.signup,
        builder: (context, state) {
          String? initialMobile;
          bool isMobileReadOnly = false;

          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            initialMobile = map['mobile'] as String?;
            isMobileReadOnly = map['isReadOnly'] as bool? ??
                (initialMobile != null && initialMobile.isNotEmpty);
          } else if (state.extra is String) {
            initialMobile = state.extra as String;
            isMobileReadOnly = true;
          }

          return _safe(
            BlocProvider(
              create: (_) => getIt<RegisterBloc>(),
              child: SignupScreen(
                initialMobile: initialMobile,
                isMobileReadOnly: isMobileReadOnly,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.otp,
        builder: (context, state) {
          String mobile = '';
          String? verificationId;
          int? resendToken;

          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            mobile = map['mobile'] as String? ?? '';
            verificationId = map['verificationId'] as String?;
            resendToken = map['resendToken'] as int?;
          } else if (state.extra is String) {
            mobile = state.extra as String;
          }

          return _safe(
            MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => getIt<VerifyOtpBloc>(),
                ),
                BlocProvider(
                  create: (_) => getIt<SendOtpBloc>(),
                ),
              ],
              child: LoginVerifyOtpScreen(
                mobile: mobile,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.profile,
        builder: (context, state) =>
            const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutePath.cart,
        builder: (context, state) {
          final isFood = state.extra as bool? ?? isFoodCart;
          if (isFood) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<CartBloc>.value(value: getIt<FoodCartBloc>()),
                BlocProvider<FoodOrderBloc>(
                  create: (_) => getIt<FoodOrderBloc>(),
                ),
              ],
              child: CartPage(isFood: true),
            );
          }
          return BlocProvider<CartBloc>.value(
            value: getIt<CartBloc>(),
            child: CartPage(isFood: false),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.foodCategory,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: _safe(
              MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) {
                      final loc = locationService.locationNotifier.value;
                      return getIt<VendorBannerBloc>()..add(
                        FetchVendorBannersEvent(
                          lat: loc?.lat ?? 0.0,
                          lng: loc?.lng ?? 0.0,
                        ),
                      );
                    },
                  ),
                  BlocProvider(
                    create: (_) =>
                        getIt<VendorEntityCategoryBloc>()
                          ..add(FetchVendorEntityCategoriesEvent()),
                  ),
                  BlocProvider(
                    create: (_) {
                      final loc = locationService.locationNotifier.value;
                      return getIt<VendorHomeSectionBloc>()
                        ..add(const FetchVendorHomeSectionFiltersEvent())
                        ..add(
                          FetchVendorHomeSectionsEvent(
                            lat: loc?.lat ?? 0.0,
                            lng: loc?.lng ?? 0.0,
                          ),
                        );
                    },
                  ),
                ],
                child: const FoodCategoryPage(),
              ),
              backgroundColor: Colors.white,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.entityCategoryVendors,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final uuid = extra['uuid'] as String? ?? '';
          final title = extra['title'] as String? ?? 'Outlets';
          return _safe(
            BlocProvider(
              create: (_) => getIt<VendorEntityCategoryBloc>(),
              child: VenderEntityCategoryPage(
                initialCategoryUuid: uuid,
                categoryName: title,
              ),
            ),
            backgroundColor: Colors.white,
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.recommendedFoodsList,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final items = extra['items'] as List<HomeSectionVendorItem>? ?? [];
          final title = extra['title'] as String? ?? 'Recommended Foods';
          return _safe(
            RecommendedFoodsPage(items: items, title: title),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.groceryCategory,
        pageBuilder: (context, state) {
          String mainCategorySlug = 'grocery-vegetables';
          String? initialTabSlug;
          String? initialCategorySlug;

          if (state.extra is String) {
            mainCategorySlug = state.extra as String;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            mainCategorySlug =
                map['mainCategorySlug'] as String? ?? 'grocery-vegetables';
            initialTabSlug = map['initialTabSlug'] as String?;
            initialCategorySlug = map['initialCategorySlug'] as String?;
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: _safe(
              MultiBlocProvider(
                providers: [
                  BlocProvider<HomePageBloc>.value(
                    value: getIt<HomePageBloc>()
                      ..add(
                        FetchHomePageData(
                          mainCategorySlug: mainCategorySlug,
                          homeTabSlug: initialTabSlug,
                          lat: (locationService.locationNotifier.value)?.lat ?? 0.0,
                          lng: (locationService.locationNotifier.value)?.lng ?? 0.0,
                        ),
                      ),
                  ),
                  BlocProvider<CategoryProductsBloc>(
                    create: (context) => getIt<CategoryProductsBloc>(),
                  ),
                ],
                child: GroceryCategoryPage(
                  initialTabSlug: initialTabSlug,
                  initialCategorySlug: initialCategorySlug,
                ),
              ),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 400),
          );
        },
      ),
      // GoRoute(
      //   path: AppRoutePath.hotDeals,
      //   builder: (context, state) =>
      //       const PageLoadingWrapper(child: HotDealsPage()),
      // ),
      GoRoute(
        path: AppRoutePath.address,
        builder: (context, state) => _safe(
          const AddressListPage(),
          backgroundColor: Colors.white,
        ),
      ),
      GoRoute(
        path: AppRoutePath.selectLocation,
        builder: (context, state) => _safe(
          const SelectLocationPage(),
          backgroundColor: Colors.white,
        ),
      ),
      GoRoute(
        path: AppRoutePath.mapLocation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fromHome = extra?['fromHome'] as bool? ?? false;
          final fetchCurrentLocation =
              extra?['fetchCurrentLocation'] as bool? ?? false;
          final existingAddress = extra?['existingAddress'] as AddressModel?;
          return _safe(
            MapLocationPage(
              fromHome: fromHome,
              fetchCurrentLocation: fetchCurrentLocation,
              existingAddress: existingAddress,
            ),
            backgroundColor: Colors.white,
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.locationDetails,
        builder: (context, state) {
          final address = state.extra as AddressModel?;
          return _safe(
            PageLoadingWrapper(
              child: LocationDetailsPage(address: address),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.productDetails,
        pageBuilder: (context, state) {
          String slug = "";
          int? variantId;
          List<dynamic>? productsList;
          int initialIndex = 0;

          if (state.extra is String) {
            slug = state.extra as String;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            slug = map['slug'] as String? ?? "";
            variantId = map['variantId'] as int?;
            productsList = map['products'] as List<dynamic>?;
            initialIndex = map['initialIndex'] as int? ?? 0;
          }

          return CustomTransitionPage(
            key: state.pageKey,
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.black.withValues(alpha: 0.75),
            child: _safe(
              BlocProvider(
                create: (context) => getIt<ProductDetailsBloc>(),
                child: ProductDetailsPage(
                  slug: slug,
                  initialVariantId: variantId,
                  productsList: productsList,
                  initialIndex: initialIndex,
                ),
              ),
              backgroundColor: Colors.transparent,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.success,
        builder: (context, state) {
          final isFoodOrder = state.extra as bool? ?? false;
          return _safe(
            SuccessPage(isFoodOrder: isFoodOrder),
            backgroundColor: Colors.white,
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.orderTracking,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _safe(
            PageLoadingWrapper(
              child: OrderTrackingPage(
                storeLocation: LatLng(
                  extra['storeLat'] as double? ?? 0.0,
                  extra['storeLng'] as double? ?? 0.0,
                ),
                deliveryLocation: LatLng(
                  extra['deliveryLat'] as double? ?? 0.0,
                  extra['deliveryLng'] as double? ?? 0.0,
                ),
                storeName: extra['storeName'] as String? ?? 'Store',
                deliveryName: extra['deliveryName'] as String? ?? 'Delivery',
                orderId: extra['orderId'] as String? ?? '',
                isFood: extra['isFood'] as bool? ?? true,
              ),
            ),
            backgroundColor: Colors.white,
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.ordersList,
        builder: (context, state) => _safe(
          const OrdersListPage(),
        ),
      ),
      GoRoute(
        path: AppRoutePath.orderDetails,
        builder: (context, state) {
          final extra = state.extra;
          final String orderId;
          final bool isFood;
          if (extra is Map<String, dynamic>) {
            orderId = extra['orderId'] as String? ?? '';
            isFood = extra['isFood'] as bool? ?? false;
          } else {
            orderId = extra as String? ?? '';
            isFood = false;
          }
          return _safe(
            OrderDetailsPage(orderId: orderId, isFood: isFood),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.wishlist,
        builder: (context, state) => _safe(
          const WishlistPage(),
        ),
      ),
      GoRoute(
        path: AppRoutePath.ratingScreen,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['orderId'] as String? ?? '';
          final isFood = extra?['isFood'] as bool? ?? false;
          return _safe(
            PageLoadingWrapper(
              child: RatingScreen(orderId: orderId, isFood: isFood),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutePath.orderHistory,
        builder: (context, state) => _safe(
          const PageLoadingWrapper(child: OrderHistoryPage()),
        ),
      ),
      GoRoute(
        path: AppRoutePath.wallet,
        builder: (context, state) => _safe(
          const WalletPage(),
          backgroundColor: Colors.white,
        ),
      ),
      GoRoute(
        path: AppRoutePath.privacyAndSecurity,
        builder: (context, state) => _safe(
          BlocProvider(
            create: (context) => getIt<CmsPageBloc>(),
            child: const CmsPageScreen(pageKey: 'privacy'),
          ),
          backgroundColor: Colors.white,
        ),
      ),
      GoRoute(
        path: AppRoutePath.refundPolicy,
        builder: (context, state) => _safe(
          BlocProvider(
            create: (context) => getIt<CmsPageBloc>(),
            child: const CmsPageScreen(pageKey: 'refund'),
          ),
          backgroundColor: Colors.white,
        ),
      ),
      GoRoute(
        path: AppRoutePath.termsAndConditions,
        builder: (context, state) => _safe(
          BlocProvider(
            create: (context) => getIt<CmsPageBloc>(),
            child: const CmsPageScreen(
              pageKey: 'terms',
            ),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    ],
  );

  Widget _safe(Widget child, {Color? backgroundColor}) {
    return Builder(
      builder: (context) {
        return Container(
          color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            top: false,
            bottom: true,
            child: child,
          ),
        );
      },
    );
  }
}
