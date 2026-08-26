import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/features/food_category/data/models/vendor_entity_category_model.dart';
import '../../../../core/utils/logger.dart';
import '../../data/domain/usecase/get_vendor_entity_categories_usecase.dart';
import '../../data/domain/usecase/get_vendor_entity_category_filters_usecase.dart';
import 'vendor_entity_category_event.dart';
import 'vendor_entity_category_state.dart';

class VendorEntityCategoryBloc
    extends Bloc<VendorEntityCategoryEvent, VendorEntityCategoryState> {
  final GetVendorEntityCategoriesUseCase getVendorEntityCategoriesUseCase;
  final GetVendorEntityCategoryFiltersUseCase getVendorEntityCategoryFiltersUseCase;

  VendorEntityCategoryBloc({
    required this.getVendorEntityCategoriesUseCase,
    required this.getVendorEntityCategoryFiltersUseCase,
  }) : super(VendorEntityCategoryState.initial()) {
    on<FetchVendorEntityCategoriesEvent>(_onFetchVendorEntityCategories);
    on<FetchVendorEntityCategoryFiltersEvent>(_onFetchVendorEntityCategoryFilters);
  }

  void _onFetchVendorEntityCategories(
    FetchVendorEntityCategoriesEvent event,
    Emitter<VendorEntityCategoryState> emit,
  ) async {
    emit(state.copyWith(isCategoriesLoading: true, categoriesError: null));

    List<VendorEntityCategoryData> allCategories =
        event.forceRefresh ? [] : List.from(state.categories);
    String? errorMessage;

    // 1. Fetch all categories ONLY if we don't have them yet or forceRefresh is true
    if (allCategories.isEmpty) {
      final categoriesResult = await getVendorEntityCategoriesUseCase(
        lat: event.lat,
        lng: event.lng,
        entityCategoryUuid: null,
      );

      categoriesResult.fold(
        (failure) {
          errorMessage = failure.message;
        },
        (response) {
          allCategories = response.data ?? [];
        },
      );

      if (errorMessage != null) {
        emit(
          state.copyWith(
            isCategoriesLoading: false,
            categoriesError: errorMessage,
          ),
        );
        return;
      }
    }

    // 2. If entityCategoryUuid is provided, fetch the vendors for that category
    if (event.entityCategoryUuid != null &&
        event.entityCategoryUuid!.isNotEmpty) {
      final vendorsResult = await getVendorEntityCategoriesUseCase(
        lat: event.lat,
        lng: event.lng,
        entityCategoryUuid: event.entityCategoryUuid,
        sortBy: event.sortBy,
        foodType: event.foodType,
      );

      vendorsResult.fold(
        (failure) {
          emit(
            state.copyWith(
              isCategoriesLoading: false,
              categories: allCategories,
              categoriesError: failure.message,
            ),
          );
        },
        (response) {
          final fetchedCategories = response.data ?? [];
          if (fetchedCategories.isNotEmpty) {
            final fetchedCategory = fetchedCategories.first;
            
            final index = allCategories.indexWhere(
              (cat) => cat.uuId == event.entityCategoryUuid,
            );
            if (index != -1) {
              allCategories[index] = fetchedCategory;
            } else {
              allCategories.add(fetchedCategory);
            }
          }
          emit(
            state.copyWith(
              isCategoriesLoading: false,
              categories: allCategories,
            ),
          );
        },
      );
    } else {
      emit(
        state.copyWith(isCategoriesLoading: false, categories: allCategories),
      );
    }
  }

  void _onFetchVendorEntityCategoryFilters(
    FetchVendorEntityCategoryFiltersEvent event,
    Emitter<VendorEntityCategoryState> emit,
  ) async {
    emit(state.copyWith(isFiltersLoading: true, filtersError: null));

    final result = await getVendorEntityCategoryFiltersUseCase();

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isFiltersLoading: false,
            filtersError: failure.message,
          ),
        );
      },
      (response) {
        emit(
          state.copyWith(
            isFiltersLoading: false,
            filters: response.data,
          ),
        );
      },
    );
  }
}
