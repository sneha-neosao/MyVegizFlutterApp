abstract class CategoryProductsEvent {}

class FetchProductsAndFiltersEvent extends CategoryProductsEvent {
  final String categorySlug;
  final String? subCategoryUuId;
  final double lat;
  final double lng;
  final bool resetFilters;

  FetchProductsAndFiltersEvent({
    required this.categorySlug,
    this.subCategoryUuId,
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
