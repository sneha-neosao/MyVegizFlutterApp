import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/homePage_model.dart';
import '../models/home_tab_sub_categories_model.dart';
import '../../../../core/utils/logger.dart';

abstract class HomePageRemoteDataSource {
  Future<HomePageModel> fetchHomePageData({
    required String mainCategorySlug,
    String? homeTabSlug,
    required double lat,
    required double lng,
    String? q,
  });

  Future<HomeTabSubCategoriesResponse> fetchHomeTabSubCategories({
    required String homeTabUuId,
    int page = 1,
    int limit = 10,
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

  @override
  Future<HomeTabSubCategoriesResponse> fetchHomeTabSubCategories({
    required String homeTabUuId,
    int page = 1,
    int limit = 10,
  }) async {
    final url = ApiUrl.homeTabSubCategories(
      homeTabUuId: homeTabUuId,
      page: page,
      limit: limit,
    );

    final response = await apiHelper.execute(method: Method.get, url: url);
    return HomeTabSubCategoriesResponse.fromJson(response);
  }
}
