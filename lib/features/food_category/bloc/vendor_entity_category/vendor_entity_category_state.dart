import '../../data/models/vendor_entity_category_model.dart';

class VendorEntityCategoryState {
  final bool isCategoriesLoading;
  final List<VendorEntityCategoryData> categories;
  final String? categoriesError;

  final bool isFiltersLoading;
  final VendorEntityCategoryFilterData? filters;
  final String? filtersError;

  VendorEntityCategoryState({
    required this.isCategoriesLoading,
    required this.categories,
    this.categoriesError,
    required this.isFiltersLoading,
    this.filters,
    this.filtersError,
  });

  factory VendorEntityCategoryState.initial() {
    return VendorEntityCategoryState(
      isCategoriesLoading: false,
      categories: [],
      categoriesError: null,
      isFiltersLoading: false,
      filters: null,
      filtersError: null,
    );
  }

  VendorEntityCategoryState copyWith({
    bool? isCategoriesLoading,
    List<VendorEntityCategoryData>? categories,
    String? categoriesError,
    bool? isFiltersLoading,
    VendorEntityCategoryFilterData? filters,
    String? filtersError,
  }) {
    return VendorEntityCategoryState(
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      categories: categories ?? this.categories,
      categoriesError: categoriesError ?? this.categoriesError,
      isFiltersLoading: isFiltersLoading ?? this.isFiltersLoading,
      filters: filters ?? this.filters,
      filtersError: filtersError ?? this.filtersError,
    );
  }
}

