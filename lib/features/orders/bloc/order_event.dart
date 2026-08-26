abstract class OrderEvent {}

class FetchOrdersListEvent extends OrderEvent {}

class FetchOrderDetailsEvent extends OrderEvent {
  final String uuId;
  FetchOrderDetailsEvent(this.uuId);
}

class CancelOrderEvent extends OrderEvent {
  final String uuId;
  final String note;
  CancelOrderEvent({required this.uuId, required this.note});
}
