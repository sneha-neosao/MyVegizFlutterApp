import 'package:equatable/equatable.dart';

abstract class FoodOrderEvent extends Equatable {
  const FoodOrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchFoodOrdersListEvent extends FoodOrderEvent {}

class FetchFoodOrderDetailsEvent extends FoodOrderEvent {
  final String uuId;

  const FetchFoodOrderDetailsEvent(this.uuId);

  @override
  List<Object?> get props => [uuId];
}

class PlaceFoodOrderEvent extends FoodOrderEvent {
  final int vendorId;
  final String customerUuid;
  final String addressUuid;
  final String? couponCode;
  final int? applyWalletPoints;
  final String paymentMode;
  final String? customerNote;
  final List<Map<String, dynamic>> items;

  const PlaceFoodOrderEvent({
    required this.vendorId,
    required this.customerUuid,
    required this.addressUuid,
    this.couponCode,
    this.applyWalletPoints,
    required this.paymentMode,
    this.customerNote,
    required this.items,
  });

  @override
  List<Object?> get props => [
        vendorId,
        customerUuid,
        addressUuid,
        couponCode,
        applyWalletPoints,
        paymentMode,
        customerNote,
        items,
      ];
}

class CancelFoodOrderEvent extends FoodOrderEvent {
  final String uuId;
  final String note;

  const CancelFoodOrderEvent({required this.uuId, required this.note});

  @override
  List<Object?> get props => [uuId, note];
}
