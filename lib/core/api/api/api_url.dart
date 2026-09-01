
import '../../utils/logger.dart';

/// Centralized API endpoints and domain URLs used throughout the app.
class ApiUrl {
  const ApiUrl._();

  static String baseUrl = 'https://myvegizapis.neosao.co.in/api/v1';
  static String networkChecker = 'https://myvegizapis.neosao.co.in';

  // static String baseUrl = 'http://192.168.1.17:8002/api/v1';
  // static String networkChecker = 'http://192.168.1.17:8002';

  static Future<void> initBaseUrl() async {
    try {} catch (e) {
      logger.e('ApiUrl.initBaseUrl error: $e');
    }
  }

  static String sendOtp = "$baseUrl/web/auth/send-otp";

  static String checkUserExist = "$baseUrl/web/auth/check-user-exist";

  static String updateFirebaseToken = "$baseUrl/web/auth/update-firebase-token";

  static String vendorBanners({required double lat, required double lng}) => "$baseUrl/web/vendor_banners/list?lat=$lat&lng=$lng";

  static String verifyOtp = "$baseUrl/web/auth/verify-otp";

  static String register = "$baseUrl/web/auth/register";

  static String regiVerifyOtp = "$baseUrl/web/auth/register/verify-otp";

  static String mainCategories(int page, int limit) => "$baseUrl/web/main_categories/list?page=$page&limit=$limit";

  static String homePage({
    required String mainCategorySlug,
    String? homeTabSlug,
    required double lat,
    required double lng,
    String? q,
  }) {
    String url =
        "$baseUrl/web/homepage/?main_category_slug=$mainCategorySlug&lat=$lat&lng=$lng";
    if (homeTabSlug != null && homeTabSlug.isNotEmpty) {
      url += "&home_tab_slug=$homeTabSlug";
    }
    if (q != null && q.isNotEmpty) {
      url += "&q=${Uri.encodeQueryComponent(q)}";
    }
    return url;
  }

  static String homeTabSubCategories({
    required String homeTabUuId,
    int page = 1,
    int limit = 10,
  }) =>
      "$baseUrl/web/home_tabs/sub-categories?home_tab_uu_id=$homeTabUuId&page=$page&limit=$limit";

  static String categoryProducts({
    required double lat,
    required double lng,
    required String subCategoryUuId,
    int? homeTabId,
    String? categorySlug,
    String? search,
    String? tagUuId,
    String? sortBy,
    int? page,
    int? limit,
  }) {
    String url =
        "$baseUrl/web/grocery-products/list-with-variants?page=${page ?? 1}&limit=${limit ?? 100}";

    if (subCategoryUuId.isNotEmpty) {
      url += "&sub_category_uuid=$subCategoryUuId";
    }
    if (homeTabId != null && homeTabId > 0) {
      url += "&home_tab_id=$homeTabId";
    }
    if (categorySlug != null && categorySlug.isNotEmpty) {
      url += "&category_slug=$categorySlug";
    }
    if (search != null && search.isNotEmpty) {
      url += "&search=${Uri.encodeQueryComponent(search)}";
    }
    if (tagUuId != null && tagUuId.isNotEmpty) {
      url += "&tag_uu_id=$tagUuId";
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      url += "&sort_by=$sortBy";
    }
    url += "&lat=$lat&lng=$lng";
    return url;
  }

  static String categoryFilters({required String categorySlug}) =>
      "$baseUrl/web/homepage/category/filters?category_slug=$categorySlug";

  static String subCategoriesByCategory({
    required String categorySlug,
    int page = 1,
    int limit = 10,
  }) =>
      "$baseUrl/web/sub_categories/by-category?category_slug=$categorySlug&page=$page&limit=$limit";

