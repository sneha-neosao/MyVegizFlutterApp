import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/homePage_model.dart';
import '../../../../core/utils/logger.dart';

abstract class HomePageRemoteDataSource {
  Future<HomePageModel> fetchHomePageData({
    required String mainCategorySlug,
    String? homeTabSlug,
    required double lat,
    required double lng,
    String? q,
  });
}

class HomePageRemoteDataSourceImpl implements HomePageRemoteDataSource {
  final ApiHelper apiHelper;

  HomePageRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<HomePageModel> fetchHomePageData({
    required String mainCategorySlug,
    String? homeTabSlug,
    required double lat,
    required double lng,
    String? q,
  }) async {
    final url = ApiUrl.homePage(
      mainCategorySlug: mainCategorySlug,
      homeTabSlug: homeTabSlug,
      lat: lat,
      lng: lng,
      q: q,
    );
    // logger.i("🌐 API CALL → HomePage");
    // logger.d("URL: $url");

    final response = await apiHelper.execute(method: Method.get, url: url);

    // logger.i("📡 API RESPONSE");
    return HomePageModel.fromJson(response);
  }
}
