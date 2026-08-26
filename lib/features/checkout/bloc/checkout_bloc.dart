import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repository/checkout_repo.dart';
import './checkout_event.dart';
import './checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CheckoutRepository repository;

  CheckoutBloc({required this.repository}) : super(CheckoutInitial()) {
    on<LoadCheckoutDataEvent>(_onLoadCheckoutData);
    on<PlaceOrderEvent>(_onPlaceOrder);
  }

  Future<void> _onLoadCheckoutData(
    LoadCheckoutDataEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    
    final slotsResult = await repository.getAvailableSlots();
    final settingsResult = await repository.getOrderSettings();

    slotsResult.fold(
      (failure) => emit(CheckoutError(failure.message)),
      (slots) {
        settingsResult.fold(
          (failure) => emit(CheckoutError(failure.message)),
          (settings) {
            emit(CheckoutLoaded(slots: slots, settings: settings));
          },
        );
      },
    );
  }

  Future<void> _onPlaceOrder(
    PlaceOrderEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    // Save current loaded state
    final currentState = state;
    
    emit(OrderPlacing());
    final result = await repository.placeOrder(
      paymentMode: event.paymentMode,
      addressUuid: event.addressUuid,
      slotUuid: event.slotUuid,
      customerNote: event.customerNote,
    );

    result.fold(
      (failure) {
        emit(OrderPlacedFailure(failure.message));
        // Restore previous state if possible so user can try again
        if (currentState is CheckoutLoaded) {
          emit(currentState);
        }
      },
      (response) => emit(OrderPlacedSuccess(response)),
    );
  }
}