  static String searchGroceryProducts({
    required String query,
    required double lat,
    required double lng,
    int? page,
    int? limit,
    String? categorySlug,
    String? subCategoryUuid,
  }) {
    String url =
        "$baseUrl/web/grocery-products/search?search=${Uri.encodeQueryComponent(query)}&page=${page ?? 1}&limit=${limit ?? 10}&lat=$lat&lng=$lng";
    if (categorySlug != null && categorySlug.isNotEmpty) {
      url += "&category_slug=$categorySlug";
    }
    if (subCategoryUuid != null && subCategoryUuid.isNotEmpty) {
      url += "&sub_category_uuid=$subCategoryUuid";
    }
    return url;
  }

  static String productDetails({
    required String slug,
    required double lat,
    required double lng,
  }) => "$baseUrl/web/product/details?slug=$slug&lat=$lat&lng=$lng";

  static String addressList = "$baseUrl/web/address/list";

  static String addAddress = "$baseUrl/web/address/add";

  static String updateAddress(String uuId) =>
      "$baseUrl/web/address/update?uu_id=$uuId";

  static String deleteAddress(String uuId) =>
      "$baseUrl/web/address/delete?uu_id=$uuId";

  // Cart Endpoints
  static String addToCart = "$baseUrl/web/cart/add";
  static String cartList = "$baseUrl/web/cart/list";
  static String updateCart = "$baseUrl/web/cart/update";
  static String clearCart = "$baseUrl/web/cart/clear";
  static String validateAddress = "$baseUrl/web/cart/validate_address";
  static String removeCartItem(int cartItemId) =>
      "$baseUrl/web/cart/remove/$cartItemId";
  static String calculateTotals = "$baseUrl/web/vendor/orders/calculate-totals";

  // Coupon Endpoints
  static String availableCoupons = "$baseUrl/web/cart/available-coupons";
  static String applyCoupon = "$baseUrl/web/cart/apply-coupon";
  static String removeCoupon = "$baseUrl/web/cart/remove-coupon";
  static String validateCoupon(String code) =>
      "$baseUrl/web/cart/validate?code=$code";

  // Checkout Endpoints
  static String slotsAvailable = "$baseUrl/web/orders/slots/available";
  static String orderSettingsList = "$baseUrl/web/order_settings/list";
  static String placeOrder = "$baseUrl/web/orders/place";

  // Order Endpoints
  static String ordersList = "$baseUrl/web/orders/list";
  static String todayActiveOrders({int page = 1, int limit = 10}) =>
      "$baseUrl/web/orders/today-active-order?page=$page&limit=$limit";
  static String orderDetails(String uuId) =>
      "$baseUrl/web/orders/detail?uu_id=$uuId";
  static String cancelOrder = "$baseUrl/web/orders/cancel";

  // Rating Endpoints
  static String productRatings = "$baseUrl/web/ratings/product";
  static String deliveryRating = "$baseUrl/web/ratings/delivery";
  static String fetchOrderRatings(String orderUuId) =>
      "$baseUrl/web/ratings/order?order_uu_id=$orderUuId";

  // Food Order Endpoints
  static String foodAvailableCoupons(String vendorUuid) =>
      "$baseUrl/web/vendor/orders/available-coupons?vendor_uu_id=$vendorUuid";
  static String foodPlaceOrder = "$baseUrl/web/vendor/orders/place";
  static String foodOrdersList = "$baseUrl/web/vendor/orders/list";
  static String foodOrderDetails(String uuId) =>
      "$baseUrl/web/vendor/orders/detail?uu_id=$uuId";
  static String foodCancelOrder = "$baseUrl/web/orders/cancel";
  static String foodCalculateTotals =
      "$baseUrl/web/vendor/orders/calculate-totals";

  // Food Rating Endpoints
  static String foodVendorRating = "$baseUrl/web/vendor/ratings/vendor";
  static String foodItemRatings = "$baseUrl/web/vendor/ratings/items";
  static String foodDeliveryRating = "$baseUrl/web/vendor/ratings/delivery";
  static String fetchFoodOrderRatings(String orderUuId) =>
      "$baseUrl/web/vendor/ratings/order?order_uu_id=$orderUuId";

