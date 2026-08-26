import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/cms_remote_datasource.dart';
import '../models/cms_page_model.dart';

abstract class CmsRepository {
  Future<Either<Failure, CmsPageResponse>> fetchCmsPage(String pageKey);
}

class CmsRepositoryImpl implements CmsRepository {
  final CmsRemoteDataSource remoteDataSource;

  CmsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, CmsPageResponse>> fetchCmsPage(String pageKey) async {
    try {
      final data = await remoteDataSource.fetchCmsPage(pageKey);
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch CMS page content"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
