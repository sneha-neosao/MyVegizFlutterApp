import 'package:dio/dio.dart';
import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/homePage_model.dart';
import '../models/category_filters_model.dart';
import '../../../../core/utils/logger.dart';

abstract class CategoryProductsRemoteDataSource {
  Future<CategoryProductsResponse> fetchCategoryProducts({
    required double lat,
    required double lng,
    required String subCategoryUuId,
    int? homeTabId,
    String? categorySlug,
    String? search,
    String? tagUuId,
    String? sortBy,
    int? page,
    int? limit,
  });

  Future<CategoryFiltersResponse> fetchCategoryFilters({
    required String categorySlug,
  });
}

class CategoryProductsRemoteDataSourceImpl implements CategoryProductsRemoteDataSource {
  final ApiHelper apiHelper;

  CategoryProductsRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<CategoryProductsResponse> fetchCategoryProducts({
    required double lat,
    required double lng,
    required String subCategoryUuId,
    int? homeTabId,
    String? categorySlug,
    String? search,
    String? tagUuId,
    String? sortBy,
    int? page,
    int? limit,
  }) async {
    final url = ApiUrl.categoryProducts(
      lat: lat,
      lng: lng,
      subCategoryUuId: subCategoryUuId,
      homeTabId: homeTabId,
      categorySlug: categorySlug,
      search: search,
      tagUuId: tagUuId,
      sortBy: sortBy,
      page: page,
      limit: limit,
    );
    // logger.i("🌐 API CALL → CategoryProducts");
    // logger.d("URL: $url");

    final token = await SecureStorage.getAccessToken();
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;

    final response = await apiHelper.execute(
      method: Method.get,
      url: url,
      options: options,
    );

    // logger.i("📡 API RESPONSE CategoryProducts");
    return CategoryProductsResponse.fromJson(response);
  }

  @override
  Future<CategoryFiltersResponse> fetchCategoryFilters({
    required String categorySlug,
  }) async {
    final url = ApiUrl.categoryFilters(categorySlug: categorySlug);
    // logger.i("🌐 API CALL → CategoryFilters");
    // logger.d("URL: $url");

    final response = await apiHelper.execute(method: Method.get, url: url);

    // logger.i("📡 API RESPONSE CategoryFilters");
    return CategoryFiltersResponse.fromJson(response);
  }
}
