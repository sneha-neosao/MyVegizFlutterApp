import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grocery_search_response_model.dart';
import '../../data/repository/search_repository.dart';

class SearchProductsUseCase {
  final SearchRepository repository;

  SearchProductsUseCase(this.repository);

  Future<Either<Failure, GrocerySearchResponse>> call({
    required String query,
    double? lat,
    double? lng,
    int? page,
    int? limit,
  }) async {
    return await repository.searchProducts(
      query: query,
      lat: lat,
      lng: lng,
      page: page,
      limit: limit,
    );
  }
}
