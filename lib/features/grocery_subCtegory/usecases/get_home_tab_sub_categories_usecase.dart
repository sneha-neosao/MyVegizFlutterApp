import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../data/models/home_tab_sub_categories_model.dart';
import '../data/repository/homePage_repo.dart';

class GetHomeTabSubCategoriesUseCase {
  final HomePageRepository repository;

  GetHomeTabSubCategoriesUseCase(this.repository);

  Future<Either<Failure, HomeTabSubCategoriesResponse>> call({
    required String homeTabUuId,
    int page = 1,
    int limit = 10,
  }) async {
    return await repository.getHomeTabSubCategories(
      homeTabUuId: homeTabUuId,
      page: page,
      limit: limit,
    );
  }
}
