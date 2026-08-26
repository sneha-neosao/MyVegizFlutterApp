import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/restaurant_details_remote_datasource.dart';
import '../models/vendor_list_model.dart';
import '../models/vendor_item_details_model.dart';
import '../models/vendor_details_model.dart';

abstract class RestaurantDetailsRepository {
  Future<Either<Failure, VendorListResponse>> getVendorList({
    required int limit,
    required int page,
    required int vendorId,
    double? lat,
    double? lng,
    String? sortBy,
    String? foodType,
  });

  Future<Either<Failure, VendorDetailsResponse>> getVendorDetails({
    required int vendorId,
    double? lat,
    double? lng,
  });

  Future<Either<Failure, VendorItemDetailsResponse>> getVendorItemDetails({
    required int vendorItemId,
    double? lat,
    double? lng,
  });

  Future<Either<Failure, VendorFiltersResponse>> getVendorFilters({
    required int vendorId,
  });
}

class RestaurantDetailsRepositoryImpl implements RestaurantDetailsRepository {
  final RestaurantDetailsRemoteDataSource remoteDataSource;

  RestaurantDetailsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, VendorListResponse>> getVendorList({
    required int limit,
    required int page,
    required int vendorId,
    double? lat,
    double? lng,
    String? sortBy,
    String? foodType,
  }) async {
    try {
      final response = await remoteDataSource.fetchVendorList(
        limit: limit,
        page: page,
        vendorId: vendorId,
        lat: lat,
        lng: lng,
        sortBy: sortBy,
        foodType: foodType,
      );
      if (response.status == 200 || response.status == 201) {
        return Right(response);
      } else {
        return Left(ServerFailure(response.message ?? "Failed to fetch vendor list"));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorDetailsResponse>> getVendorDetails({
    required int vendorId,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await remoteDataSource.fetchVendorDetails(
        vendorId: vendorId,
        lat: lat,
        lng: lng,
      );
      if (response.status == 200 || response.status == 201) {
        return Right(response);
      } else {
        return Left(ServerFailure(response.message ?? "Failed to fetch vendor details"));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorItemDetailsResponse>> getVendorItemDetails({
    required int vendorItemId,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await remoteDataSource.fetchVendorItemDetails(
        vendorItemId: vendorItemId,
        lat: lat,
        lng: lng,
      );
      if (response.status == 200 || response.status == 201) {
        return Right(response);
      } else {
        return Left(ServerFailure(response.message ?? "Failed to fetch vendor item details"));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorFiltersResponse>> getVendorFilters({
    required int vendorId,
  }) async {
    try {
      final response = await remoteDataSource.fetchVendorFilters(
        vendorId: vendorId,
      );
      if (response.status == 200 || response.status == 201) {
        return Right(response);
      } else {
        return Left(ServerFailure(response.message ?? "Failed to fetch vendor filters"));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
