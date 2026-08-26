import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/food_rating_model.dart';
import '../../data/repository/food_order_repo.dart';

class SubmitFoodVendorRatingUseCase {
  final FoodOrderRepository repository;

  SubmitFoodVendorRatingUseCase(this.repository);

  Future<Either<Failure, void>> execute(String orderUuId, double rating, String review) async {
    return await repository.submitFoodVendorRating(orderUuId, rating, review);
  }
}

class SubmitFoodItemRatingsUseCase {
  final FoodOrderRepository repository;

  SubmitFoodItemRatingsUseCase(this.repository);

  Future<Either<Failure, void>> execute(String orderUuId, List<FoodProductRatingModel> ratings) async {
    return await repository.submitFoodItemRatings(orderUuId, ratings);
  }
}

class SubmitFoodDeliveryRatingUseCase {
  final FoodOrderRepository repository;

  SubmitFoodDeliveryRatingUseCase(this.repository);

  Future<Either<Failure, void>> execute(String orderUuId, double rating, String review) async {
    return await repository.submitFoodDeliveryRating(orderUuId, rating, review);
  }
}

class FetchFoodOrderRatingsUseCase {
  final FoodOrderRepository repository;

  FetchFoodOrderRatingsUseCase(this.repository);

  Future<Either<Failure, FoodOrderRatingsResponseModel>> execute(String orderUuId) async {
    return await repository.fetchFoodOrderRatings(orderUuId);
  }
}
