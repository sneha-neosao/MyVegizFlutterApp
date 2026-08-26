abstract class RestaurantDetailsEvent {}

class FetchVendorListEvent extends RestaurantDetailsEvent {
  final int vendorId;
  final int limit;
  final int page;
  final double? lat;
  final double? lng;
  final String? sortBy;
  final String? foodType;

  FetchVendorListEvent({
    required this.vendorId,
    this.limit = 50,
    this.page = 1,
    this.lat,
    this.lng,
    this.sortBy,
    this.foodType,
  });
}

class FetchVendorItemDetailsEvent extends RestaurantDetailsEvent {
  final int vendorItemId;
  final double? lat;
  final double? lng;

  FetchVendorItemDetailsEvent({
    required this.vendorItemId,
    this.lat,
    this.lng,
  });
}

class FetchVendorDetailsEvent extends RestaurantDetailsEvent {
  final int vendorId;
  final double? lat;
  final double? lng;

  FetchVendorDetailsEvent({
    required this.vendorId,
    this.lat,
    this.lng,
  });
}

class FetchVendorFiltersEvent extends RestaurantDetailsEvent {
  final int vendorId;

  FetchVendorFiltersEvent({required this.vendorId});
}
