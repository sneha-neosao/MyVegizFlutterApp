class FoodProductRatingModel {
  final int orderItemId;
  final double rating;
  final String review;
  final String? createdAt;

  FoodProductRatingModel({
    required this.orderItemId,
    required this.rating,
    required this.review,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        "order_item_id": orderItemId,
        "rating": rating,
        "review": review,
      };

  factory FoodProductRatingModel.fromJson(Map<String, dynamic> json) => FoodProductRatingModel(
        orderItemId: json["order_item_id"] ?? 0,
        rating: (json["rating"] ?? 0.0).toDouble(),
        review: json["review"] ?? "",
        createdAt: json["created_at"],
      );
}

class FoodDeliveryRatingModel {
  final double rating;
  final String review;
  final String? createdAt;

  FoodDeliveryRatingModel({
    required this.rating,
    required this.review,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        "rating": rating,
        "review": review,
      };

  factory FoodDeliveryRatingModel.fromJson(Map<String, dynamic> json) => FoodDeliveryRatingModel(
        rating: (json["rating"] ?? 0.0).toDouble(),
        review: json["review"] ?? "",
        createdAt: json["created_at"],
      );
}

class VendorRatingModel {
  final double rating;
  final String review;
  final String? createdAt;

  VendorRatingModel({
    required this.rating,
    required this.review,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        "rating": rating,
        "review": review,
      };

  factory VendorRatingModel.fromJson(Map<String, dynamic> json) => VendorRatingModel(
        rating: (json["rating"] ?? 0.0).toDouble(),
        review: json["review"] ?? "",
        createdAt: json["created_at"],
      );
}

class FoodOrderRatingsResponseModel {
  final List<FoodProductRatingModel> productRatings;
  final FoodDeliveryRatingModel? deliveryRating;
  final VendorRatingModel? vendorRating;

  FoodOrderRatingsResponseModel({
    required this.productRatings,
    this.deliveryRating,
    this.vendorRating,
  });

  factory FoodOrderRatingsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return FoodOrderRatingsResponseModel(
      productRatings: (data['product_ratings'] as List<dynamic>?)
              ?.map((e) => FoodProductRatingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryRating: data['delivery_rating'] != null
          ? FoodDeliveryRatingModel.fromJson(data['delivery_rating'] as Map<String, dynamic>)
          : null,
      vendorRating: data['vendor_rating'] != null
          ? VendorRatingModel.fromJson(data['vendor_rating'] as Map<String, dynamic>)
          : null,
    );
  }
}
