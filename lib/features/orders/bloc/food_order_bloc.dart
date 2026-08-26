import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecase/food_order_usecases.dart';
import 'food_order_event.dart';
import 'food_order_state.dart';

class FoodOrderBloc extends Bloc<FoodOrderEvent, FoodOrderState> {
  final GetFoodOrdersListUseCase getOrdersListUseCase;
  final GetFoodOrderDetailsUseCase getOrderDetailsUseCase;
  final PlaceFoodOrderUseCase placeOrderUseCase;
  final CancelFoodOrderUseCase cancelOrderUseCase;

  FoodOrderBloc({
    required this.getOrdersListUseCase,
    required this.getOrderDetailsUseCase,
    required this.placeOrderUseCase,
    required this.cancelOrderUseCase,
  }) : super(FoodOrderInitial()) {
    on<FetchFoodOrdersListEvent>(_onFetchOrdersList);
    on<FetchFoodOrderDetailsEvent>(_onFetchOrderDetails);
    on<PlaceFoodOrderEvent>(_onPlaceOrder);
    on<CancelFoodOrderEvent>(_onCancelOrder);
  }

  @override
  void onChange(Change<FoodOrderState> change) {
    super.onChange(change);
    debugPrint('===== FOOD ORDER BLOC =====');
    debugPrint('State Emitted: ${change.nextState}');
  }

  Future<void> _onFetchOrdersList(
    FetchFoodOrdersListEvent event,
    Emitter<FoodOrderState> emit,
  ) async {
    debugPrint('===== FOOD ORDER BLOC =====');
    debugPrint('Event Triggered: $event');
    emit(FoodOrderListLoading());
    final result = await getOrdersListUseCase.execute();
    result.fold(
      (failure) => emit(FoodOrderListError(failure.message)),
      (response) => emit(FoodOrderListLoaded(response.orders)),
    );
  }

  Future<void> _onFetchOrderDetails(
    FetchFoodOrderDetailsEvent event,
    Emitter<FoodOrderState> emit,
  ) async {
    debugPrint('===== FOOD ORDER BLOC =====');
    debugPrint('Event Triggered: $event');
    emit(FoodOrderDetailsLoading());
    final result = await getOrderDetailsUseCase.execute(event.uuId);
    result.fold(
      (failure) => emit(FoodOrderDetailsError(failure.message)),
      (details) => emit(FoodOrderDetailsLoaded(details)),
    );
  }

  Future<void> _onPlaceOrder(
    PlaceFoodOrderEvent event,
    Emitter<FoodOrderState> emit,
  ) async {
    debugPrint('===== FOOD ORDER BLOC =====');
    debugPrint('Event Triggered: $event');
    emit(FoodOrderPlacing());
    final result = await placeOrderUseCase.execute(
      vendorId: event.vendorId,
      customerUuid: event.customerUuid,
      addressUuid: event.addressUuid,
      couponCode: event.couponCode,
      applyWalletPoints: event.applyWalletPoints,
      paymentMode: event.paymentMode,
      customerNote: event.customerNote,
      items: event.items,
    );
    result.fold(
      (failure) => emit(FoodOrderPlacedFailure(failure.message)),
      (details) => emit(FoodOrderPlacedSuccess(details)),
    );
  }

  Future<void> _onCancelOrder(
    CancelFoodOrderEvent event,
    Emitter<FoodOrderState> emit,
  ) async {
    debugPrint('===== FOOD ORDER BLOC =====');
    debugPrint('Event Triggered: $event');
    emit(FoodOrderCancelling());
    final result = await cancelOrderUseCase.execute(event.uuId, event.note);
    result.fold(
      (failure) => emit(FoodOrderCancelError(failure.message)),
      (response) => emit(const FoodOrderCancelled("Order cancelled successfully")),
    );
  }
}
