import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/location_service.dart';
import '../models/vendor_list_model.dart';
import '../models/vendor_item_details_model.dart';
import '../models/vendor_details_model.dart';

abstract class RestaurantDetailsRemoteDataSource {
  Future<VendorListResponse> fetchVendorList({
    required int limit,
    required int page,
    required int vendorId,
    double? lat,
    double? lng,
    String? sortBy,
    String? foodType,
  });

  Future<VendorDetailsResponse> fetchVendorDetails({
    required int vendorId,
    double? lat,
    double? lng,
  });

  Future<VendorItemDetailsResponse> fetchVendorItemDetails({
    required int vendorItemId,
    double? lat,
    double? lng,
  });

  Future<VendorFiltersResponse> fetchVendorFilters({
    required int vendorId,
  });
}

class RestaurantDetailsRemoteDataSourceImpl
    implements RestaurantDetailsRemoteDataSource {
  final ApiHelper apiHelper;

  RestaurantDetailsRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<VendorListResponse> fetchVendorList({
    required int limit,
    required int page,
    required int vendorId,
    double? lat,
    double? lng,
    String? sortBy,
    String? foodType,
  }) async {
    final double finalLat = lat ?? locationService.locationNotifier.value?.lat ?? 0.0;
    final double finalLng = lng ?? locationService.locationNotifier.value?.lng ?? 0.0;
    final url = ApiUrl.webVendorsList(
      limit: limit,
      page: page,
      vendorId: vendorId,
      lat: finalLat,
      lng: finalLng,
      sortBy: sortBy,
      foodType: foodType,
    );

    final response = await apiHelper.execute(method: Method.get, url: url);
    return VendorListResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<VendorDetailsResponse> fetchVendorDetails({
    required int vendorId,
    double? lat,
    double? lng,
  }) async {
    final double finalLat = lat ?? locationService.locationNotifier.value?.lat ?? 0.0;
    final double finalLng = lng ?? locationService.locationNotifier.value?.lng ?? 0.0;
    final url = ApiUrl.webVendorDetails(
      vendorId: vendorId,
      lat: finalLat,
      lng: finalLng,
    );

    final response = await apiHelper.execute(method: Method.get, url: url);
    return VendorDetailsResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<VendorItemDetailsResponse> fetchVendorItemDetails({
    required int vendorItemId,
    double? lat,
    double? lng,
  }) async {
    final double finalLat = lat ?? locationService.locationNotifier.value?.lat ?? 0.0;
    final double finalLng = lng ?? locationService.locationNotifier.value?.lng ?? 0.0;
    final url = ApiUrl.webVendorItemDetails(
      vendorItemId,
      lat: finalLat,
      lng: finalLng,
    );

    final response = await apiHelper.execute(method: Method.get, url: url);
    return VendorItemDetailsResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<VendorFiltersResponse> fetchVendorFilters({
    required int vendorId,
  }) async {
    final url = ApiUrl.webVendorFilters(vendorId: vendorId);
    final response = await apiHelper.execute(method: Method.get, url: url);
    return VendorFiltersResponse.fromJson(response as Map<String, dynamic>);
  }
}
