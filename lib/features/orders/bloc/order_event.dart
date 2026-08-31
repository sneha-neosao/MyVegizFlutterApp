abstract class OrderEvent {
  const OrderEvent();
}

class FetchOrdersListEvent extends OrderEvent {
  const FetchOrdersListEvent();
}

class FetchTodayActiveOrdersEvent extends OrderEvent {
  final int page;
  final int limit;
  const FetchTodayActiveOrdersEvent({this.page = 1, this.limit = 10});
}

class FetchOrderDetailsEvent extends OrderEvent {
  final String uuId;
  const FetchOrderDetailsEvent(this.uuId);
}

class CancelOrderEvent extends OrderEvent {
  final String uuId;
  final String note;
  const CancelOrderEvent({required this.uuId, required this.note});
}
