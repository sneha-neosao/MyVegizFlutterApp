import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/location_service.dart';

abstract class CartRemoteDataSource {
  Future<Map<String, dynamic>> addToCart({
    required int productVariantId,
    required int quantity,
    required double lat,
    required double lng,
    bool isFood = false,
    List<int>? addonIds,
    List<Map<String, dynamic>>? addonData,
  });

  Future<Map<String, dynamic>> getCartList({
    required double lat,
    required double lng,
  });

  Future<Map<String, dynamic>> updateCart({
    required int cartItemId,
    required int quantity,
    required double lat,
    required double lng,
  });

  Future<Map<String, dynamic>> clearCart();

  Future<Map<String, dynamic>> validateAddress(String addressUuid);

  Future<Map<String, dynamic>> removeCartItem(int cartItemId);

  // Coupon Methods
  Future<Map<String, dynamic>> getAvailableCoupons();
  Future<Map<String, dynamic>> getAvailableFoodCoupons(String vendorUuid);
  Future<Map<String, dynamic>> applyCoupon(String couponCode);
  Future<Map<String, dynamic>> removeCoupon();
  Future<Map<String, dynamic>> validateCoupon(String code);

  // Food Cart Calculation Method
  Future<Map<String, dynamic>> calculateFoodCartTotals({
    required int vendorId,
    required String customerName,
    required String customerId,
    required String customerUuid,
    String? addressUuid,
    double? lat,
    double? lng,
    String? couponCode,
    int? applyWalletPoints,
    required List<Map<String, dynamic>> items,
  });

  Future<Map<String, dynamic>> fetchVendorItemDetails(
    int vendorItemId, {
    double? lat,
    double? lng,
  });
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final ApiHelper _apiHelper;

  CartRemoteDataSourceImpl(this._apiHelper);

  // Helper to format lat/lng to avoid precision issues that might cause 500 errors
  double _fmt(double val) => double.parse(val.toStringAsFixed(6));

  @override
  Future<Map<String, dynamic>> addToCart({
    required int productVariantId,
    required int quantity,
    required double lat,
    required double lng,
    bool isFood = false,
    List<int>? addonIds,
    List<Map<String, dynamic>>? addonData,
  }) async {
    logger.i(
      "🌐 API CALL → Add to Cart (id: $productVariantId, qty: $quantity, isFood: $isFood)",
    );
    final Map<String, dynamic> body = {
      "quantity": quantity,
      "lat": _fmt(lat),
      "lng": _fmt(lng),
    };

    if (isFood || (addonData != null && addonData.isNotEmpty) || (addonIds != null && addonIds.isNotEmpty)) {
      body["vendor_item_id"] = productVariantId;
      if (addonIds != null && addonIds.isNotEmpty) {
        body["addon_id"] = addonIds;
      }
      if (addonData != null && addonData.isNotEmpty) {
        body["addon_data"] = addonData;
      }
    } else {
      body["product_variant_id"] = productVariantId;
    }

    return await _apiHelper.execute(
      method: Method.post,
      url: ApiUrl.addToCart,
      data: body,
    );
  }

  @override
  Future<Map<String, dynamic>> getCartList({
    required double lat,
    required double lng,
  }) async {
    logger.i("🌐 API CALL → Get Cart List (lat: $lat, lng: $lng)");
    return await _apiHelper.execute(
      method: Method.get,
      url: ApiUrl.cartList,
      data: {"lat": _fmt(lat), "lng": _fmt(lng)},
    );
  }

  @override
  Future<Map<String, dynamic>> updateCart({
    required int cartItemId,
    required int quantity,
    required double lat,
    required double lng,
  }) async {
    logger.i("🌐 API CALL → Update Cart (itemId: $cartItemId, qty: $quantity)");
    return await _apiHelper.execute(
      method: Method.put,
      url: ApiUrl.updateCart,
      data: {
        "cart_item_id": cartItemId,
        "quantity": quantity,
        "lat": _fmt(lat),
        "lng": _fmt(lng),
      },
    );
  }

  @override
  Future<Map<String, dynamic>> clearCart() async {
    logger.i("🌐 API CALL → Clear Cart");
    return await _apiHelper.execute(
      method: Method.delete,
      url: ApiUrl.clearCart,
    );
  }

