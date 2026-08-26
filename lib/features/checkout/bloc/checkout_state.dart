import 'package:equatable/equatable.dart';
import '../data/models/checkout_model.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutLoaded extends CheckoutState {
  final List<SlotModel> slots;
  final OrderSettingsModel settings;

  const CheckoutLoaded({required this.slots, required this.settings});

  @override
  List<Object?> get props => [slots, settings];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderPlacing extends CheckoutState {}

class OrderPlacedSuccess extends CheckoutState {
  final PlaceOrderResponseModel response;

  const OrderPlacedSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class OrderPlacedFailure extends CheckoutState {
  final String message;

  const OrderPlacedFailure(this.message);

  @override
  List<Object?> get props => [message];
}
