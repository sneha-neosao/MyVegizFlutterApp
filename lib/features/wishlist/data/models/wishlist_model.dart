import '../../../../core/models/common_models.dart';

class WishlistToggleResponse {
  final bool isSaved;
  final String message;

  WishlistToggleResponse({required this.isSaved, required this.message});

  factory WishlistToggleResponse.fromJson(Map<String, dynamic> json) {
    return WishlistToggleResponse(
      isSaved: json['is_saved'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class WishlistItemModel {
  final int favouriteId;
  final int productId;
  final String productUuId;
  final String productName;
  final String slug;
  final String productImage;
  final bool isSaved;
  final List<SharedVariantModel> variants;
  final SharedRatingModel? rating;
  final int productViews;
  final int? productVariantId;

  WishlistItemModel({
    required this.favouriteId,
    required this.productId,
    required this.productUuId,
    required this.productName,
    required this.slug,
    required this.productImage,
    required this.isSaved,
    required this.variants,
    this.rating,
    this.productViews = 0,
    this.productVariantId,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    // Some APIs return the product data nested inside a 'product' object
    final Map<String, dynamic> productJson = json['product'] is Map<String, dynamic> 
        ? json['product'] as Map<String, dynamic> 
        : json;

    // Extract the best image
    String? bestImage = productJson['product_image'] ?? productJson['image'];
    if ((bestImage == null || bestImage.isEmpty) && productJson['images'] != null && (productJson['images'] as List).isNotEmpty) {
      final images = productJson['images'] as List;
      final primaryImage = images.firstWhere(
        (img) => img['is_primary'] == true, 
        orElse: () => images.first
      );
      bestImage = primaryImage['product_image'] ?? primaryImage['image'];
    }

    // Parse rating even if it's flat or named differently
    SharedRatingModel? parsedRating;
    if (productJson['rating'] != null) {
      parsedRating = SharedRatingModel.fromJson(productJson['rating']);
    } else if (productJson['avg_rating'] != null) {
      parsedRating = SharedRatingModel(
        avgRating: (productJson['avg_rating'] as num?)?.toDouble() ?? 0.0,
        totalReviews: (productJson['total_reviews'] as num?)?.toInt() ?? 0,
      );
    }

    return WishlistItemModel(
      favouriteId: json['favourite_id'] ?? json['id'] ?? 0,
      productId: productJson['id'] ?? productJson['product_id'] ?? json['product_id'] ?? 0,
      productUuId: productJson['uu_id'] ?? productJson['product_uu_id'] ?? json['product_uu_id'] ?? '',
      productName: productJson['product_name'] ?? productJson['name'] ?? '',
      slug: productJson['slug'] ?? '',
      productImage: bestImage ?? '',
      isSaved: json['is_saved'] ?? true,
      variants: productJson['variants'] != null
          ? (productJson['variants'] as List)
                .map((v) => SharedVariantModel.fromJson(v))
                .toList()
          : [],
      rating: parsedRating,
      productViews: (productJson['product_views'] as num?)?.toInt() ?? (productJson['views'] as num?)?.toInt() ?? 0,
      productVariantId: json['product_variant_id'] as int?,
    );
  }
}

class WishlistListResponse {
  final List<WishlistItemModel> data;

  WishlistListResponse({required this.data});

  factory WishlistListResponse.fromJson(Map<String, dynamic> json) {
    return WishlistListResponse(
      data: json['data'] != null
          ? (json['data'] as List).map((i) => WishlistItemModel.fromJson(i)).toList()
          : [],
    );
  }
}
