import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecase/food_rating_usecases.dart';
import 'food_rating_event.dart';
import 'food_rating_state.dart';

class FoodRatingBloc extends Bloc<FoodRatingEvent, FoodRatingState> {
  final SubmitFoodVendorRatingUseCase submitVendorRatingUseCase;
  final SubmitFoodItemRatingsUseCase submitItemRatingsUseCase;
  final SubmitFoodDeliveryRatingUseCase submitDeliveryRatingUseCase;
  final FetchFoodOrderRatingsUseCase fetchOrderRatingsUseCase;

  FoodRatingBloc({
    required this.submitVendorRatingUseCase,
    required this.submitItemRatingsUseCase,
    required this.submitDeliveryRatingUseCase,
    required this.fetchOrderRatingsUseCase,
  }) : super(FoodRatingInitial()) {
    on<FetchFoodOrderRatingsEvent>(_onFetchOrderRatings);
    on<SubmitFoodVendorRatingEvent>(_onSubmitVendorRating);
    on<SubmitFoodItemRatingsEvent>(_onSubmitItemRatings);
    on<SubmitFoodDeliveryRatingEvent>(_onSubmitDeliveryRating);
  }

  @override
  void onChange(Change<FoodRatingState> change) {
    super.onChange(change);
    debugPrint('===== FOOD RATING BLOC =====');
    debugPrint('State Emitted: ${change.nextState}');
  }

  Future<void> _onFetchOrderRatings(
    FetchFoodOrderRatingsEvent event,
    Emitter<FoodRatingState> emit,
  ) async {
    debugPrint('===== FOOD RATING BLOC =====');
    debugPrint('Event Triggered: $event');
    emit(FoodRatingLoading());
    final result = await fetchOrderRatingsUseCase.execute(event.orderUuId);
    result.fold(
      (failure) => emit(FoodOrderRatingsError(failure.message)),
      (ratings) => emit(FoodOrderRatingsLoaded(ratings)),
    );
  }

  Future<void> _onSubmitVendorRating(
    SubmitFoodVendorRatingEvent event,
    Emitter<FoodRatingState> emit,
  ) async {
    debugPrint('===== FOOD RATING BLOC =====');
    debugPrint('Event Triggered: $event');
    emit(FoodRatingSubmitting());
    final result = await submitVendorRatingUseCase.execute(
      event.orderUuId,
      event.rating,
      event.review,
    );
    result.fold(
      (failure) => emit(FoodRatingSubmitError(failure.message)),
      (_) => emit(FoodRatingSubmitSuccess()),
    );
  }

  Future<void> _onSubmitItemRatings(
    SubmitFoodItemRatingsEvent event,
    Emitter<FoodRatingState> emit,
  ) async {
    debugPrint('===== FOOD RATING BLOC =====');
    debugPrint('Event Triggered: $event');
    emit(FoodRatingSubmitting());
    final result = await submitItemRatingsUseCase.execute(
      event.orderUuId,
      event.ratings,
    );
    result.fold(
      (failure) => emit(FoodRatingSubmitError(failure.message)),
      (_) => emit(FoodRatingSubmitSuccess()),
    );
  }

  Future<void> _onSubmitDeliveryRating(
    SubmitFoodDeliveryRatingEvent event,
    Emitter<FoodRatingState> emit,
  ) async {
    debugPrint('===== FOOD RATING BLOC =====');
    debugPrint('Event Triggered: $event');
    emit(FoodRatingSubmitting());
    final result = await submitDeliveryRatingUseCase.execute(
      event.orderUuId,
      event.rating,
      event.review,
    );
    result.fold(
      (failure) => emit(FoodRatingSubmitError(failure.message)),
      (_) => emit(FoodRatingSubmitSuccess()),
    );
  }
}
