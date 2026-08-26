class ProductRatingModel {
  final int orderItemId;
  final double rating;
  final String review;
  final String? createdAt;

  ProductRatingModel({
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

  factory ProductRatingModel.fromJson(Map<String, dynamic> json) => ProductRatingModel(
        orderItemId: json["order_item_id"] ?? 0,
        rating: (json["rating"] ?? 0.0).toDouble(),
        review: json["review"] ?? "",
        createdAt: json["created_at"],
      );
}

class DeliveryRatingModel {
  final double rating;
  final String review;
  final String? createdAt;

  DeliveryRatingModel({
    required this.rating,
    required this.review,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        "rating": rating,
        "review": review,
      };

  factory DeliveryRatingModel.fromJson(Map<String, dynamic> json) => DeliveryRatingModel(
        rating: (json["rating"] ?? 0.0).toDouble(),
        review: json["review"] ?? "",
        createdAt: json["created_at"],
      );
}

class OrderRatingsResponseModel {
  final List<ProductRatingModel> productRatings;
  final DeliveryRatingModel? deliveryRating;

  OrderRatingsResponseModel({
    required this.productRatings,
    this.deliveryRating,
  });

  factory OrderRatingsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return OrderRatingsResponseModel(
      productRatings: (data['product_ratings'] as List<dynamic>?)
              ?.map((e) => ProductRatingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryRating: data['delivery_rating'] != null
          ? DeliveryRatingModel.fromJson(data['delivery_rating'] as Map<String, dynamic>)
          : null,
    );
  }
}
