import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/vendor_banner_remote_datasource.dart';
import '../models/vendor_banner_model.dart';

abstract class VendorBannerRepository {
  Future<Either<Failure, VendorBannerListResponse>> fetchVendorBanners({
    double? lat,
    double? lng,
  });
}

class VendorBannerRepositoryImpl implements VendorBannerRepository {
  final VendorBannerRemoteDataSource remoteDataSource;

  VendorBannerRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, VendorBannerListResponse>> fetchVendorBanners({
    double? lat,
    double? lng,
  }) async {
    try {
      final data = await remoteDataSource.fetchVendorBanners(lat: lat, lng: lng);
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch vendor banners"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
