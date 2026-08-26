import 'package:dio/dio.dart';
import 'package:my_vegiz_flutter/features/productDetails/data/models/product_details_model.dart';
import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';

import '../../../../core/utils/location_service.dart';

abstract class ProductDetailsRemoteDataSource {
  Future<ProductDetailsModel> fetchProductDetails({
    required String slug,
    double? lat,
    double? lng,
  });
}

class ProductDetailsRemoteDataSourceImpl
    implements ProductDetailsRemoteDataSource {
  final ApiHelper apiHelper;

  ProductDetailsRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<ProductDetailsModel> fetchProductDetails({
    required String slug,
    double? lat,
    double? lng,
  }) async {
    try {
      final double finalLat = lat ?? locationService.locationNotifier.value?.lat ?? 0.0;
      final double finalLng = lng ?? locationService.locationNotifier.value?.lng ?? 0.0;
      final response = await apiHelper.execute(
        url: ApiUrl.productDetails(slug: slug, lat: finalLat, lng: finalLng),
        method: Method.get,
      );
      return ProductDetailsModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch product details',
        );
      }
      throw Exception('Failed to fetch product details: $e');
    }
  }
}
