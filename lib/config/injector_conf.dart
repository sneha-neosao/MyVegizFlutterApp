import 'package:my_vegiz_flutter/features/productDetails/data/datasources/productDetails_datasource.dart';
import 'package:my_vegiz_flutter/features/productDetails/data/repository/productDetails_repo.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../core/api/api/api_helper.dart';
import '../core/services/firebase_auth_service.dart';
import '../features/auth/bloc/login_blocs/login_bloc/sendOtp_bloc.dart';
import '../features/auth/bloc/login_blocs/verifyOtp_bloc/verifyOtp_bloc.dart';
import '../features/auth/bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_bloc.dart';
import '../features/auth/bloc/signup_blocs/signup_bloc/signup_bloc.dart';
import '../features/auth/domain/usecase/regiVerifyOtp_usecase.dart';
import '../features/auth/domain/usecase/register_usecase.dart';
import '../features/auth/domain/usecase/sendOtp_usecase.dart';
import '../features/auth/domain/usecase/verifyOtp_usecase.dart';
import '../features/auth/data/datasources/regiVerifyOtp_datasource.dart';
import '../features/auth/data/datasources/register_datasource.dart';
import '../features/auth/data/datasources/sendOtp_datasource.dart';
import '../features/auth/data/datasources/verifyOtp_datasource.dart';
import '../features/auth/data/repository/regiVerifyOtp_repo.dart';
import '../features/grocery_subCtegory/bloc/homePage/homePage_bloc.dart';
import '../features/grocery_subCtegory/usecases/homePage_usecase.dart';
import '../features/grocery_subCtegory/usecases/get_home_tab_sub_categories_usecase.dart';
import '../features/search/data/datasources/search_remote_datasource.dart';
import '../features/search/data/repository/search_repository.dart';
import '../features/search/domain/usecases/search_products_usecase.dart';
import '../features/search/bloc/search_bloc.dart';
import '../features/food_category/bloc/vendor_banner/vendor_banner_bloc.dart';
import '../features/food_category/data/datasources/vendor_banner_remote_datasource.dart';
import '../features/restaurant_details/data/datasources/restaurant_details_remote_datasource.dart';
import '../features/restaurant_details/data/repository/restaurant_details_repository.dart';
import '../features/restaurant_details/bloc/restaurant_details_bloc.dart';
import '../features/food_category/data/repository/vendor_banner_repository.dart';
import '../features/food_category/bloc/vendor_entity_category/vendor_entity_category_bloc.dart';
import '../features/food_category/data/datasources/vendor_entity_category_remote_datasource.dart';
import '../features/food_category/data/repository/vendor_entity_category_repository.dart';
import '../features/food_category/data/domain/usecase/get_vendor_banners_usecase.dart';
import '../features/food_category/data/domain/usecase/get_vendor_entity_categories_usecase.dart';
import '../features/food_category/data/domain/usecase/get_vendor_entity_category_filters_usecase.dart';
import '../features/food_category/bloc/vendor_home_section/vendor_home_section_bloc.dart';
import '../features/food_category/data/datasources/vendor_home_section_remote_datasource.dart';
import '../features/food_category/data/repository/vendor_home_section_repository.dart';
import '../features/food_category/data/domain/usecase/get_vendor_home_sections_usecase.dart';
import '../features/food_category/data/domain/usecase/get_vendor_home_section_filters_usecase.dart';
import '../features/grocery_subCtegory/data/datasources/homePage_datasource.dart';
import '../features/grocery_subCtegory/data/repository/homePage_repo.dart';
import '../features/auth/data/repository/register_repo.dart';
import '../features/auth/data/repository/sendOtp_repo.dart';
import '../features/auth/data/repository/verifyOtp_repo.dart';
import '../routes/routes.dart';
import '../features/mainCetegories/domain/usecase/mainCategories_usecase.dart';
import '../features/mainCetegories/bloc/mainCategories_bloc.dart';
import '../features/mainCetegories/data/datasources/mainCategories_datasource.dart';
import '../features/mainCetegories/data/repository/mainCategories_repo.dart';
import '../features/productDetails/bloc/product_details_bloc.dart';
import '../features/productDetails/domain/usecase/product_details_usecase.dart';

