import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/mainCategory_model.dart';
import '../../data/repository/mainCategories_repo.dart';

class MainCategoriesUseCase {
  final MainCategoriesRepository repository;

  MainCategoriesUseCase(this.repository);

  Future<Either<Failure, MainCategoryModel>> call({
    int page = 1,
    int limit = 10,
  }) {
    return repository.getMainCategories(page: page, limit: limit);
  }
}
