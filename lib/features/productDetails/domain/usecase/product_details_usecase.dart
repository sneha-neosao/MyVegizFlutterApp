import 'package:my_vegiz_flutter/features/productDetails/data/repository/productDetails_repo.dart';

import '../../data/models/product_details_model.dart';

class ProductDetailsUseCase {
  final ProductDetailsRepository repository;

  ProductDetailsUseCase(this.repository);

  Future<ProductDetailsModel> call({
    required String slug,
    double? lat,
    double? lng,
  }) async {
    return await repository.getProductDetails(
      slug: slug,
      lat: lat,
      lng: lng,
    );
  }
}
