import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/vendor_banner_model.dart';

abstract class VendorBannerRemoteDataSource {
  Future<VendorBannerListResponse> fetchVendorBanners({
    double? lat,
    double? lng,
  });
}

class VendorBannerRemoteDataSourceImpl implements VendorBannerRemoteDataSource {
  final ApiHelper apiHelper;

  VendorBannerRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<VendorBannerListResponse> fetchVendorBanners({
    double? lat,
    double? lng,
  }) async {
    final url = ApiUrl.vendorBanners(lat: lat ?? 0.0, lng: lng ?? 0.0);
    logger.i("🌐 API CALL → VendorBannersList with lat=$lat, lng=$lng");
    logger.d("URL: $url");

    final response = await apiHelper.execute(method: Method.get, url: url);

    logger.i("📡 API RESPONSE → VendorBannersList success");
    return VendorBannerListResponse.fromJson(response);
  }
}
