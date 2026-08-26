import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/cms_page_model.dart';
import '../../data/repository/cms_repository.dart';

class GetCmsPageUseCase {
  final CmsRepository repository;

  GetCmsPageUseCase(this.repository);

  Future<Either<Failure, CmsPageResponse>> call(String pageKey) async {
    return await repository.fetchCmsPage(pageKey);
  }
}
