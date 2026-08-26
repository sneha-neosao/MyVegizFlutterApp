import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/vendor_entity_category_remote_datasource.dart';
import '../models/vendor_entity_category_model.dart';

abstract class VendorEntityCategoryRepository {
  Future<Either<Failure, VendorEntityCategoryResponse>> fetchVendorEntityCategories({
    double? lat,
    double? lng,
    String? entityCategoryUuid,
    String? sortBy,
    String? foodType,
  });

  Future<Either<Failure, VendorEntityCategoryFilterResponse>> fetchVendorEntityCategoryFilters();
}

class VendorEntityCategoryRepositoryImpl implements VendorEntityCategoryRepository {
  final VendorEntityCategoryRemoteDataSource remoteDataSource;

  VendorEntityCategoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, VendorEntityCategoryResponse>> fetchVendorEntityCategories({
    double? lat,
    double? lng,
    String? entityCategoryUuid,
    String? sortBy,
    String? foodType,
  }) async {
    try {
      final data = await remoteDataSource.fetchVendorEntityCategories(
        lat: lat,
        lng: lng,
        entityCategoryUuid: entityCategoryUuid,
        sortBy: sortBy,
        foodType: foodType,
      );
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch vendor entity categories"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorEntityCategoryFilterResponse>> fetchVendorEntityCategoryFilters() async {
    try {
      final data = await remoteDataSource.fetchVendorEntityCategoryFilters();
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch vendor entity category filters"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

