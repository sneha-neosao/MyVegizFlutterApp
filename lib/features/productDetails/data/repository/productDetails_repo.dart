import 'package:my_vegiz_flutter/features/productDetails/data/models/product_details_model.dart';

import '../datasources/productDetails_datasource.dart';

abstract class ProductDetailsRepository {
  Future<ProductDetailsModel> getProductDetails({
    required String slug,
    double? lat,
    double? lng,
  });
}

class ProductDetailsRepositoryImpl implements ProductDetailsRepository {
  final ProductDetailsRemoteDataSource remoteDataSource;

  ProductDetailsRepositoryImpl(this.remoteDataSource);

  @override
  Future<ProductDetailsModel> getProductDetails({
    required String slug,
    double? lat,
    double? lng,
  }) async {
    return await remoteDataSource.fetchProductDetails(
      slug: slug,
      lat: lat,
      lng: lng,
    );
  }
}
