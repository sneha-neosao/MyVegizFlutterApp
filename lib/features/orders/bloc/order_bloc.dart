import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repository/grocery_order_repo.dart';
import './order_event.dart';
import './order_state.dart';

class GroceryOrderBloc extends Bloc<OrderEvent, OrderState> {
  final GroceryOrderRepository repository;

  GroceryOrderBloc({required this.repository}) : super(OrderInitial()) {
    on<FetchOrdersListEvent>(_onFetchOrdersList);
    on<FetchTodayActiveOrdersEvent>(_onFetchTodayActiveOrders);
    on<FetchOrderDetailsEvent>(_onFetchOrderDetails);
    on<CancelOrderEvent>(_onCancelOrder);
  }

  Future<void> _onFetchOrdersList(
    FetchOrdersListEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderListLoading());
    final result = await repository.getOrdersList();
    result.fold(
      (failure) => emit(OrderListError(failure.message)),
      (response) => emit(OrderListLoaded(response.orders)),
    );
  }

  Future<void> _onFetchTodayActiveOrders(
    FetchTodayActiveOrdersEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(TodayActiveOrdersLoading());
    final result = await repository.getTodayActiveOrders(
      page: event.page,
      limit: event.limit,
    );
    result.fold(
      (failure) => emit(TodayActiveOrdersError(failure.message)),
      (response) => emit(TodayActiveOrdersLoaded(response)),
    );
  }

  Future<void> _onFetchOrderDetails(
    FetchOrderDetailsEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderDetailsLoading());
    final result = await repository.getOrderDetails(event.uuId);
    result.fold(
      (failure) => emit(OrderDetailsError(failure.message)),
      (details) => emit(OrderDetailsLoaded(details)),
    );
  }

  Future<void> _onCancelOrder(
    CancelOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderCancelling());
    final result = await repository.cancelOrder(event.uuId, event.note);
    result.fold(
      (failure) => emit(OrderCancelError(failure.message)),
      (response) => emit(OrderCancelled("Order cancelled successfully")),
    );
  }
}
