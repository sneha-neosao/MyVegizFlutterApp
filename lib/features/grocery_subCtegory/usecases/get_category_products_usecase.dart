import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../data/models/homePage_model.dart';
import '../data/repository/category_products_repository.dart';

class GetCategoryProductsUseCase {
  final CategoryProductsRepository repository;

  GetCategoryProductsUseCase(this.repository);

  Future<Either<Failure, CategoryProductsResponse>> call({
    required double lat,
    required double lng,
    required String categorySlug,
    String? subCategoryUuId,
    String? tagUuId,
    String? sortBy,
  }) async {
    return await repository.fetchCategoryProducts(
      lat: lat,
      lng: lng,
      categorySlug: categorySlug,
      subCategoryUuId: subCategoryUuId,
      tagUuId: tagUuId,
      sortBy: sortBy,
    );
  }
}
