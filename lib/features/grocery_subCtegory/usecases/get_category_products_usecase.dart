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
    required String subCategoryUuId,
    int? homeTabId,
    String? categorySlug,
    String? search,
    String? tagUuId,
    String? sortBy,
    int? page,
    int? limit,
  }) async {
    return await repository.fetchCategoryProducts(
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
  }
}
