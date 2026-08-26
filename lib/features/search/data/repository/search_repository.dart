import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/api/api/api_exception.dart';
import '../datasources/search_remote_datasource.dart';
import '../models/grocery_search_response_model.dart';

abstract class SearchRepository {
  Future<Either<Failure, GrocerySearchResponse>> searchProducts({
    required String query,
    double? lat,
    double? lng,
    int? page,
    int? limit,
  });
}

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, GrocerySearchResponse>> searchProducts({
    required String query,
    double? lat,
    double? lng,
    int? page,
    int? limit,
  }) async {
    try {
      final data = await remoteDataSource.searchProducts(
        query: query,
        lat: lat,
        lng: lng,
        page: page,
        limit: limit,
      );
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to search products"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
