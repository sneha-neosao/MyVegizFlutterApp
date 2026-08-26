abstract class VendorEntityCategoryEvent {}

class FetchVendorEntityCategoriesEvent extends VendorEntityCategoryEvent {
  final double? lat;
  final double? lng;
  final String? entityCategoryUuid;
  final String? sortBy;
  final String? foodType;
  final bool forceRefresh;

  FetchVendorEntityCategoriesEvent({
    this.lat,
    this.lng,
    this.entityCategoryUuid,
    this.sortBy,
    this.foodType,
    this.forceRefresh = false,
  });
}

class FetchVendorEntityCategoryFiltersEvent extends VendorEntityCategoryEvent {}

