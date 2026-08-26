import '../data/models/vendor_list_model.dart';
import '../data/models/vendor_item_details_model.dart';
import '../data/models/vendor_details_model.dart';

class RestaurantDetailsState {
  final bool isVendorListLoading;
  final String? vendorListError;
  final VendorListResponse? vendorResponse;

  final bool isItemDetailsLoading;
  final String? itemDetailsError;
  final VendorItemDetailsResponse? itemDetailsResponse;

  final bool isVendorDetailsLoading;
  final String? vendorDetailsError;
  final VendorDetailsResponse? vendorDetailsResponse;

  final bool isFiltersLoading;
  final String? filtersError;
  final VendorFiltersData? filtersData;

  // Active filter selections
  final String? activeSortBy;
  final String? activeFoodType;

  RestaurantDetailsState({
    required this.isVendorListLoading,
    this.vendorListError,
    this.vendorResponse,
    required this.isItemDetailsLoading,
    this.itemDetailsError,
    this.itemDetailsResponse,
    required this.isVendorDetailsLoading,
    this.vendorDetailsError,
    this.vendorDetailsResponse,
    required this.isFiltersLoading,
    this.filtersError,
    this.filtersData,
    this.activeSortBy,
    this.activeFoodType,
  });

  factory RestaurantDetailsState.initial() {
    return RestaurantDetailsState(
      isVendorListLoading: false,
      vendorListError: null,
      vendorResponse: null,
      isItemDetailsLoading: false,
      itemDetailsError: null,
      itemDetailsResponse: null,
      isVendorDetailsLoading: false,
      vendorDetailsError: null,
      vendorDetailsResponse: null,
      isFiltersLoading: false,
      filtersError: null,
      filtersData: null,
      activeSortBy: null,
      activeFoodType: null,
    );
  }

  RestaurantDetailsState copyWith({
    bool? isVendorListLoading,
    String? vendorListError,
    VendorListResponse? vendorResponse,
    bool? isItemDetailsLoading,
    String? itemDetailsError,
    VendorItemDetailsResponse? itemDetailsResponse,
    bool? isVendorDetailsLoading,
    String? vendorDetailsError,
    VendorDetailsResponse? vendorDetailsResponse,
    bool? isFiltersLoading,
    String? filtersError,
    VendorFiltersData? filtersData,
    String? activeSortBy,
    String? activeFoodType,
    bool clearSortBy = false,
    bool clearFoodType = false,
  }) {
    return RestaurantDetailsState(
      isVendorListLoading: isVendorListLoading ?? this.isVendorListLoading,
      vendorListError: vendorListError ?? this.vendorListError,
      vendorResponse: vendorResponse ?? this.vendorResponse,
      isItemDetailsLoading: isItemDetailsLoading ?? this.isItemDetailsLoading,
      itemDetailsError: itemDetailsError ?? this.itemDetailsError,
      itemDetailsResponse: itemDetailsResponse ?? this.itemDetailsResponse,
      isVendorDetailsLoading: isVendorDetailsLoading ?? this.isVendorDetailsLoading,
      vendorDetailsError: vendorDetailsError ?? this.vendorDetailsError,
      vendorDetailsResponse: vendorDetailsResponse ?? this.vendorDetailsResponse,
      isFiltersLoading: isFiltersLoading ?? this.isFiltersLoading,
      filtersError: filtersError ?? this.filtersError,
      filtersData: filtersData ?? this.filtersData,
      activeSortBy: clearSortBy ? null : (activeSortBy ?? this.activeSortBy),
      activeFoodType: clearFoodType ? null : (activeFoodType ?? this.activeFoodType),
    );
  }
}