import '../features/home/data/datasources/entity_category_remote_datasource.dart';
import '../features/home/data/repository/entity_category_repository.dart';
import '../features/home/domain/usecase/get_entity_categories_usecase.dart';
import '../features/home/bloc/entity_category/entity_category_bloc.dart';

import '../features/home/data/datasources/grocery_category_remote_datasource.dart';
import '../features/home/data/repository/grocery_category_repository.dart';
import '../features/home/domain/usecase/get_grocery_categories_usecase.dart';
import '../features/home/bloc/grocery_category/grocery_category_bloc.dart';

import '../features/grocery_subCtegory/data/datasources/category_products_remote_datasource.dart';
import '../features/grocery_subCtegory/data/repository/category_products_repository.dart';
import '../features/grocery_subCtegory/usecases/get_category_products_usecase.dart';
import '../features/grocery_subCtegory/usecases/get_category_filters_usecase.dart';
import '../features/grocery_subCtegory/bloc/categoryProducts/category_products_bloc.dart';

import '../features/address/bloc/address_bloc.dart';
import '../features/address/bloc/places_bloc.dart';
import '../features/address/data/datasources/address_remote_datasource.dart';
import '../features/address/data/datasources/places_remote_datasource.dart';
import '../features/address/data/repository/address_repository.dart';
import '../features/address/data/repository/places_repository.dart';
import '../features/address/domain/usecase/address_usecases.dart';
import '../features/address/domain/usecase/places_usecases.dart';
import '../features/cart/bloc/cart_bloc.dart';
import '../features/cart/bloc/food_cart_bloc.dart';
import '../features/cart/domain/usecase/cart_usecases.dart';
import '../features/cart/data/datasources/cart_datasource.dart';
import '../features/cart/data/repository/cart_repo.dart';
import '../features/checkout/bloc/checkout_bloc.dart';
import '../features/checkout/data/datasources/checkout_datasource.dart';
import '../features/checkout/data/repository/checkout_repo.dart';
import '../features/orders/bloc/order_bloc.dart';
import '../features/orders/data/datasources/order_datasource.dart';
import '../features/orders/data/repository/grocery_order_repo.dart';
import '../features/orders/data/datasources/food_order_datasource.dart';
import '../features/orders/data/repository/food_order_repo.dart';
import '../features/orders/domain/usecase/food_order_usecases.dart';
import '../features/orders/bloc/food_order_bloc.dart';
import '../features/orders/domain/usecase/food_rating_usecases.dart';
import '../features/orders/bloc/food_rating_bloc.dart';
import '../features/wishlist/bloc/wishlist_bloc.dart';
import '../features/wishlist/data/datasources/wishlist_datasource.dart';
import '../features/wishlist/data/repository/wishlist_repo.dart';
import '../features/profile/bloc/profile_blocs/profile_bloc.dart';
import '../features/profile/domain/usecase/profile_usecases.dart';
import '../features/profile/data/datasources/profile_datasource.dart';
import '../features/profile/data/repository/profile_repository.dart';

