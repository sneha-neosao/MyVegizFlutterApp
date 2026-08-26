import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../models/vendor_home_section_model.dart';
import '../../repository/vendor_home_section_repository.dart';

class GetVendorHomeSectionsUseCase {
  final VendorHomeSectionRepository repository;

  GetVendorHomeSectionsUseCase(this.repository);

  Future<Either<Failure, VendorHomeSectionResponse>> call({
    required double lat,
    required double lng,
    String? sortBy,
    String? foodType,
  }) async {
    return await repository.fetchVendorHomeSections(
      lat: lat,
      lng: lng,
      sortBy: sortBy,
      foodType: foodType,
    );
  }
}
