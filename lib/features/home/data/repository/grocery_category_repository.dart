import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/grocery_category_remote_datasource.dart';
import '../models/grocery_category_model.dart';

abstract class GroceryCategoryRepository {
  Future<Either<Failure, GroceryCategoryResponse>> fetchGroceryCategories({
    required int page,
    required int limit,
    required String mainCategorySlug,
  });
}

class GroceryCategoryRepositoryImpl implements GroceryCategoryRepository {
  final GroceryCategoryRemoteDataSource remoteDataSource;

  GroceryCategoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, GroceryCategoryResponse>> fetchGroceryCategories({
    required int page,
    required int limit,
    required String mainCategorySlug,
  }) async {
    try {
      final data = await remoteDataSource.fetchGroceryCategories(
        page: page,
        limit: limit,
        mainCategorySlug: mainCategorySlug,
      );
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch grocery categories"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
