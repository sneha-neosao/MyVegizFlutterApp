import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/places_remote_datasource.dart';
import '../models/places_model.dart';

abstract class PlacesRepository {
  Future<Either<Failure, List<PlacesSuggestion>>> searchPlaces(String query);
  Future<Either<Failure, PlaceDetails>> getPlaceDetails(String placeId);
}

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesRemoteDataSource remoteDataSource;

  PlacesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<PlacesSuggestion>>> searchPlaces(
    String query,
  ) async {
    try {
      final result = await remoteDataSource.searchPlaces(query);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaceDetails>> getPlaceDetails(
    String placeId,
  ) async {
    try {
      final result = await remoteDataSource.getPlaceDetails(placeId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
