import 'package:equatable/equatable.dart';
import '../data/models/food_rating_model.dart';

abstract class FoodRatingState extends Equatable {
  const FoodRatingState();

  @override
  List<Object?> get props => [];
}

class FoodRatingInitial extends FoodRatingState {}

class FoodRatingLoading extends FoodRatingState {}

class FoodOrderRatingsLoaded extends FoodRatingState {
  final FoodOrderRatingsResponseModel ratings;

  const FoodOrderRatingsLoaded(this.ratings);

  @override
  List<Object?> get props => [ratings];
}

class FoodOrderRatingsError extends FoodRatingState {
  final String message;

  const FoodOrderRatingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Submitting states
class FoodRatingSubmitting extends FoodRatingState {}

class FoodRatingSubmitSuccess extends FoodRatingState {}

class FoodRatingSubmitError extends FoodRatingState {
  final String message;

  const FoodRatingSubmitError(this.message);

  @override
  List<Object?> get props => [message];
}
