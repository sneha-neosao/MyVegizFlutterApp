import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grocery_category_model.dart';
import '../../data/repository/grocery_category_repository.dart';

class GetGroceryCategoriesUseCase {
  final GroceryCategoryRepository repository;

  GetGroceryCategoriesUseCase(this.repository);

  Future<Either<Failure, GroceryCategoryResponse>> call({
    required int page,
    required int limit,
    required String mainCategorySlug,
  }) async {
    return await repository.fetchGroceryCategories(
      page: page,
      limit: limit,
      mainCategorySlug: mainCategorySlug,
    );
  }
}
