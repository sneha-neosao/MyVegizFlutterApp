import 'package:flutter/foundation.dart';
import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/food_order_model.dart';
import '../models/food_rating_model.dart';

abstract class FoodOrderRemoteDataSource {
  Future<FoodOrderListResponse> getFoodOrdersList();
  Future<FoodOrderDetailsModel> getFoodOrderDetails(String uuId);
  Future<FoodOrderDetailsModel> placeFoodOrder({
    required int vendorId,
    required String customerUuid,
    required String addressUuid,
    String? couponCode,
    int? applyWalletPoints,
    required String paymentMode,
    String? customerNote,
    required List<Map<String, dynamic>> items,
  });
  Future<FoodCancelOrderResponseModel> cancelFoodOrder(String uuId, String note);
  Future<List<dynamic>> getAvailableFoodCoupons(String vendorUuid);

  // Rating Methods
  Future<void> submitFoodVendorRating(String orderUuId, double rating, String review);
  Future<void> submitFoodItemRatings(String orderUuId, List<FoodProductRatingModel> ratings);
  Future<void> submitFoodDeliveryRating(String orderUuId, double rating, String review);
  Future<FoodOrderRatingsResponseModel> fetchFoodOrderRatings(String orderUuId);
}

class FoodOrderRemoteDataSourceImpl implements FoodOrderRemoteDataSource {
  final ApiHelper apiHelper;

  FoodOrderRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<FoodOrderListResponse> getFoodOrdersList() async {
    final url = ApiUrl.foodOrdersList;
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: url,
      );

      debugPrint('===== FOOD ORDER API =====');
      debugPrint('Request URL: $url');
      debugPrint('Request Body: null');
      debugPrint('Response Status: ${response != null ? response['status'] : 'null'}');
      debugPrint('Response Data: $response');

      if (response != null) {
        return FoodOrderListResponse.fromJson(response);
      } else {
        throw Exception("Failed to load food orders list");
      }
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl getFoodOrdersList error: $e");
      rethrow;
    }
  }

  @override
  Future<FoodOrderDetailsModel> getFoodOrderDetails(String uuId) async {
    final url = ApiUrl.foodOrderDetails(uuId);
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: url,
      );

      debugPrint('===== FOOD ORDER API =====');
      debugPrint('Request URL: $url');
      debugPrint('Request Body: null');
      debugPrint('Response Status: ${response != null ? response['status'] : 'null'}');
      debugPrint('Response Data: $response');

      if (response != null) {
        return FoodOrderDetailsModel.fromJson(response);
      } else {
        throw Exception("Failed to load food order details");
      }
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl getFoodOrderDetails error: $e");
      rethrow;
    }
  }

  @override
  Future<FoodOrderDetailsModel> placeFoodOrder({
    required int vendorId,
    required String customerUuid,
    required String addressUuid,
    String? couponCode,
    int? applyWalletPoints,
    required String paymentMode,
    String? customerNote,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = ApiUrl.foodPlaceOrder;
    final body = {
      "vendor_id": vendorId,
      "customer_uu_id": customerUuid,
      "address_uu_id": addressUuid,
      if (couponCode != null && couponCode.isNotEmpty) "coupon_code": couponCode,
      if (applyWalletPoints != null && applyWalletPoints > 0) "apply_wallet_points": applyWalletPoints,
      "payment_mode": paymentMode,
      if (customerNote != null && customerNote.isNotEmpty) "customer_note": customerNote,
      "items": items,
    };

    try {
      final response = await apiHelper.execute(
        method: Method.post,
        url: url,
        data: body,
      );

      debugPrint('===== FOOD ORDER API =====');
      debugPrint('Request URL: $url');
      debugPrint('Request Body: $body');
      debugPrint('Response Status: ${response != null ? response['status'] : 'null'}');
      debugPrint('Response Data: $response');

      if (response != null) {
        return FoodOrderDetailsModel.fromJson(response);
      } else {
        throw Exception("Failed to place food order");
      }
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl placeFoodOrder error: $e");
      rethrow;
    }
  }

  @override
  Future<FoodCancelOrderResponseModel> cancelFoodOrder(String uuId, String note) async {
    final url = ApiUrl.foodCancelOrder;
    final body = {'uu_id': uuId, 'note': note};
    try {
      final response = await apiHelper.execute(
        method: Method.post,
        url: url,
        data: body,
      );

      debugPrint('===== FOOD ORDER API =====');
      debugPrint('Request URL: $url');
      debugPrint('Request Body: $body');
      debugPrint('Response Status: ${response != null ? response['status'] : 'null'}');
      debugPrint('Response Data: $response');

      if (response != null) {
        return FoodCancelOrderResponseModel.fromJson(response);
      } else {
        throw Exception("Failed to cancel food order");
      }
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl cancelFoodOrder error: $e");
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getAvailableFoodCoupons(String vendorUuid) async {
    final url = ApiUrl.foodAvailableCoupons(vendorUuid);
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: url,
      );

      debugPrint('===== FOOD ORDER API =====');
      debugPrint('Request URL: $url');
      debugPrint('Request Body: null');
      debugPrint('Response Status: ${response != null ? response['status'] : 'null'}');
      debugPrint('Response Data: $response');

      if (response != null && response['data'] != null) {
        return response['data'] as List<dynamic>;
      } else {
        return [];
      }
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl getAvailableFoodCoupons error: $e");
      rethrow;
    }
  }

  @override
  Future<void> submitFoodVendorRating(String orderUuId, double rating, String review) async {
    try {
      await apiHelper.execute(
        method: Method.post,
        url: ApiUrl.foodVendorRating,
        data: {
          'order_uu_id': orderUuId,
          'rating': rating,
          'review': review,
        },
      );
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl submitFoodVendorRating error: $e");
      rethrow;
    }
  }

  @override
  Future<void> submitFoodItemRatings(String orderUuId, List<FoodProductRatingModel> ratings) async {
    try {
      await apiHelper.execute(
        method: Method.post,
        url: ApiUrl.foodItemRatings,
        data: {
          'order_uu_id': orderUuId,
          'ratings': ratings.map((e) => e.toJson()).toList(),
        },
      );
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl submitFoodItemRatings error: $e");
      rethrow;
    }
  }

  @override
  Future<void> submitFoodDeliveryRating(String orderUuId, double rating, String review) async {
    try {
      await apiHelper.execute(
        method: Method.post,
        url: ApiUrl.foodDeliveryRating,
        data: {
          'order_uu_id': orderUuId,
          'rating': rating,
          'review': review,
        },
      );
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl submitFoodDeliveryRating error: $e");
      rethrow;
    }
  }

  @override
  Future<FoodOrderRatingsResponseModel> fetchFoodOrderRatings(String orderUuId) async {
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.fetchFoodOrderRatings(orderUuId),
      );
      if (response != null) {
        return FoodOrderRatingsResponseModel.fromJson(response);
      } else {
        throw Exception("Failed to fetch food order ratings");
      }
    } catch (e) {
      logger.e("FoodOrderRemoteDataSourceImpl fetchFoodOrderRatings error: $e");
      rethrow;
    }
  }
}
