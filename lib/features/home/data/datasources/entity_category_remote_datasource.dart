import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/entity_category_model.dart';

abstract class EntityCategoryRemoteDataSource {
  Future<EntityCategoryResponse> fetchEntityCategories();
}

class EntityCategoryRemoteDataSourceImpl implements EntityCategoryRemoteDataSource {
  final ApiHelper apiHelper;

  EntityCategoryRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<EntityCategoryResponse> fetchEntityCategories() async {
    final String url = ApiUrl.entityCategoriesList;
    // logger.i("🌐 API CALL → EntityCategoryList: $url");

    final response = await apiHelper.execute(method: Method.get, url: url);
    // logger.i("📡 API RESPONSE → EntityCategoryList success");
    return EntityCategoryResponse.fromJson(response);
  }
}
