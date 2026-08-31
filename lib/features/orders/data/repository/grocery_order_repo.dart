import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/order_datasource.dart';
import '../models/order_model.dart';
import '../models/today_active_order_model.dart';
import '../../../profile/data/models/rating_model.dart';
import '../../../../core/utils/logger.dart';

abstract class GroceryOrderRepository {
  Future<Either<Failure, OrderListResponse>> getOrdersList();
  Future<Either<Failure, TodayActiveOrdersResponse>> getTodayActiveOrders({
    int page = 1,
    int limit = 10,
  });
  Future<Either<Failure, OrderDetailsModel>> getOrderDetails(String uuId);
  Future<Either<Failure, CancelOrderResponseModel>> cancelOrder(
    String uuId,
    String note,
  );

  // Rating Methods
  Future<Either<Failure, void>> submitProductRatings(
    String orderUuId,
    List<ProductRatingModel> ratings,
  );
  Future<Either<Failure, void>> submitDeliveryRating(
    String orderUuId,
    double rating,
    String review,
  );
  Future<Either<Failure, OrderRatingsResponseModel>> fetchOrderRatings(
    String orderUuId,
  );
}

class GroceryOrderRepositoryImpl implements GroceryOrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  GroceryOrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, OrderListResponse>> getOrdersList() async {
    try {
      final result = await remoteDataSource.getOrdersList();
      return Right(result);
    } catch (e) {
      logger.e("OrderRepositoryImpl getOrdersList error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TodayActiveOrdersResponse>> getTodayActiveOrders({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getTodayActiveOrders(
        page: page,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      logger.e("GroceryOrderRepositoryImpl getTodayActiveOrders error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderDetailsModel>> getOrderDetails(
    String uuId,
  ) async {
    try {
      final result = await remoteDataSource.getOrderDetails(uuId);
      return Right(result);
    } catch (e) {
      logger.e("OrderRepositoryImpl getOrderDetails error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CancelOrderResponseModel>> cancelOrder(
    String uuId,
    String note,
  ) async {
    try {
      final result = await remoteDataSource.cancelOrder(uuId, note);
      return Right(result);
    } catch (e) {
      logger.e("OrderRepositoryImpl cancelOrder error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitProductRatings(
    String orderUuId,
    List<ProductRatingModel> ratings,
  ) async {
    try {
      await remoteDataSource.submitProductRatings(orderUuId, ratings);
      return const Right(null);
    } catch (e) {
      logger.e("OrderRepositoryImpl submitProductRatings error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitDeliveryRating(
    String orderUuId,
    double rating,
    String review,
  ) async {
    try {
      await remoteDataSource.submitDeliveryRating(orderUuId, rating, review);
      return const Right(null);
    } catch (e) {
      logger.e("OrderRepositoryImpl submitDeliveryRating error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderRatingsResponseModel>> fetchOrderRatings(
    String orderUuId,
  ) async {
    try {
      final result = await remoteDataSource.fetchOrderRatings(orderUuId);
      return Right(result);
    } catch (e) {
      logger.e("OrderRepositoryImpl fetchOrderRatings error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }
}
