/// Models for Google Places Autocomplete and Place Details responses.

class PlacesSuggestion {
  final String placeId;
  final String description;

  const PlacesSuggestion({
    required this.placeId,
    required this.description,
  });

  factory PlacesSuggestion.fromJson(Map<String, dynamic> json) {
    return PlacesSuggestion(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double lat;
  final double lng;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });

  factory PlaceDetails.fromJson(String placeId, Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? {};
    final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};

    return PlaceDetails(
      placeId: placeId,
      name: result['name'] as String? ?? '',
      formattedAddress: result['formatted_address'] as String? ?? '',
      lat: (location['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
