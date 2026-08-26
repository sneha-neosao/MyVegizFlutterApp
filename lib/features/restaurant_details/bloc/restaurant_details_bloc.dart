import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../data/repository/restaurant_details_repository.dart';
import 'restaurant_details_event.dart';
import 'restaurant_details_state.dart';

class RestaurantDetailsBloc
    extends Bloc<RestaurantDetailsEvent, RestaurantDetailsState> {
  final RestaurantDetailsRepository repository;

  RestaurantDetailsBloc({
    required this.repository,
  }) : super(RestaurantDetailsState.initial()) {
    on<FetchVendorListEvent>(_onFetchVendorList);
    on<FetchVendorDetailsEvent>(_onFetchVendorDetails);
    on<FetchVendorItemDetailsEvent>(_onFetchVendorItemDetails);
    on<FetchVendorFiltersEvent>(_onFetchVendorFilters);
  }

  void _onFetchVendorList(
    FetchVendorListEvent event,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    emit(state.copyWith(
      isVendorListLoading: true,
      vendorListError: null,
      activeSortBy: event.sortBy,
      activeFoodType: event.foodType,
      clearSortBy: event.sortBy == null,
      clearFoodType: event.foodType == null,
    ));

    final result = await repository.getVendorList(
      limit: event.limit,
      page: event.page,
      vendorId: event.vendorId,
      lat: event.lat,
      lng: event.lng,
      sortBy: event.sortBy,
      foodType: event.foodType,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isVendorListLoading: false,
          vendorListError: failure.message,
        ));
      },
      (response) {
        emit(state.copyWith(
          isVendorListLoading: false,
          vendorResponse: response,
        ));
      },
    );
  }

  void _onFetchVendorDetails(
    FetchVendorDetailsEvent event,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    emit(state.copyWith(isVendorDetailsLoading: true, vendorDetailsError: null));

    final result = await repository.getVendorDetails(
      vendorId: event.vendorId,
      lat: event.lat,
      lng: event.lng,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isVendorDetailsLoading: false,
          vendorDetailsError: failure.message,
        ));
      },
      (response) {
        emit(state.copyWith(
          isVendorDetailsLoading: false,
          vendorDetailsResponse: response,
        ));
      },
    );
  }

  void _onFetchVendorItemDetails(
    FetchVendorItemDetailsEvent event,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    emit(state.copyWith(isItemDetailsLoading: true, itemDetailsError: null));

    final result = await repository.getVendorItemDetails(
      vendorItemId: event.vendorItemId,
      lat: event.lat,
      lng: event.lng,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isItemDetailsLoading: false,
          itemDetailsError: failure.message,
        ));
      },
      (response) {
        emit(state.copyWith(
          isItemDetailsLoading: false,
          itemDetailsResponse: response,
        ));
      },
    );
  }

  void _onFetchVendorFilters(
    FetchVendorFiltersEvent event,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    emit(state.copyWith(isFiltersLoading: true, filtersError: null));

    final result = await repository.getVendorFilters(vendorId: event.vendorId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isFiltersLoading: false,
          filtersError: failure.message,
        ));
      },
      (response) {
        emit(state.copyWith(
          isFiltersLoading: false,
          filtersData: response.data,
        ));
      },
    );
  }
}
