import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/grocery_category_model.dart';

abstract class GroceryCategoryRemoteDataSource {
  Future<GroceryCategoryResponse> fetchGroceryCategories({
    required int page,
    required int limit,
    required String mainCategorySlug,
  });
}

class GroceryCategoryRemoteDataSourceImpl implements GroceryCategoryRemoteDataSource {
  final ApiHelper apiHelper;

  GroceryCategoryRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<GroceryCategoryResponse> fetchGroceryCategories({
    required int page,
    required int limit,
    required String mainCategorySlug,
  }) async {
    final String url = ApiUrl.groceryCategories(
      page: page,
      limit: limit,
      mainCategorySlug: mainCategorySlug,
    );
    // logger.i("🌐 API CALL → GroceryCategories: $url");

    final response = await apiHelper.execute(method: Method.get, url: url);
    // logger.i("📡 API RESPONSE → GroceryCategories success");
    return GroceryCategoryResponse.fromJson(response);
  }
}