  // Wishlist Endpoints
  static String toggleWishlist(int productId) =>
      "$baseUrl/web/favourites/toggle?product_id=$productId";
  static String getWishlist = "$baseUrl/web/favourites/list";

  // Profile Endpoints
  static String updateProfile = "$baseUrl/web/profile/update";
  static String deleteAccount = "$baseUrl/web/profile/delete";

  // Wallet Endpoints
  static String walletSummary = "$baseUrl/web/wallet/summary";
  static String walletTransactions(int page, int limit) =>
      "$baseUrl/web/wallet/list?page=$page&limit=$limit";
  static String applyWallet = "$baseUrl/web/wallet/apply";
  static String removeWallet = "$baseUrl/web/wallet/remove";

  // Vendors Endpoints
  static String webVendorsList({
    required int limit,
    required int page,
    required int vendorId,
    required double lat,
    required double lng,
    String? sortBy,
    String? foodType,
  }) {
    String url =
        "$baseUrl/web/web_vendors/list?lat=$lat&lng=$lng&vendor_id=$vendorId&limit=$limit&page=$page";
    if (sortBy != null && sortBy.isNotEmpty) {
      url += "&sort_by=$sortBy";
    }
    if (foodType != null && foodType.isNotEmpty) {
      url += "&food_type=$foodType";
    }
    return url;
  }

  static String webVendorDetails({
    required int vendorId,
    required double lat,
    required double lng,
  }) =>
      "$baseUrl/web/web_vendors/details?vendor_id=$vendorId&lat=$lat&lng=$lng";

  static String webVendorFilters({required int vendorId}) =>
      "$baseUrl/web/web_vendors/filters?vendor_id=$vendorId";

  static String webVendorItemDetails(
    int vendorItemId, {
    required double lat,
    required double lng,
  }) =>
      "$baseUrl/web/web_vendors/item-details?vendor_item_id=$vendorItemId&lat=$lat&lng=$lng";

  // Entity Vendors Endpoints
  static String vendorEntityCategoryList({
    required String entityCategoryUuid,
    required double lat,
    required double lng,
    String? sortBy,
    String? foodType,
  }) {
    String url = "$baseUrl/web/vendor_entitycategory/list?entity_category_uuid=$entityCategoryUuid&lat=$lat&lng=$lng";
    if (sortBy != null && sortBy.isNotEmpty) {
      url += "&sort_by=$sortBy";
    }
    if (foodType != null && foodType.isNotEmpty) {
      url += "&food_type=$foodType";
    }
    return url;
  }

  static String vendorEntityCategoryFilters =
      "$baseUrl/web/vendor_entitycategory/filters";

  static String vendorEntityCategoryCategoriesList =
      "$baseUrl/web/vendor_entitycategory/categories/list";

  static String entityCategoriesList = "$baseUrl/web/entity_categories/list";

  static String groceryCategories({
    required int page,
    required int limit,
    required String mainCategorySlug,
  }) =>
      "$baseUrl/web/categories/list?page=$page&limit=$limit&main_category_slug=$mainCategorySlug";

  static String privacyPolicy = "$baseUrl/web/sitecms/privacypolicy/list";
  static String refundPolicy = "$baseUrl/web/sitecms/refund/list";
  static String termsAndConditions = "$baseUrl/web/sitecms/terms/list";

  static String appVersion = "$baseUrl/web/sitecms/app-version";

  // ── Google Places API ─────────────────────────────────────────────────────
  /// Key is the same one registered in AndroidManifest.xml / AppDelegate.swift.
  static const String googlePlacesApiKey =
      'AIzaSyCZw4DVNyJwP85ZeDG1y_x8DLQ7bF8J0EU';

  static String placesAutocomplete(String input) =>
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeQueryComponent(input)}'
      '&key=$googlePlacesApiKey'
      '&components=country:in'
      '&language=en';

  static String placeDetails(String placeId) =>
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=geometry,name,formatted_address'
      '&key=$googlePlacesApiKey';
}
