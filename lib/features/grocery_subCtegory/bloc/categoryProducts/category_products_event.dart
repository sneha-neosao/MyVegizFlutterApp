abstract class CategoryProductsEvent {}

class FetchProductsAndFiltersEvent extends CategoryProductsEvent {
  final int? homeTabId;
  final String? homeTabUuId;
  final String? categorySlug;
  final String? subCategoryUuId;
  final String? search;
  final double lat;
  final double lng;
  final bool resetFilters;

  FetchProductsAndFiltersEvent({
    this.homeTabId,
    this.homeTabUuId,
    this.categorySlug,
    this.subCategoryUuId,
    this.search,
    required this.lat,
    required this.lng,
    this.resetFilters = false,
  });
}

class FilterSubCategoryChangedEvent extends CategoryProductsEvent {
  final String? subCategoryUuId;

  FilterSubCategoryChangedEvent(this.subCategoryUuId);
}

class FilterTagChangedEvent extends CategoryProductsEvent {
  final String? tagUuId;

  FilterTagChangedEvent(this.tagUuId);
}

class FilterSortChangedEvent extends CategoryProductsEvent {
  final String? sortBy;

  FilterSortChangedEvent(this.sortBy);
}
