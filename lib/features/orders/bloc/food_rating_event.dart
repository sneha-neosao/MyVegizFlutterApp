import 'package:equatable/equatable.dart';
import '../data/models/food_rating_model.dart';

abstract class FoodRatingEvent extends Equatable {
  const FoodRatingEvent();

  @override
  List<Object?> get props => [];
}

class FetchFoodOrderRatingsEvent extends FoodRatingEvent {
  final String orderUuId;

  const FetchFoodOrderRatingsEvent(this.orderUuId);

  @override
  List<Object?> get props => [orderUuId];
}

class SubmitFoodVendorRatingEvent extends FoodRatingEvent {
  final String orderUuId;
  final double rating;
  final String review;

  const SubmitFoodVendorRatingEvent({
    required this.orderUuId,
    required this.rating,
    required this.review,
  });

  @override
  List<Object?> get props => [orderUuId, rating, review];
}

class SubmitFoodItemRatingsEvent extends FoodRatingEvent {
  final String orderUuId;
  final List<FoodProductRatingModel> ratings;

  const SubmitFoodItemRatingsEvent({
    required this.orderUuId,
    required this.ratings,
  });

  @override
  List<Object?> get props => [orderUuId, ratings];
}

class SubmitFoodDeliveryRatingEvent extends FoodRatingEvent {
  final String orderUuId;
  final double rating;
  final String review;

  const SubmitFoodDeliveryRatingEvent({
    required this.orderUuId,
    required this.rating,
    required this.review,
  });

  @override
  List<Object?> get props => [orderUuId, rating, review];
}
