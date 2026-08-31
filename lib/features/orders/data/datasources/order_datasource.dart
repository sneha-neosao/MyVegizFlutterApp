import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/order_model.dart';
import '../models/today_active_order_model.dart';
import '../../../profile/data/models/rating_model.dart';
import '../../../../core/utils/logger.dart';

abstract class OrderRemoteDataSource {
  Future<OrderListResponse> getOrdersList();
  Future<TodayActiveOrdersResponse> getTodayActiveOrders({int page = 1, int limit = 10});
  Future<OrderDetailsModel> getOrderDetails(String uuId);
  Future<CancelOrderResponseModel> cancelOrder(String uuId, String note);
  
  // Rating Methods
  Future<void> submitProductRatings(String orderUuId, List<ProductRatingModel> ratings);
  Future<void> submitDeliveryRating(String orderUuId, double rating, String review);
  Future<OrderRatingsResponseModel> fetchOrderRatings(String orderUuId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiHelper apiHelper;

  OrderRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<OrderListResponse> getOrdersList() async {
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.ordersList,
      );
      if (response != null) {
        logger.d("ordersList JSON response: $response");
        return OrderListResponse.fromJson(response);
      } else {
        throw Exception("Failed to load orders list");
      }
    } catch (e) {
      logger.e("OrderRemoteDataSourceImpl getOrdersList error: $e");
      rethrow;
    }
  }

  @override
  Future<TodayActiveOrdersResponse> getTodayActiveOrders({int page = 1, int limit = 10}) async {
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.todayActiveOrders(page: page, limit: limit),
      );
      if (response != null) {
        logger.d("todayActiveOrders JSON response: $response");
        return TodayActiveOrdersResponse.fromJson(response);
      } else {
        throw Exception("Failed to load today active orders");
      }
    } catch (e) {
      logger.e("OrderRemoteDataSourceImpl getTodayActiveOrders error: $e");
      rethrow;
    }
  }

  @override
  Future<OrderDetailsModel> getOrderDetails(String uuId) async {
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.orderDetails(uuId),
      );
      if (response != null) {
        // 🔍 DEBUG: Log full response to verify customer_note is returned by API
        logger.d('===== ORDER DETAILS API ===== Raw Response: $response');
        final data = response['data'] ?? response;
        logger.d('===== ORDER DETAILS API ===== customer_note from API: ${data['customer_note']}');
        return OrderDetailsModel.fromJson(response);
      } else {
        throw Exception("Failed to load order details");
      }
    } catch (e) {
      logger.e("OrderRemoteDataSourceImpl getOrderDetails error: $e");
      rethrow;
    }
  }

  @override
  Future<CancelOrderResponseModel> cancelOrder(String uuId, String note) async {
    try {
      final response = await apiHelper.execute(
        method: Method.post,
        url: ApiUrl.cancelOrder,
        data: {'uu_id': uuId, 'note': note},
      );
      if (response != null) {
        return CancelOrderResponseModel.fromJson(response);
      } else {
        throw Exception("Failed to cancel order");
      }
    } catch (e) {
      logger.e("OrderRemoteDataSourceImpl cancelOrder error: $e");
      rethrow;
    }
  }

  @override
  Future<void> submitProductRatings(String orderUuId, List<ProductRatingModel> ratings) async {
    try {
      await apiHelper.execute(
        method: Method.post,
        url: ApiUrl.productRatings,
        data: {
          'order_uu_id': orderUuId,
          'ratings': ratings.map((e) => e.toJson()).toList(),
        },
      );
    } catch (e) {
      logger.e("OrderRemoteDataSourceImpl submitProductRatings error: $e");
      rethrow;
    }
  }

  @override
  Future<void> submitDeliveryRating(String orderUuId, double rating, String review) async {
    try {
      await apiHelper.execute(
        method: Method.post,
        url: ApiUrl.deliveryRating,
        data: {
          'order_uu_id': orderUuId,
          'rating': rating,
          'review': review,
        },
      );
    } catch (e) {
      logger.e("OrderRemoteDataSourceImpl submitDeliveryRating error: $e");
      rethrow;
    }
  }

  @override
  Future<OrderRatingsResponseModel> fetchOrderRatings(String orderUuId) async {
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.fetchOrderRatings(orderUuId),
      );
      if (response != null) {
        return OrderRatingsResponseModel.fromJson(response);
      } else {
        throw Exception("Failed to fetch order ratings");
      }
    } catch (e) {
      logger.e("OrderRemoteDataSourceImpl fetchOrderRatings error: $e");
      rethrow;
    }
  }
}
