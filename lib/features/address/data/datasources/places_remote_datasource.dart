import 'package:dio/dio.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/places_model.dart';

abstract class PlacesRemoteDataSource {
  Future<List<PlacesSuggestion>> searchPlaces(String query);
  Future<PlaceDetails> getPlaceDetails(String placeId);
}

class PlacesRemoteDataSourceImpl implements PlacesRemoteDataSource {
  final Dio _dio;

  PlacesRemoteDataSourceImpl(this._dio);

  @override
  Future<List<PlacesSuggestion>> searchPlaces(String query) async {
    logger.i('🗺️ Places API → Autocomplete: "$query"');
    try {
      final response = await _dio.get(ApiUrl.placesAutocomplete(query));
      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        logger.e('🗺️ Places Autocomplete error status: $status');
        throw Exception('Places API error: $status');
      }

      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions
          .cast<Map<String, dynamic>>()
          .map(PlacesSuggestion.fromJson)
          .toList();
    } catch (e) {
      logger.e('🗺️ Places Autocomplete exception: $e');
      rethrow;
    }
  }

  @override
  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    logger.i('🗺️ Places API → Details for placeId: $placeId');
    try {
      final response = await _dio.get(ApiUrl.placeDetails(placeId));
      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';

      if (status != 'OK') {
        logger.e('🗺️ Place Details error status: $status');
        throw Exception('Place Details API error: $status');
      }

      return PlaceDetails.fromJson(placeId, data);
    } catch (e) {
      logger.e('🗺️ Place Details exception: $e');
      rethrow;
    }
  }
}
