import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api/api_exception.dart';
import '../datasources/mainCategories_datasource.dart';
import '../models/mainCategory_model.dart';
import '../../../../core/utils/logger.dart';

abstract class MainCategoriesRepository {
  Future<Either<Failure, MainCategoryModel>> getMainCategories({
    int page = 1,
    int limit = 10,
  });
}

class MainCategoriesRepositoryImpl implements MainCategoriesRepository {
  final MainCategoriesRemoteDataSource remoteDataSource;

  MainCategoriesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, MainCategoryModel>> getMainCategories({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getMainCategories(
        page: page,
        limit: limit,
      );
      if (result.status == 200 || result.status == 201) {
        return Right(result);
      } else {
        return Left(ServerFailure(result.message));
      }
    } on ApiException catch (e) {
      logger.e("❌ MainCategoriesRepository ApiException: ${e.message}");
      return Left(ServerFailure(e.message));
    } catch (e) {
      logger.e("❌ MainCategoriesRepository Error: $e");
      return Left(ServerFailure(e.toString()));
    }
  }
}
