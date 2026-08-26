import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/places_model.dart';
import '../../data/repository/places_repository.dart';

class SearchPlacesUseCase {
  final PlacesRepository repository;

  SearchPlacesUseCase(this.repository);

  Future<Either<Failure, List<PlacesSuggestion>>> call(String query) {
    return repository.searchPlaces(query);
  }
}

class GetPlaceDetailsUseCase {
  final PlacesRepository repository;

  GetPlaceDetailsUseCase(this.repository);

  Future<Either<Failure, PlaceDetails>> call(String placeId) {
    return repository.getPlaceDetails(placeId);
  }
}
