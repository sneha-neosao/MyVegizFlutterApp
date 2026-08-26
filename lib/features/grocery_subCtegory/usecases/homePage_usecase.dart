import 'package:fpdart/fpdart.dart';
import '../../../core/errors/failures.dart';
import '../data/models/homePage_model.dart';
import '../data/repository/homePage_repo.dart';

class HomePageUseCase {
  final HomePageRepository repository;

  HomePageUseCase(this.repository);

  Future<Either<Failure, HomePageModel>> call({
    required String mainCategorySlug,
    String? homeTabSlug,
    required double lat,
    required double lng,
    String? q,
  }) async {
    return await repository.fetchHomePageData(
      mainCategorySlug: mainCategorySlug,
      homeTabSlug: homeTabSlug,
      lat: lat,
      lng: lng,
      q: q,
    );
  }
}
