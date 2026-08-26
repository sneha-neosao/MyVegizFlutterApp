import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/api/api/api_exception.dart';
import '../models/homePage_model.dart';
import '../models/category_filters_model.dart';
import '../datasources/category_products_remote_datasource.dart';

abstract class CategoryProductsRepository {
  Future<Either<Failure, CategoryProductsResponse>> fetchCategoryProducts({
    required double lat,
    required double lng,
    required String categorySlug,
    String? subCategoryUuId,
    String? tagUuId,
    String? sortBy,
  });

  Future<Either<Failure, CategoryFiltersResponse>> fetchCategoryFilters({
    required String categorySlug,
  });
}

class CategoryProductsRepositoryImpl implements CategoryProductsRepository {
  final CategoryProductsRemoteDataSource remoteDataSource;

  CategoryProductsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, CategoryProductsResponse>> fetchCategoryProducts({
    required double lat,
    required double lng,
    required String categorySlug,
    String? subCategoryUuId,
    String? tagUuId,
    String? sortBy,
  }) async {
    try {
      final data = await remoteDataSource.fetchCategoryProducts(
        lat: lat,
        lng: lng,
        categorySlug: categorySlug,
        subCategoryUuId: subCategoryUuId,
        tagUuId: tagUuId,
        sortBy: sortBy,
      );
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch category products"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CategoryFiltersResponse>> fetchCategoryFilters({
    required String categorySlug,
  }) async {
    try {
      final data = await remoteDataSource.fetchCategoryFilters(
        categorySlug: categorySlug,
      );
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch category filters"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
