import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/vendor_home_section_remote_datasource.dart';
import '../models/vendor_home_section_model.dart';

abstract class VendorHomeSectionRepository {
  Future<Either<Failure, VendorHomeSectionResponse>> fetchVendorHomeSections({
    required double lat,
    required double lng,
    String? sortBy,
    String? foodType,
  });

  Future<Either<Failure, VendorHomeSectionFiltersResponse>> fetchVendorHomeSectionFilters();
}

class VendorHomeSectionRepositoryImpl implements VendorHomeSectionRepository {
  final VendorHomeSectionRemoteDataSource remoteDataSource;

  VendorHomeSectionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, VendorHomeSectionResponse>> fetchVendorHomeSections({
    required double lat,
    required double lng,
    String? sortBy,
    String? foodType,
  }) async {
    try {
      final response = await remoteDataSource.fetchVendorHomeSections(
        lat: lat,
        lng: lng,
        sortBy: sortBy,
        foodType: foodType,
      );
      if (response.status == 200 || response.status == 201) {
        return Right(response);
      } else {
        return Left(ServerFailure(response.message ?? "Failed to fetch home sections"));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorHomeSectionFiltersResponse>> fetchVendorHomeSectionFilters() async {
    try {
      final response = await remoteDataSource.fetchVendorHomeSectionFilters();
      if (response.status == 200 || response.status == 201) {
        return Right(response);
      } else {
        return Left(ServerFailure(response.message ?? "Failed to fetch filters"));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
