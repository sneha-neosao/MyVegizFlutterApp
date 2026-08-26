class VendorDetailsResponse {
  final int? status;
  final String? message;
  final VendorDetailsData? data;

  VendorDetailsResponse({this.status, this.message, this.data});

  factory VendorDetailsResponse.fromJson(Map<String, dynamic> json) {
    return VendorDetailsResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? VendorDetailsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
class VendorDetailsData {
  final int? id;
  final String? uuId;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? entityName;
  final String? entityImage;
  final String? entityContact;
  final int? entityCategoryId;
  final String? entityCategoryName;
  final String? email;
  final String? city;
  final String? area;
  final String? address;
  final double? lat;
  final double? lng;
  final List<VendorCuisineMapping>? cuisines;
  final String? deliveryPackagingType;
  final double? deliveryPackagingPrice;
  final bool? adminIsServiceable;
  final bool? autoIsServiceable;
  final bool? isPopular;
  final dynamic tags;
  final String? foodType;
  final bool? isActive;
  final bool? isDeliverable;
  final double? distanceKm;
  final String? createdAt;
  final double? avgRating;
  final int? totalReviews;

  VendorDetailsData({
    this.id,
    this.uuId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.entityName,
    this.entityImage,
    this.entityContact,
    this.entityCategoryId,
    this.entityCategoryName,
    this.email,
    this.city,
    this.area,
    this.address,
    this.lat,
    this.lng,
    this.cuisines,
    this.deliveryPackagingType,
    this.deliveryPackagingPrice,
    this.adminIsServiceable,
    this.autoIsServiceable,
    this.isPopular,
    this.tags,
    this.foodType,
    this.isActive,
    this.isDeliverable,
    this.distanceKm,
    this.createdAt,
    this.avgRating,
    this.totalReviews,
  });

  bool get isServiceable => adminIsServiceable == true;

  factory VendorDetailsData.fromJson(Map<String, dynamic> json) {
    return VendorDetailsData(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      entityName: json['entity_name'] as String?,
      entityImage: json['entity_image'] as String?,
      entityContact: json['entity_contact'] as String?,
      entityCategoryId: json['entity_category_id'] as int?,
      entityCategoryName: json['entity_category_name'] as String?,
      email: json['email'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      cuisines: json['cuisines'] != null
          ? (json['cuisines'] as List)
              .map((e) => VendorCuisineMapping.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      deliveryPackagingType: json['delivery_packaging_type'] as String?,
      deliveryPackagingPrice: (json['delivery_packaging_price'] as num?)?.toDouble(),
      adminIsServiceable: json['admin_is_serviceable'] as bool?,
      autoIsServiceable: json['auto_is_serviceable'] as bool?,
      isPopular: json['is_popular'] as bool?,
      tags: json['tags'],
      foodType: json['food_type'] as String?,
      isActive: json['is_active'] as bool?,
      isDeliverable: json['is_deliverable'] as bool?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
    );
  }
}

class VendorCuisineMapping {
  final int? id;
  final int? cuisineId;
  final VendorCuisine? cuisine;

  VendorCuisineMapping({
    this.id,
    this.cuisineId,
    this.cuisine,
  });

  factory VendorCuisineMapping.fromJson(Map<String, dynamic> json) {
    return VendorCuisineMapping(
      id: json['id'] as int?,
      cuisineId: json['cuisine_id'] as int?,
      cuisine: json['cuisine'] != null
          ? VendorCuisine.fromJson(json['cuisine'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VendorCuisine {
  final int? id;
  final String? uuId;
  final String? cuisineName;
  final String? image;

  VendorCuisine({
    this.id,
    this.uuId,
    this.cuisineName,
    this.image,
  });

  factory VendorCuisine.fromJson(Map<String, dynamic> json) {
    return VendorCuisine(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      cuisineName: json['cuisine_name'] as String?,
      image: json['image'] as String?,
    );
  }
}
