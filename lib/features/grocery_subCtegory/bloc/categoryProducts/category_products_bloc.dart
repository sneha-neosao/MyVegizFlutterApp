import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/category_filters_model.dart';
import '../../data/models/homePage_model.dart';
import '../../usecases/get_category_products_usecase.dart';
import '../../usecases/get_category_filters_usecase.dart';
import '../../usecases/get_home_tab_sub_categories_usecase.dart';
import '../../usecases/get_sub_categories_by_category_usecase.dart';
import 'category_products_event.dart';
import 'category_products_state.dart';

class CategoryProductsBloc extends Bloc<CategoryProductsEvent, CategoryProductsState> {
  final GetCategoryProductsUseCase getCategoryProductsUseCase;
  final GetCategoryFiltersUseCase getCategoryFiltersUseCase;
  final GetHomeTabSubCategoriesUseCase getHomeTabSubCategoriesUseCase;
  final GetSubCategoriesByCategoryUseCase getSubCategoriesByCategoryUseCase;

  // Stored state for network calls
  int? _currentHomeTabId;
  String? _currentHomeTabUuId;
  String? _currentCategorySlug;
  String? _currentSearch;
  double? _currentLat;
  double? _currentLng;

  CategoryProductsBloc({
    required this.getCategoryProductsUseCase,
    required this.getCategoryFiltersUseCase,
    required this.getHomeTabSubCategoriesUseCase,
    required this.getSubCategoriesByCategoryUseCase,
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
    if (event.homeTabId != null) _currentHomeTabId = event.homeTabId;
    if (event.homeTabUuId != null) _currentHomeTabUuId = event.homeTabUuId;
    if (event.categorySlug != null) _currentCategorySlug = event.categorySlug;
    if (event.search != null) _currentSearch = event.search;
    _currentLat = event.lat;
    _currentLng = event.lng;

    emit(CategoryProductsLoading());

    // 1. If homeTabUuId is provided, fetch sub-categories using the home_tabs/sub-categories API
    if (event.homeTabUuId != null && event.homeTabUuId!.isNotEmpty) {
      final subCatsResult = await getHomeTabSubCategoriesUseCase.call(
        homeTabUuId: event.homeTabUuId!,
        page: 1,
        limit: 100,
      );

      await subCatsResult.fold(
        (failure) async {
          logger.e("📦 HomeTabSubCategories error: ${failure.message}");
          if (event.categorySlug != null && event.categorySlug!.isNotEmpty) {
            await _fetchUsingCategorySlug(event, emit);
          } else {
            emit(CategoryProductsError(failure.message));
          }
        },
        (subCatsData) async {
          final subCatsList = subCatsData.data;

          if (subCatsList.isEmpty && event.categorySlug != null && event.categorySlug!.isNotEmpty) {
            await _fetchUsingCategorySlug(event, emit);
            return;
          }

          final String targetSubUuid = (event.resetFilters || event.subCategoryUuId == null || event.subCategoryUuId!.isEmpty)
              ? 'all'
              : event.subCategoryUuId!;

          final filterOptions = subCatsList
              .map((s) => FilterOption(key: s.uuId, label: s.subCategoryName))
              .toList();

          final bool isAllSelected = targetSubUuid == 'all';

          // Home Tab flow: Call grocery-products/list-with-variants
          // When 'all' is selected: send homeTabId (and not subCategoryUuId)
          // When a specific subcategory is selected: send only subCategoryUuId
          final productsResult = await getCategoryProductsUseCase(
            lat: event.lat,
            lng: event.lng,
            subCategoryUuId: isAllSelected ? '' : targetSubUuid,
            homeTabId: isAllSelected ? (_currentHomeTabId ?? event.homeTabId) : null,
            categorySlug: null,
            search: null,
            page: 1,
            limit: 100,
          );

          productsResult.fold(
            (failure) {
              logger.w("📦 CategoryProducts notice: ${failure.message}");
              emit(CategoryProductsLoaded(
                categoryProductsResponse: CategoryProductsResponse(
                  status: 300,
                  message: failure.message,
                  products: [],
                ),
                categoryFiltersResponse: CategoryFiltersResponse(
                  status: 200,
                  message: '',
                  data: CategoryFiltersData(
                    subCategories: filterOptions,
                    sortOptions: [],
                    tags: [],
                  ),
                ),
                homeTabSubCategories: subCatsList,
                subCategoriesByCategory: null,
                selectedSubCategoryUuId: targetSubUuid.isNotEmpty ? targetSubUuid : null,
                selectedTagUuId: null,
                selectedSortBy: null,
                isProductsLoading: false,
              ));
            },
            (productsData) {
              emit(CategoryProductsLoaded(
                categoryProductsResponse: productsData,
                categoryFiltersResponse: CategoryFiltersResponse(
                  status: 200,
                  message: '',
                  data: CategoryFiltersData(
                    subCategories: filterOptions,
                    sortOptions: [],
                    tags: [],
                  ),
                ),
                homeTabSubCategories: subCatsList,
                subCategoriesByCategory: null,
                selectedSubCategoryUuId: targetSubUuid.isNotEmpty ? targetSubUuid : null,
                selectedTagUuId: null,
                selectedSortBy: null,
                isProductsLoading: false,
              ));
            },
          );
        },
      );
    } else if (event.categorySlug != null && event.categorySlug!.isNotEmpty) {
      // 2. Tapped on Category circle from Home sections / category page: fetch sub-categories by category slug
      await _fetchUsingCategorySlug(event, emit);
    } else {
      final targetSubUuid = event.subCategoryUuId ?? '';
      final productsResult = await getCategoryProductsUseCase(
        lat: event.lat,
        lng: event.lng,
        subCategoryUuId: targetSubUuid,
        homeTabId: event.homeTabId,
        categorySlug: event.categorySlug,
        search: event.search,
      );

      productsResult.fold(
        (failure) {
          logger.e("📦 CategoryProducts error: ${failure.message}");
          emit(CategoryProductsError(failure.message));
        },
        (productsData) {
          emit(CategoryProductsLoaded(
            categoryProductsResponse: productsData,
            categoryFiltersResponse: CategoryFiltersResponse(status: 200, message: '', data: null),
            selectedSubCategoryUuId: targetSubUuid.isNotEmpty ? targetSubUuid : null,
            selectedTagUuId: null,
            selectedSortBy: null,
            isProductsLoading: false,
          ));
        },
      );
    }
  }

  Future<void> _fetchUsingCategorySlug(
    FetchProductsAndFiltersEvent event,
    Emitter<CategoryProductsState> emit,
  ) async {
    final subCatsResult = await getSubCategoriesByCategoryUseCase.call(
      categorySlug: event.categorySlug!,
      page: 1,
      limit: 100,
    );

    await subCatsResult.fold(
      (failure) async {
        logger.e("📦 SubCategoriesByCategory error: ${failure.message}");
        final filtersResult = await getCategoryFiltersUseCase(categorySlug: event.categorySlug!);

        await filtersResult.fold(
          (filterFailure) async {
            logger.e("📦 CategoryFilters error: ${filterFailure.message}");
            emit(CategoryProductsError(failure.message));
          },
          (filtersData) async {
            final String targetSubUuid = (event.resetFilters || event.subCategoryUuId == null || event.subCategoryUuId!.isEmpty)
                ? 'all'
                : event.subCategoryUuId!;

            final bool isAllSelected = targetSubUuid == 'all';
            final productsResult = await getCategoryProductsUseCase(
              lat: event.lat,
              lng: event.lng,
              subCategoryUuId: isAllSelected ? '' : targetSubUuid,
              homeTabId: null,
              categorySlug: isAllSelected ? event.categorySlug : null,
              search: null,
              page: 1,
              limit: 100,
            );

            productsResult.fold(
              (prodFailure) {
                logger.w("📦 CategoryProducts notice: ${prodFailure.message}");
                emit(CategoryProductsLoaded(
                  categoryProductsResponse: CategoryProductsResponse(
                    status: 300,
                    message: prodFailure.message,
                    products: [],
                  ),
                  categoryFiltersResponse: filtersData,
                  selectedSubCategoryUuId: targetSubUuid.isNotEmpty ? targetSubUuid : null,
                  selectedTagUuId: null,
                  selectedSortBy: null,
                  isProductsLoading: false,
                ));
              },
              (productsData) {
                emit(CategoryProductsLoaded(
                  categoryProductsResponse: productsData,
                  categoryFiltersResponse: filtersData,
                  selectedSubCategoryUuId: targetSubUuid.isNotEmpty ? targetSubUuid : null,
                  selectedTagUuId: null,
                  selectedSortBy: null,
                  isProductsLoading: false,
                ));
              },
            );
          },
        );
      },
      (subCatsData) async {
        final subCatsList = subCatsData.data;
        final firstSub = subCatsList.isNotEmpty ? subCatsList.first : null;
        final String firstSubKey = firstSub != null
            ? (firstSub.subCategoryUuid != null && firstSub.subCategoryUuid!.isNotEmpty
                ? firstSub.subCategoryUuid!
                : firstSub.uuId)
            : '';
        final String effectiveCatSlug = (firstSub?.categorySlug != null && firstSub!.categorySlug!.isNotEmpty)
            ? firstSub.categorySlug!
            : (event.categorySlug ?? '');

        _currentCategorySlug = effectiveCatSlug.isNotEmpty ? effectiveCatSlug : _currentCategorySlug;

        final String targetSubUuid = (event.resetFilters || event.subCategoryUuId == null || event.subCategoryUuId!.isEmpty)
            ? 'all'
            : event.subCategoryUuId!;

        final filterOptions = subCatsList
            .map((s) => FilterOption(
                  key: (s.subCategoryUuid != null && s.subCategoryUuid!.isNotEmpty) ? s.subCategoryUuid! : s.uuId,
                  label: s.subCategoryName,
                ))
            .toList();

        final bool isAllSelected = targetSubUuid == 'all';
        // Category Subcategory flow: Call grocery-products/list-with-variants
        // When 'all' is selected: send categorySlug (and not subCategoryUuId)
        // When a specific subcategory is selected: send only subCategoryUuId
        final productsResult = await getCategoryProductsUseCase(
          lat: event.lat,
          lng: event.lng,
          subCategoryUuId: isAllSelected ? '' : targetSubUuid,
          homeTabId: null,
          categorySlug: isAllSelected ? effectiveCatSlug : null,
          search: null,
          page: 1,
          limit: 100,
        );

        productsResult.fold(
          (failure) {
            logger.w("📦 CategoryProducts notice: ${failure.message}");
            emit(CategoryProductsLoaded(
              categoryProductsResponse: CategoryProductsResponse(
                status: 300,
                message: failure.message,
                products: [],
              ),
              categoryFiltersResponse: CategoryFiltersResponse(
                status: 200,
                message: '',
                data: CategoryFiltersData(
                  subCategories: filterOptions,
                  sortOptions: [],
                  tags: [],
                ),
              ),
              subCategoriesByCategory: subCatsList,
              homeTabSubCategories: null,
              selectedSubCategoryUuId: targetSubUuid.isNotEmpty ? targetSubUuid : null,
              selectedTagUuId: null,
              selectedSortBy: null,
              isProductsLoading: false,
            ));
          },
          (productsData) {
            emit(CategoryProductsLoaded(
              categoryProductsResponse: productsData,
              categoryFiltersResponse: CategoryFiltersResponse(
                status: 200,
                message: '',
                data: CategoryFiltersData(
                  subCategories: filterOptions,
                  sortOptions: [],
                  tags: [],
                ),
              ),
              subCategoriesByCategory: subCatsList,
              homeTabSubCategories: null,
              selectedSubCategoryUuId: targetSubUuid.isNotEmpty ? targetSubUuid : null,
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
    if (_currentLat == null || _currentLng == null) {
      return;
    }

    final latestState = state is CategoryProductsLoaded ? (state as CategoryProductsLoaded) : currentState;

    // Determine the parameters to use, defaulting to the latest state value
    final String subId = subCategoryUuId ?? latestState.selectedSubCategoryUuId ?? '';
    final String? tagId = tagUuId ?? latestState.selectedTagUuId;
    final String? sort = latestState.selectedSortBy;

    final bool isAllSelected = subId == 'all';
    final bool isHomeTabFlow = _currentHomeTabUuId != null && _currentHomeTabUuId!.isNotEmpty;

    // Resolve categorySlug if subCategoriesByCategory is present
    String? effectiveCategorySlug = _currentCategorySlug;
    if (latestState.subCategoriesByCategory != null && latestState.subCategoriesByCategory!.isNotEmpty) {
      final matchingSub = latestState.subCategoriesByCategory!.firstWhere(
        (s) => s.uuId == subId || s.subCategoryUuid == subId,
        orElse: () => latestState.subCategoriesByCategory!.first,
      );
      if (matchingSub.categorySlug != null && matchingSub.categorySlug!.isNotEmpty) {
        effectiveCategorySlug = matchingSub.categorySlug;
      }
    }

    final int? sendHomeTabId = (isHomeTabFlow && isAllSelected) ? _currentHomeTabId : null;
    final String? sendCategorySlug = (!isHomeTabFlow && isAllSelected) ? effectiveCategorySlug : null;
    final String sendSubCategoryUuid = isAllSelected ? '' : subId;

    final result = await getCategoryProductsUseCase(
      lat: _currentLat!,
      lng: _currentLng!,
      subCategoryUuId: sendSubCategoryUuid,
      homeTabId: sendHomeTabId,
      categorySlug: sendCategorySlug,
      search: null,
      tagUuId: tagId,
      sortBy: sort,
      page: 1,
      limit: 100,
    );

    result.fold(
      (failure) {
        logger.w("📦 CategoryProducts filter notice: ${failure.message}");
        final latestState = state;
        if (latestState is CategoryProductsLoaded) {
          emit(latestState.copyWith(
            categoryProductsResponse: CategoryProductsResponse(
              status: 300,
              message: failure.message,
              products: [],
            ),
            isProductsLoading: false,
          ));
        } else {
          emit(CategoryProductsError(failure.message));
        }
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
