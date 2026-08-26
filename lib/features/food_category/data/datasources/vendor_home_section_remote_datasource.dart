import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/vendor_home_section_model.dart';

abstract class VendorHomeSectionRemoteDataSource {
  Future<VendorHomeSectionResponse> fetchVendorHomeSections({
    required double lat,
    required double lng,
    String? sortBy,
    String? foodType,
  });

  Future<VendorHomeSectionFiltersResponse> fetchVendorHomeSectionFilters();
}

class VendorHomeSectionRemoteDataSourceImpl implements VendorHomeSectionRemoteDataSource {
  final ApiHelper apiHelper;

  VendorHomeSectionRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<VendorHomeSectionResponse> fetchVendorHomeSections({
    required double lat,
    required double lng,
    String? sortBy,
    String? foodType,
  }) async {
    String url = "${ApiUrl.baseUrl}/web/vendor_home_sections/list?lat=$lat&lng=$lng";
    if (sortBy != null && sortBy.isNotEmpty) {
      url += "&sort_by=$sortBy";
    }
    if (foodType != null && foodType.isNotEmpty) {
      url += "&food_type=$foodType";
    } else {
      url += "&food_type=both";
    }

    logger.i("🌐 API CALL → VendorHomeSectionList with lat=$lat, lng=$lng, sortBy=$sortBy, foodType=$foodType");
    logger.d("URL: $url");

    final response = await apiHelper.execute(method: Method.get, url: url);

    logger.i("📡 API RESPONSE → VendorHomeSectionList success");
    return VendorHomeSectionResponse.fromJson(response);
  }

  @override
  Future<VendorHomeSectionFiltersResponse> fetchVendorHomeSectionFilters() async {
    final String url = "${ApiUrl.baseUrl}/web/vendor_home_sections/filters";
    logger.i("🌐 API CALL → VendorHomeSectionFilters");
    logger.d("URL: $url");

    final response = await apiHelper.execute(method: Method.get, url: url);

    logger.i("📡 API RESPONSE → VendorHomeSectionFilters success");
    return VendorHomeSectionFiltersResponse.fromJson(response);
  }
}
