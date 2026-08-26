import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../models/vendor_banner_model.dart';
import '../../repository/vendor_banner_repository.dart';

class GetVendorBannersUseCase {
  final VendorBannerRepository repository;

  GetVendorBannersUseCase(this.repository);

  Future<Either<Failure, VendorBannerListResponse>> call({
    double? lat,
    double? lng,
  }) async {
    return await repository.fetchVendorBanners(lat: lat, lng: lng);
  }
}
