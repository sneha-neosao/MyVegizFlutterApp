abstract class OrderEvent {}

class FetchOrdersListEvent extends OrderEvent {}

class FetchTodayActiveOrdersEvent extends OrderEvent {
  final int page;
  final int limit;
  FetchTodayActiveOrdersEvent({this.page = 1, this.limit = 10});
}

class FetchOrderDetailsEvent extends OrderEvent {
  final String uuId;
  FetchOrderDetailsEvent(this.uuId);
}

class CancelOrderEvent extends OrderEvent {
  final String uuId;
  final String note;
  CancelOrderEvent({required this.uuId, required this.note});
}
