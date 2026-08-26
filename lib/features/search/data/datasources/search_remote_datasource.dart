import 'package:dio/dio.dart';
import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/location_service.dart';
import '../models/grocery_search_response_model.dart';

abstract class SearchRemoteDataSource {
  Future<GrocerySearchResponse> searchProducts({
    required String query,
    double? lat,
    double? lng,
    int? page,
    int? limit,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final ApiHelper apiHelper;

  SearchRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<GrocerySearchResponse> searchProducts({
    required String query,
    double? lat,
    double? lng,
    int? page,
    int? limit,
  }) async {
    final double finalLat = lat ?? locationService.locationNotifier.value?.lat ?? 0.0;
    final double finalLng = lng ?? locationService.locationNotifier.value?.lng ?? 0.0;

    final url = ApiUrl.searchGroceryProducts(
      query: query,
      lat: finalLat,
      lng: finalLng,
      page: page,
      limit: limit,
    );

    final token = await SecureStorage.getAccessToken();
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;

    final response = await apiHelper.execute(
      method: Method.get,
      url: url,
      options: options,
    );

    return GrocerySearchResponse.fromJson(response);
  }
}
