import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/entity_category_remote_datasource.dart';
import '../models/entity_category_model.dart';

abstract class EntityCategoryRepository {
  Future<Either<Failure, EntityCategoryResponse>> fetchEntityCategories();
}

class EntityCategoryRepositoryImpl implements EntityCategoryRepository {
  final EntityCategoryRemoteDataSource remoteDataSource;

  EntityCategoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, EntityCategoryResponse>> fetchEntityCategories() async {
    try {
      final data = await remoteDataSource.fetchEntityCategories();
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch entity categories"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
