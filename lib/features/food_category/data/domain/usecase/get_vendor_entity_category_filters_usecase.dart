import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../models/vendor_entity_category_model.dart';
import '../../repository/vendor_entity_category_repository.dart';

class GetVendorEntityCategoryFiltersUseCase {
  final VendorEntityCategoryRepository repository;

  GetVendorEntityCategoryFiltersUseCase(this.repository);

  Future<Either<Failure, VendorEntityCategoryFilterResponse>> call() async {
    return await repository.fetchVendorEntityCategoryFilters();
  }
}