  @override
  Future<Map<String, dynamic>> validateAddress(String addressUuid) async {
    logger.i("🌐 API CALL → Validate Address: $addressUuid");
    return await _apiHelper.execute(
      method: Method.get,
      url: ApiUrl.validateAddress,
      data: {"address_uu_id": addressUuid},
    );
  }

  @override
  Future<Map<String, dynamic>> removeCartItem(int cartItemId) async {
    logger.i("🌐 API CALL → Remove Cart Item: $cartItemId");
    return await _apiHelper.execute(
      method: Method.delete,
      url: ApiUrl.removeCartItem(cartItemId),
    );
  }

  // --- Coupon Methods ---
  @override
  Future<Map<String, dynamic>> getAvailableCoupons() async {
    logger.i("🌐 API CALL → Get Available Coupons");
    return await _apiHelper.execute(
      method: Method.get,
      url: ApiUrl.availableCoupons,
    );
  }

  @override
  Future<Map<String, dynamic>> getAvailableFoodCoupons(String vendorUuid) async {
    final url = ApiUrl.foodAvailableCoupons(vendorUuid);
    logger.d('===== FOOD ORDER API =====');
    logger.d('Request URL: $url');
    logger.d('Request Body: null');
    try {
      final response = await _apiHelper.execute(
        method: Method.get,
        url: url,
      );
      logger.d('===== FOOD ORDER API =====');
      logger.d('Response Status: ${response != null ? response['status'] : 'null'}');
      logger.d('Response Data: $response');
      return response;
    } catch (e) {
      logger.e('===== FOOD ORDER API =====');
      logger.e('Error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> applyCoupon(String couponCode) async {
    logger.i("🌐 API CALL → Apply Coupon: $couponCode");
    return await _apiHelper.execute(
      method: Method.post,
      url: "${ApiUrl.applyCoupon}?coupon_code=$couponCode",
    );
  }

  @override
  Future<Map<String, dynamic>> removeCoupon() async {
    logger.i("🌐 API CALL → Remove Coupon");
    return await _apiHelper.execute(
      method: Method.delete,
      url: ApiUrl.removeCoupon,
    );
  }

  @override
  Future<Map<String, dynamic>> validateCoupon(String code) async {
    logger.i("🌐 API CALL → Validate Coupon: $code");
    return await _apiHelper.execute(
      method: Method.get,
      url: ApiUrl.validateCoupon(code),
    );
  }

  @override
  Future<Map<String, dynamic>> calculateFoodCartTotals({
    required int vendorId,
    required String customerName,
    required String customerId,
    required String customerUuid,
    String? addressUuid,
    double? lat,
    double? lng,
    String? couponCode,
    int? applyWalletPoints,
    required List<Map<String, dynamic>> items,
  }) async {
    logger.i("🌐 API CALL → Calculate Food Cart Totals for Vendor: $vendorId");
    final body = <String, dynamic>{
      "vendor_id": vendorId,
      "customerName": customerName,
      "customer_id": customerId,
      "customer_uu_id": customerUuid,
      "items": items,
    };
    if (addressUuid != null && addressUuid.isNotEmpty) {
      body["address_uu_id"] = addressUuid;
    } else {
      if (lat != null) body["lat"] = _fmt(lat);
      if (lng != null) body["lng"] = _fmt(lng);
    }
    if (couponCode != null) {
      body["coupon_code"] = couponCode;
    }
    if (applyWalletPoints != null) {
      body["apply_wallet_points"] = applyWalletPoints;
    }
    return await _apiHelper.execute(
      method: Method.post,
      url: ApiUrl.calculateTotals,
      data: body,
    );
  }

  @override
  Future<Map<String, dynamic>> fetchVendorItemDetails(
    int vendorItemId, {
    double? lat,
    double? lng,
  }) async {
    logger.i("🌐 API CALL → Fetch Vendor Item Details: $vendorItemId");
    final double finalLat = lat ?? locationService.locationNotifier.value?.lat ?? 0.0;
    final double finalLng = lng ?? locationService.locationNotifier.value?.lng ?? 0.0;
    return await _apiHelper.execute(
      method: Method.get,
      url: ApiUrl.webVendorItemDetails(vendorItemId, lat: finalLat, lng: finalLng),
    );
  }
}
