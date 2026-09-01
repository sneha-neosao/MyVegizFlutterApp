import '../../data/models/homePage_model.dart';
import '../../data/models/category_filters_model.dart';
import '../../data/models/home_tab_sub_categories_model.dart';
import '../../data/models/sub_categories_by_category_model.dart';

abstract class CategoryProductsState {}

class CategoryProductsInitial extends CategoryProductsState {}

class CategoryProductsLoading extends CategoryProductsState {}

class CategoryProductsLoaded extends CategoryProductsState {
  final CategoryProductsResponse categoryProductsResponse;
  final CategoryFiltersResponse categoryFiltersResponse;
  final List<HomeTabSubCategoryItemModel>? homeTabSubCategories;
  final List<SubCategoryByCategoryItemModel>? subCategoriesByCategory;
  final String? selectedSubCategoryUuId;
  final String? selectedTagUuId;
  final String? selectedSortBy;
  final bool isProductsLoading;

  CategoryProductsLoaded({
    required this.categoryProductsResponse,
    required this.categoryFiltersResponse,
    this.homeTabSubCategories,
    this.subCategoriesByCategory,
    this.selectedSubCategoryUuId,
    this.selectedTagUuId,
    this.selectedSortBy,
    this.isProductsLoading = false,
  });

  CategoryProductsLoaded copyWith({
    CategoryProductsResponse? categoryProductsResponse,
    CategoryFiltersResponse? categoryFiltersResponse,
    List<HomeTabSubCategoryItemModel>? homeTabSubCategories,
    List<SubCategoryByCategoryItemModel>? subCategoriesByCategory,
    String? selectedSubCategoryUuId,
    bool clearSubCategory = false,
    String? selectedTagUuId,
    bool clearTag = false,
    String? selectedSortBy,
    bool clearSortBy = false,
    bool? isProductsLoading,
  }) {
    return CategoryProductsLoaded(
      categoryProductsResponse: categoryProductsResponse ?? this.categoryProductsResponse,
      categoryFiltersResponse: categoryFiltersResponse ?? this.categoryFiltersResponse,
      homeTabSubCategories: homeTabSubCategories ?? this.homeTabSubCategories,
      subCategoriesByCategory: subCategoriesByCategory ?? this.subCategoriesByCategory,
      selectedSubCategoryUuId: clearSubCategory ? null : (selectedSubCategoryUuId ?? this.selectedSubCategoryUuId),
      selectedTagUuId: clearTag ? null : (selectedTagUuId ?? this.selectedTagUuId),
      selectedSortBy: clearSortBy ? null : (selectedSortBy ?? this.selectedSortBy),
      isProductsLoading: isProductsLoading ?? this.isProductsLoading,
    );
  }
}

class CategoryProductsError extends CategoryProductsState {
  final String message;

  CategoryProductsError(this.message);
}
