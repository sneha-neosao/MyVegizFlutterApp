import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/food_order_datasource.dart';
import '../models/food_order_model.dart';
import '../models/food_rating_model.dart';
import '../../../../core/utils/logger.dart';

abstract class FoodOrderRepository {
  Future<Either<Failure, FoodOrderListResponse>> getFoodOrdersList();
  Future<Either<Failure, FoodOrderDetailsModel>> getFoodOrderDetails(String uuId);
  Future<Either<Failure, FoodOrderDetailsModel>> placeFoodOrder({
    required int vendorId,
    required String customerUuid,
    required String addressUuid,
    String? couponCode,
    int? applyWalletPoints,
    required String paymentMode,
    String? customerNote,
    required List<Map<String, dynamic>> items,
  });
  Future<Either<Failure, FoodCancelOrderResponseModel>> cancelFoodOrder(String uuId, String note);
  Future<Either<Failure, List<dynamic>>> getAvailableFoodCoupons(String vendorUuid);

  // Rating Methods
  Future<Either<Failure, void>> submitFoodVendorRating(String orderUuId, double rating, String review);
  Future<Either<Failure, void>> submitFoodItemRatings(String orderUuId, List<FoodProductRatingModel> ratings);
  Future<Either<Failure, void>> submitFoodDeliveryRating(String orderUuId, double rating, String review);
  Future<Either<Failure, FoodOrderRatingsResponseModel>> fetchFoodOrderRatings(String orderUuId);
}

class FoodOrderRepositoryImpl implements FoodOrderRepository {
  final FoodOrderRemoteDataSource remoteDataSource;

  FoodOrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, FoodOrderListResponse>> getFoodOrdersList() async {
    try {
      final result = await remoteDataSource.getFoodOrdersList();
      return Right(result);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl getFoodOrdersList error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FoodOrderDetailsModel>> getFoodOrderDetails(String uuId) async {
    try {
      final result = await remoteDataSource.getFoodOrderDetails(uuId);
      return Right(result);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl getFoodOrderDetails error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FoodOrderDetailsModel>> placeFoodOrder({
    required int vendorId,
    required String customerUuid,
    required String addressUuid,
    String? couponCode,
    int? applyWalletPoints,
    required String paymentMode,
    String? customerNote,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final result = await remoteDataSource.placeFoodOrder(
        vendorId: vendorId,
        customerUuid: customerUuid,
        addressUuid: addressUuid,
        couponCode: couponCode,
        applyWalletPoints: applyWalletPoints,
        paymentMode: paymentMode,
        customerNote: customerNote,
        items: items,
      );
      return Right(result);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl placeFoodOrder error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FoodCancelOrderResponseModel>> cancelFoodOrder(String uuId, String note) async {
    try {
      final result = await remoteDataSource.cancelFoodOrder(uuId, note);
      return Right(result);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl cancelFoodOrder error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getAvailableFoodCoupons(String vendorUuid) async {
    try {
      final result = await remoteDataSource.getAvailableFoodCoupons(vendorUuid);
      return Right(result);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl getAvailableFoodCoupons error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitFoodVendorRating(String orderUuId, double rating, String review) async {
    try {
      await remoteDataSource.submitFoodVendorRating(orderUuId, rating, review);
      return const Right(null);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl submitFoodVendorRating error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitFoodItemRatings(String orderUuId, List<FoodProductRatingModel> ratings) async {
    try {
      await remoteDataSource.submitFoodItemRatings(orderUuId, ratings);
      return const Right(null);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl submitFoodItemRatings error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitFoodDeliveryRating(String orderUuId, double rating, String review) async {
    try {
      await remoteDataSource.submitFoodDeliveryRating(orderUuId, rating, review);
      return const Right(null);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl submitFoodDeliveryRating error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FoodOrderRatingsResponseModel>> fetchFoodOrderRatings(String orderUuId) async {
    try {
      final result = await remoteDataSource.fetchFoodOrderRatings(orderUuId);
      return Right(result);
    } catch (e) {
      logger.e("FoodOrderRepositoryImpl fetchFoodOrderRatings error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }
}
