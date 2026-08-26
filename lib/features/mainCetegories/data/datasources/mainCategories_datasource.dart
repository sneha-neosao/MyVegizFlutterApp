import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/mainCategory_model.dart';
import '../../../../core/utils/logger.dart';

abstract class MainCategoriesRemoteDataSource {
  Future<MainCategoryModel> getMainCategories({int page = 1, int limit = 10});
}

class MainCategoriesRemoteDataSourceImpl
    implements MainCategoriesRemoteDataSource {
  final ApiHelper apiHelper;

  MainCategoriesRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<MainCategoryModel> getMainCategories({
    int page = 1,
    int limit = 10,
  }) async {

    final response = await apiHelper.execute(
      method: Method.get,
      url: ApiUrl.mainCategories(page, limit),
    );

    return MainCategoryModel.fromJson(response);
  }
}
