import 'package:equatable/equatable.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class LoadCheckoutDataEvent extends CheckoutEvent {}

class PlaceOrderEvent extends CheckoutEvent {
  final String paymentMode;
  final String addressUuid;
  final String? slotUuid;
  final String? customerNote;

  const PlaceOrderEvent({
    required this.paymentMode,
    required this.addressUuid,
    this.slotUuid,
    this.customerNote,
  });

  @override
  List<Object?> get props => [paymentMode, addressUuid, slotUuid, customerNote];
}
