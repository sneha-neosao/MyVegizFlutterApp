import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../models/vendor_entity_category_model.dart';
import '../../repository/vendor_entity_category_repository.dart';

class GetVendorEntityCategoriesUseCase {
  final VendorEntityCategoryRepository repository;

  GetVendorEntityCategoriesUseCase(this.repository);

  Future<Either<Failure, VendorEntityCategoryResponse>> call({
    double? lat,
    double? lng,
    String? entityCategoryUuid,
    String? sortBy,
    String? foodType,
  }) async {
    return await repository.fetchVendorEntityCategories(
      lat: lat,
      lng: lng,
      entityCategoryUuid: entityCategoryUuid,
      sortBy: sortBy,
      foodType: foodType,
    );
  }
}
