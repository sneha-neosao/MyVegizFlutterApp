import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/cms_page_model.dart';

abstract class CmsRemoteDataSource {
  Future<CmsPageResponse> fetchCmsPage(String pageKey);
}

class CmsRemoteDataSourceImpl implements CmsRemoteDataSource {
  final ApiHelper apiHelper;

  CmsRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<CmsPageResponse> fetchCmsPage(String pageKey) async {
    final String url;
    if (pageKey == 'privacy') {
      url = ApiUrl.privacyPolicy;
    } else if (pageKey == 'refund') {
      url = ApiUrl.refundPolicy;
    } else if (pageKey == 'terms') {
      url = ApiUrl.termsAndConditions;
    } else {
      throw Exception("Unsupported CMS page key: $pageKey");
    }

    logger.i("🌐 API CALL → CMS Page ($pageKey): $url");

    final response = await apiHelper.execute(method: Method.get, url: url);
    logger.i("📡 API RESPONSE → CMS Page ($pageKey) success");
    return CmsPageResponse.fromJson(response);
  }
}
