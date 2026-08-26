import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/vendor_entity_category_model.dart';

abstract class VendorEntityCategoryRemoteDataSource {
  Future<VendorEntityCategoryResponse> fetchVendorEntityCategories({
    double? lat,
    double? lng,
    String? entityCategoryUuid,
    String? sortBy,
    String? foodType,
  });

  Future<VendorEntityCategoryFilterResponse> fetchVendorEntityCategoryFilters();
}

class VendorEntityCategoryRemoteDataSourceImpl
    implements VendorEntityCategoryRemoteDataSource {
  final ApiHelper apiHelper;

  VendorEntityCategoryRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<VendorEntityCategoryResponse> fetchVendorEntityCategories({
    double? lat,
    double? lng,
    String? entityCategoryUuid,
    String? sortBy,
    String? foodType,
  }) async {
    final String url;
    if (entityCategoryUuid != null && entityCategoryUuid.isNotEmpty) {
      url = ApiUrl.vendorEntityCategoryList(
        entityCategoryUuid: entityCategoryUuid,
        lat: lat ?? 0.0,
        lng: lng ?? 0.0,
        sortBy: sortBy,
        foodType: foodType,
      );
    } else {
      url = ApiUrl.vendorEntityCategoryCategoriesList;
    }

    final response = await apiHelper.execute(method: Method.get, url: url);
    return VendorEntityCategoryResponse.fromJson(response);
  }

  @override
  Future<VendorEntityCategoryFilterResponse>
  fetchVendorEntityCategoryFilters() async {
    final url = ApiUrl.vendorEntityCategoryFilters;
    final response = await apiHelper.execute(method: Method.get, url: url);
    return VendorEntityCategoryFilterResponse.fromJson(response);
  }
}
