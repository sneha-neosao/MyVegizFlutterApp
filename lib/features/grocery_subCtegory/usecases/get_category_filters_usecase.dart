import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../data/models/category_filters_model.dart';
import '../data/repository/category_products_repository.dart';

class GetCategoryFiltersUseCase {
  final CategoryProductsRepository repository;

  GetCategoryFiltersUseCase(this.repository);

  Future<Either<Failure, CategoryFiltersResponse>> call({
    required String categorySlug,
  }) async {
    return await repository.fetchCategoryFilters(
      categorySlug: categorySlug,
    );
  }
}
