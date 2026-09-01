import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../data/models/sub_categories_by_category_model.dart';
import '../data/repository/category_products_repository.dart';

class GetSubCategoriesByCategoryUseCase {
  final CategoryProductsRepository repository;

  GetSubCategoriesByCategoryUseCase(this.repository);

  Future<Either<Failure, SubCategoriesByCategoryResponse>> call({
    required String categorySlug,
    int page = 1,
    int limit = 10,
  }) async {
    return await repository.fetchSubCategoriesByCategory(
      categorySlug: categorySlug,
      page: page,
      limit: limit,
    );
  }
}
