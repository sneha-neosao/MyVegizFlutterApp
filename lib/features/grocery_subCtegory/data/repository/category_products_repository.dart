import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/api/api/api_exception.dart';
import '../models/homePage_model.dart';
import '../models/category_filters_model.dart';
import '../models/sub_categories_by_category_model.dart';
import '../datasources/category_products_remote_datasource.dart';

abstract class CategoryProductsRepository {
  Future<Either<Failure, CategoryProductsResponse>> fetchCategoryProducts({
    required double lat,
    required double lng,
    required String subCategoryUuId,
    int? homeTabId,
    String? categorySlug,
    String? search,
    String? tagUuId,
    String? sortBy,
    int? page,
    int? limit,
  });

  Future<Either<Failure, CategoryFiltersResponse>> fetchCategoryFilters({
    required String categorySlug,
  });

  Future<Either<Failure, SubCategoriesByCategoryResponse>> fetchSubCategoriesByCategory({
    required String categorySlug,
    int page = 1,
    int limit = 10,
  });
}

class CategoryProductsRepositoryImpl implements CategoryProductsRepository {
  final CategoryProductsRemoteDataSource remoteDataSource;

  CategoryProductsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, CategoryProductsResponse>> fetchCategoryProducts({
    required double lat,
    required double lng,
    required String subCategoryUuId,
    int? homeTabId,
    String? categorySlug,
    String? search,
    String? tagUuId,
    String? sortBy,
    int? page,
    int? limit,
  }) async {
    try {
      final data = await remoteDataSource.fetchCategoryProducts(
        lat: lat,
        lng: lng,
        subCategoryUuId: subCategoryUuId,
        homeTabId: homeTabId,
        categorySlug: categorySlug,
        search: search,
        tagUuId: tagUuId,
        sortBy: sortBy,
        page: page,
        limit: limit,
      );
      if (data.status == 200 || data.status == 201 || data.status == 300) {
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

  @override
  Future<Either<Failure, SubCategoriesByCategoryResponse>> fetchSubCategoriesByCategory({
    required String categorySlug,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final data = await remoteDataSource.fetchSubCategoriesByCategory(
        categorySlug: categorySlug,
        page: page,
        limit: limit,
      );
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message.isNotEmpty ? data.message : "Failed to fetch sub-categories"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
