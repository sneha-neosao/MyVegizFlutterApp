import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../usecases/get_category_products_usecase.dart';
import '../../usecases/get_category_filters_usecase.dart';
import 'category_products_event.dart';
import 'category_products_state.dart';

class CategoryProductsBloc extends Bloc<CategoryProductsEvent, CategoryProductsState> {
  final GetCategoryProductsUseCase getCategoryProductsUseCase;
  final GetCategoryFiltersUseCase getCategoryFiltersUseCase;

  // Stored state for network calls
  String? _currentCategorySlug;
  double? _currentLat;
  double? _currentLng;

  CategoryProductsBloc({
    required this.getCategoryProductsUseCase,
    required this.getCategoryFiltersUseCase,
  }) : super(CategoryProductsInitial()) {
    on<FetchProductsAndFiltersEvent>(_onFetchProductsAndFilters);
    on<FilterSubCategoryChangedEvent>(_onFilterSubCategoryChanged);
    on<FilterTagChangedEvent>(_onFilterTagChanged);
    on<FilterSortChangedEvent>(_onFilterSortChanged);
  }

  void _onFetchProductsAndFilters(
    FetchProductsAndFiltersEvent event,
    Emitter<CategoryProductsState> emit,
  ) async {
    // logger.i("📦 CategoryProductsBloc: Fetching products & filters for ${event.categorySlug}");
    
    _currentCategorySlug = event.categorySlug;
    _currentLat = event.lat;
    _currentLng = event.lng;

    emit(CategoryProductsLoading());

    final filtersResult = await getCategoryFiltersUseCase(categorySlug: event.categorySlug);

    await filtersResult.fold(
      (failure) async {
        logger.e("📦 CategoryFilters error: ${failure.message}");
        emit(CategoryProductsError(failure.message));
      },
      (filtersData) async {
        final subCats = filtersData.data?.subCategories ?? [];
        final defaultSubUuid = subCats.isNotEmpty ? subCats.first.key : null;

        final productsResult = await getCategoryProductsUseCase(
          lat: event.lat,
          lng: event.lng,
          categorySlug: event.categorySlug,
          subCategoryUuId: defaultSubUuid,
        );

        productsResult.fold(
          (failure) {
            logger.e("📦 CategoryProducts error: ${failure.message}");
            emit(CategoryProductsError(failure.message));
          },
          (productsData) {
            emit(CategoryProductsLoaded(
              categoryProductsResponse: productsData,
              categoryFiltersResponse: filtersData,
              selectedSubCategoryUuId: defaultSubUuid,
              selectedTagUuId: null,
              selectedSortBy: null,
              isProductsLoading: false,
            ));
          },
        );
      },
    );
  }

  void _onFilterSubCategoryChanged(
    FilterSubCategoryChangedEvent event,
    Emitter<CategoryProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoryProductsLoaded) {
      final newSubCategoryUuId = event.subCategoryUuId;
      emit(currentState.copyWith(
        selectedSubCategoryUuId: newSubCategoryUuId,
        clearSubCategory: newSubCategoryUuId == null,
        isProductsLoading: true,
      ));

      await _fetchProductsOnly(emit, currentState, subCategoryUuId: newSubCategoryUuId);
    }
  }

  void _onFilterTagChanged(
    FilterTagChangedEvent event,
    Emitter<CategoryProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoryProductsLoaded) {
      final newTagUuId = event.tagUuId;
      emit(currentState.copyWith(
        selectedTagUuId: newTagUuId,
        clearTag: newTagUuId == null,
        isProductsLoading: true,
      ));

      await _fetchProductsOnly(emit, currentState, tagUuId: newTagUuId);
    }
  }

  void _onFilterSortChanged(
    FilterSortChangedEvent event,
    Emitter<CategoryProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoryProductsLoaded) {
      final newSortBy = event.sortBy;
      emit(currentState.copyWith(
        selectedSortBy: newSortBy,
        clearSortBy: newSortBy == null,
        isProductsLoading: true,
      ));

      await _fetchProductsOnly(emit, currentState, sortBy: newSortBy);
    }
  }

  Future<void> _fetchProductsOnly(
    Emitter<CategoryProductsState> emit,
    CategoryProductsLoaded currentState, {
    String? subCategoryUuId,
    String? tagUuId,
    String? sortBy,
  }) async {
    if (_currentCategorySlug == null || _currentLat == null || _currentLng == null) {
      return;
    }

    // Determine the parameters to use, defaulting to the current state value if not provided
    final String? subId = subCategoryUuId ?? currentState.selectedSubCategoryUuId;
    final String? tagId = tagUuId ?? currentState.selectedTagUuId;
    final String? sort = sortBy ?? currentState.selectedSortBy;

    // logger.i("📦 CategoryProductsBloc: Fetching products only (subCategory: $subId, tag: $tagId, sort: $sort)");

    final result = await getCategoryProductsUseCase(
      lat: _currentLat!,
      lng: _currentLng!,
      categorySlug: _currentCategorySlug!,
      subCategoryUuId: subId,
      tagUuId: tagId,
      sortBy: sort,
    );

    result.fold(
      (failure) {
        logger.e("📦 CategoryProducts filter error: ${failure.message}");
        emit(CategoryProductsError(failure.message));
      },
      (newData) {
        // Since state could have updated (e.g. user double clicked), make sure we keep the latest options/selections
        final latestState = state;
        if (latestState is CategoryProductsLoaded) {
          emit(latestState.copyWith(
            categoryProductsResponse: newData,
            isProductsLoading: false,
          ));
        }
      },
    );
  }
}