import '../features/profile/data/datasources/cms_remote_datasource.dart';
import '../features/profile/data/repository/cms_repository.dart';
import '../features/profile/domain/usecase/get_cms_page_usecase.dart';
import '../features/profile/bloc/cms_page/cms_page_bloc.dart';
import '../core/connectivity/connectivity_bloc.dart';
import '../features/wallet/bloc/wallet_bloc.dart';
import '../features/wallet/data/datasources/wallet_datasource.dart';
import '../features/wallet/data/repository/wallet_repo.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  /// CORE
  getIt.registerLazySingleton<Dio>(() => Dio());

  getIt.registerLazySingleton<AppRoutes>(() => AppRoutes());

  getIt.registerLazySingleton<ApiHelper>(() => ApiHelper(getIt<Dio>()));

  getIt.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());

  /// DATASOURCE
  getIt.registerLazySingleton<SendOtpRemoteDataSource>(
    () => SendOtpRemoteDataSource(getIt<ApiHelper>()),
  );

  /// REPOSITORY
  getIt.registerLazySingleton<SendOtpRepository>(
    () => SendOtpRepositoryImpl(getIt<SendOtpRemoteDataSource>()),
  );

  /// USECASE
  getIt.registerLazySingleton<SendOtpUseCase>(
    () => SendOtpUseCase(getIt<SendOtpRepository>()),
  );

  /// BLOC
  getIt.registerFactory<SendOtpBloc>(
    () => SendOtpBloc(getIt<SendOtpUseCase>(), getIt<FirebaseAuthService>()),
  );
  // ----------------------------------------
  ///verify_otp
  getIt.registerLazySingleton<VerifyOtpRemoteDataSource>(
    () => VerifyOtpRemoteDataSource(getIt()),
  );

  getIt.registerLazySingleton<VerifyOtpRepository>(
    () => VerifyOtpRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => VerifyOtpUseCase(getIt()));

  getIt.registerFactory(
    () => VerifyOtpBloc(getIt(), getIt<FirebaseAuthService>()),
  );
  //---------------------------------------
  /// register (sign up)
  getIt.registerLazySingleton<RegisterRemoteDataSource>(
    () => RegisterRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<RegisterRepository>(
    () => RegisterRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));

  getIt.registerFactory(
    () => RegisterBloc(getIt(), getIt<FirebaseAuthService>()),
  );
  //---------------------------------------
  /// regi Verify Otp
  getIt.registerLazySingleton<RegiVerifyOtpDataSource>(
    () => RegiVerifyOtpDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<RegiVerifyOtpRepository>(
    () => RegiVerifyOtpRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => RegiVerifyOtpUseCase(getIt()));

  getIt.registerFactory(
    () => RegiVerifyOtpBloc(getIt(), getIt<FirebaseAuthService>()),
  );

  /// Main Categories
  getIt.registerLazySingleton<MainCategoriesRemoteDataSource>(
    () => MainCategoriesRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<MainCategoriesRepository>(
    () => MainCategoriesRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => MainCategoriesUseCase(getIt()));

  getIt.registerFactory(() => MainCategoriesBloc(getIt()));

  /// Home Page
  getIt.registerLazySingleton<HomePageRemoteDataSource>(
    () => HomePageRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<HomePageRepository>(
    () => HomePageRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => HomePageUseCase(getIt()));
  getIt.registerLazySingleton(() => GetHomeTabSubCategoriesUseCase(getIt()));

  getIt.registerLazySingleton(() => HomePageBloc(getIt()));

  /// Category Products & Filters
  getIt.registerLazySingleton<CategoryProductsRemoteDataSource>(
    () => CategoryProductsRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<CategoryProductsRepository>(
    () => CategoryProductsRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => GetCategoryProductsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCategoryFiltersUseCase(getIt()));

  getIt.registerFactory(
    () => CategoryProductsBloc(
      getCategoryProductsUseCase: getIt(),
      getCategoryFiltersUseCase: getIt(),
      getHomeTabSubCategoriesUseCase: getIt(),
    ),
  );

  /// Search Products
  getIt.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => SearchProductsUseCase(getIt()));

  getIt.registerFactory(() => SearchBloc(searchProductsUseCase: getIt()));

  /// Entity Categories (for Section1Mind)
  getIt.registerLazySingleton<EntityCategoryRemoteDataSource>(
    () => EntityCategoryRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<EntityCategoryRepository>(
    () => EntityCategoryRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => GetEntityCategoriesUseCase(getIt()));

  getIt.registerFactory(() => EntityCategoryBloc(getEntityCategoriesUseCase: getIt()));

  /// Grocery Categories (for Section2Groceries)
  getIt.registerLazySingleton<GroceryCategoryRemoteDataSource>(
    () => GroceryCategoryRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<GroceryCategoryRepository>(
    () => GroceryCategoryRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => GetGroceryCategoriesUseCase(getIt()));

  getIt.registerFactory(() => GroceryCategoryBloc(getGroceryCategoriesUseCase: getIt()));

  /// Vendor Banners / Details (Food Category)
  getIt.registerLazySingleton<VendorBannerRemoteDataSource>(
    () => VendorBannerRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<VendorBannerRepository>(
    () => VendorBannerRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => GetVendorBannersUseCase(getIt()));

  getIt.registerFactory(
    () => VendorBannerBloc(getVendorBannersUseCase: getIt()),
  );

  // Vendor Entity Category Dependency Injection
  getIt.registerLazySingleton<VendorEntityCategoryRemoteDataSource>(
    () => VendorEntityCategoryRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<VendorEntityCategoryRepository>(
    () => VendorEntityCategoryRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => GetVendorEntityCategoriesUseCase(getIt()));
  getIt.registerLazySingleton(() => GetVendorEntityCategoryFiltersUseCase(getIt()));

  getIt.registerFactory(
    () => VendorEntityCategoryBloc(
      getVendorEntityCategoriesUseCase: getIt(),
      getVendorEntityCategoryFiltersUseCase: getIt(),
    ),
  );

  // Vendor Home Section Dependency Injection
  getIt.registerLazySingleton<VendorHomeSectionRemoteDataSource>(
    () => VendorHomeSectionRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<VendorHomeSectionRepository>(
    () => VendorHomeSectionRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => GetVendorHomeSectionsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetVendorHomeSectionFiltersUseCase(getIt()));

  getIt.registerFactory(
    () => VendorHomeSectionBloc(
      getVendorHomeSectionsUseCase: getIt(),
      getVendorHomeSectionFiltersUseCase: getIt(),
    ),
  );

  /// Restaurant Details
  getIt.registerLazySingleton<RestaurantDetailsRemoteDataSource>(
    () => RestaurantDetailsRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<RestaurantDetailsRepository>(
    () => RestaurantDetailsRepositoryImpl(getIt()),
  );

  getIt.registerFactory(() => RestaurantDetailsBloc(repository: getIt()));

  /// Product Details
  getIt.registerLazySingleton<ProductDetailsRemoteDataSource>(
    () => ProductDetailsRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<ProductDetailsRepository>(
    () => ProductDetailsRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => ProductDetailsUseCase(getIt()));

  getIt.registerFactory(() => ProductDetailsBloc(getIt()));

  /// Address
  getIt.registerLazySingleton<AddressRemoteDataSource>(
    () => AddressRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => GetAddressListUseCase(getIt()));
  getIt.registerLazySingleton(() => AddAddressUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateAddressUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteAddressUseCase(getIt()));

  getIt.registerLazySingleton(
    () => AddressBloc(
      getAddressListUseCase: getIt(),
      addAddressUseCase: getIt(),
      updateAddressUseCase: getIt(),
      deleteAddressUseCase: getIt(),
    ),
  );

  /// Places (Google Places API)
  getIt.registerLazySingleton<PlacesRemoteDataSource>(
    () => PlacesRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<PlacesRepository>(
    () => PlacesRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => SearchPlacesUseCase(getIt()));
  getIt.registerLazySingleton(() => GetPlaceDetailsUseCase(getIt()));

  getIt.registerFactory(
    () => PlacesBloc(
      searchPlacesUseCase: getIt(),
      getPlaceDetailsUseCase: getIt(),
    ),
  );

  /// Cart
  getIt.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => AddToCartUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCartListUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateCartUseCase(getIt()));
  getIt.registerLazySingleton(() => ClearCartUseCase(getIt()));
  getIt.registerLazySingleton(() => ValidateAddressUseCase(getIt()));
  getIt.registerLazySingleton(() => RemoveCartItemUseCase(getIt()));
  getIt.registerLazySingleton(() => GetAvailableCouponsUseCase(getIt()));
  getIt.registerLazySingleton(() => ApplyCouponUseCase(getIt()));
  getIt.registerLazySingleton(() => RemoveCouponUseCase(getIt()));
  getIt.registerLazySingleton(() => ValidateCouponUseCase(getIt()));

  getIt.registerLazySingleton(
    () => CartBloc(
      addToCartUseCase: getIt(),
      getCartListUseCase: getIt(),
      updateCartUseCase: getIt(),
      clearCartUseCase: getIt(),
      validateAddressUseCase: getIt(),
      removeCartItemUseCase: getIt(),
      getAvailableCouponsUseCase: getIt(),
      applyCouponUseCase: getIt(),
      removeCouponUseCase: getIt(),
      validateCouponUseCase: getIt(),
    ),
  );

  getIt.registerLazySingleton(
    () => FoodCartBloc(
      addToCartUseCase: getIt(),
      getCartListUseCase: getIt(),
      updateCartUseCase: getIt(),
      clearCartUseCase: getIt(),
      validateAddressUseCase: getIt(),
      removeCartItemUseCase: getIt(),
      getAvailableCouponsUseCase: getIt(),
      applyCouponUseCase: getIt(),
      removeCouponUseCase: getIt(),
      validateCouponUseCase: getIt(),
    ),
  );

  /// Checkout
  getIt.registerLazySingleton<CheckoutRemoteDataSource>(
    () => CheckoutRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(getIt()),
  );

  getIt.registerFactory(() => CheckoutBloc(repository: getIt()));

  /// Orders
  getIt.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<GroceryOrderRepository>(
    () => GroceryOrderRepositoryImpl(getIt()),
  );

  getIt.registerFactory(() => GroceryOrderBloc(repository: getIt()));

  /// Food Orders
  getIt.registerLazySingleton<FoodOrderRemoteDataSource>(
    () => FoodOrderRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<FoodOrderRepository>(
    () => FoodOrderRepositoryImpl(getIt<FoodOrderRemoteDataSource>()),
  );

  getIt.registerLazySingleton(
    () => GetFoodOrdersListUseCase(getIt<FoodOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetFoodOrderDetailsUseCase(getIt<FoodOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => PlaceFoodOrderUseCase(getIt<FoodOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => CancelFoodOrderUseCase(getIt<FoodOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAvailableFoodCouponsUseCase(getIt<FoodOrderRepository>()),
  );

  getIt.registerFactory(
    () => FoodOrderBloc(
      getOrdersListUseCase: getIt<GetFoodOrdersListUseCase>(),
      getOrderDetailsUseCase: getIt<GetFoodOrderDetailsUseCase>(),
      placeOrderUseCase: getIt<PlaceFoodOrderUseCase>(),
      cancelOrderUseCase: getIt<CancelFoodOrderUseCase>(),
    ),
  );

  // Food Rating UseCases
  getIt.registerLazySingleton(
    () => SubmitFoodVendorRatingUseCase(getIt<FoodOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => SubmitFoodItemRatingsUseCase(getIt<FoodOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => SubmitFoodDeliveryRatingUseCase(getIt<FoodOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => FetchFoodOrderRatingsUseCase(getIt<FoodOrderRepository>()),
  );

  // Food Rating Bloc
  getIt.registerFactory(
    () => FoodRatingBloc(
      submitVendorRatingUseCase: getIt<SubmitFoodVendorRatingUseCase>(),
      submitItemRatingsUseCase: getIt<SubmitFoodItemRatingsUseCase>(),
      submitDeliveryRatingUseCase: getIt<SubmitFoodDeliveryRatingUseCase>(),
      fetchOrderRatingsUseCase: getIt<FetchFoodOrderRatingsUseCase>(),
    ),
  );

  /// Wishlist
  getIt.registerLazySingleton<WishlistRemoteDataSource>(
    () => WishlistRemoteDataSourceImpl(apiHelper: getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<WishlistRepository>(
    () => WishlistRepository(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => WishlistBloc(repository: getIt()));

  /// Profile
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(getIt<ApiHelper>()),
  );

  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => UpdateProfileUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteAccountUseCase(getIt()));

  getIt.registerFactory(
    () => ProfileBloc(
      updateProfileUseCase: getIt(),
      deleteAccountUseCase: getIt(),
    ),
  );

  /// Site CMS Pages (Privacy & Refund)
  getIt.registerLazySingleton<CmsRemoteDataSource>(
    () => CmsRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<CmsRepository>(
    () => CmsRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => GetCmsPageUseCase(getIt()));

  getIt.registerFactory(() => CmsPageBloc(getCmsPageUseCase: getIt()));

  /// CONNECTIVITY
  getIt.registerLazySingleton<ConnectivityBloc>(() => ConnectivityBloc());

  /// Wallet
  getIt.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => WalletBloc(repository: getIt()));
}
