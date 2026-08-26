import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/entity_category_model.dart';
import '../../data/repository/entity_category_repository.dart';

class GetEntityCategoriesUseCase {
  final EntityCategoryRepository repository;

  GetEntityCategoriesUseCase(this.repository);

  Future<Either<Failure, EntityCategoryResponse>> call() async {
    return await repository.fetchEntityCategories();
  }
}
