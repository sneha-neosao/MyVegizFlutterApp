import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../models/vendor_home_section_model.dart';
import '../../repository/vendor_home_section_repository.dart';

class GetVendorHomeSectionFiltersUseCase {
  final VendorHomeSectionRepository repository;

  GetVendorHomeSectionFiltersUseCase(this.repository);

  Future<Either<Failure, VendorHomeSectionFiltersResponse>> call() async {
    return await repository.fetchVendorHomeSectionFilters();
  }
}
