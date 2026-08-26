import '../data/models/order_model.dart';

abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrderListLoading extends OrderState {}

class OrderListLoaded extends OrderState {
  final List<OrderListItemModel> orders;
  OrderListLoaded(this.orders);
}

class OrderListError extends OrderState {
  final String message;
  OrderListError(this.message);
}

class OrderDetailsLoading extends OrderState {}

class OrderDetailsLoaded extends OrderState {
  final OrderDetailsModel orderDetails;
  OrderDetailsLoaded(this.orderDetails);
}

class OrderDetailsError extends OrderState {
  final String message;
  OrderDetailsError(this.message);
}

class OrderCancelling extends OrderState {}

class OrderCancelled extends OrderState {
  final String message;
  OrderCancelled(this.message);
}

class OrderCancelError extends OrderState {
  final String message;
  OrderCancelError(this.message);
}
