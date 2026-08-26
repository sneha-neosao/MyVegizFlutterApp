import 'package:equatable/equatable.dart';
import '../data/models/food_order_model.dart';

abstract class FoodOrderState extends Equatable {
  const FoodOrderState();

  @override
  List<Object?> get props => [];
}

class FoodOrderInitial extends FoodOrderState {}

// List States
class FoodOrderListLoading extends FoodOrderState {}

class FoodOrderListLoaded extends FoodOrderState {
  final List<FoodOrderListItemModel> orders;

  const FoodOrderListLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class FoodOrderListError extends FoodOrderState {
  final String message;

  const FoodOrderListError(this.message);

  @override
  List<Object?> get props => [message];
}

// Details States
class FoodOrderDetailsLoading extends FoodOrderState {}

class FoodOrderDetailsLoaded extends FoodOrderState {
  final FoodOrderDetailsModel orderDetails;

  const FoodOrderDetailsLoaded(this.orderDetails);

  @override
  List<Object?> get props => [orderDetails];
}

class FoodOrderDetailsError extends FoodOrderState {
  final String message;

  const FoodOrderDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Place Order States
class FoodOrderPlacing extends FoodOrderState {}

class FoodOrderPlacedSuccess extends FoodOrderState {
  final FoodOrderDetailsModel orderDetails;

  const FoodOrderPlacedSuccess(this.orderDetails);

  @override
  List<Object?> get props => [orderDetails];
}

class FoodOrderPlacedFailure extends FoodOrderState {
  final String message;

  const FoodOrderPlacedFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// Cancel Order States
class FoodOrderCancelling extends FoodOrderState {}

class FoodOrderCancelled extends FoodOrderState {
  final String message;

  const FoodOrderCancelled(this.message);

  @override
  List<Object?> get props => [message];
}

class FoodOrderCancelError extends FoodOrderState {
  final String message;

  const FoodOrderCancelError(this.message);

  @override
  List<Object?> get props => [message];
}
