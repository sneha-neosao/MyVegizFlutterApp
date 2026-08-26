class SharedVariantModel {
  final int? id;
  final String? uuId;
  final double? actualPrice;
  final double? sellingPrice;
  final double? quantity;
  final int? uomId;
  final String? uomName;
  final String? uomShortName;
  final int? subUomId;
  final String? subUomName;
  final String? subUomShortName;
  final double? conversionFactor;
  final bool isDeliverable;
  final bool isInCart;
  final String? zoneName;
  final int cartQuantity;

  SharedVariantModel({
    this.id,
    this.uuId,
    this.actualPrice,
    this.sellingPrice,
    this.quantity,
    this.uomId,
    this.uomName,
    this.uomShortName,
    this.subUomId,
    this.subUomName,
    this.subUomShortName,
    this.conversionFactor,
    this.isDeliverable = true,
    this.isInCart = false,
    this.zoneName,
    this.cartQuantity = 0,
  });

  factory SharedVariantModel.fromJson(Map<String, dynamic> json) {
    return SharedVariantModel(
      id: json['id'],
      uuId: json['uu_id'],
      actualPrice: (json['actual_price'] as num?)?.toDouble(),
      sellingPrice: (json['selling_price'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble(),
      uomId: json['uom_id'] as int?,
      uomName: json['uom_name'],
      uomShortName: json['uom_short_name'],
      subUomId: json['sub_uom_id'] as int?,
      subUomName: json['sub_uom_name'],
      subUomShortName: json['sub_uom_short_name'],
      conversionFactor: (json['conversion_factor'] as num?)?.toDouble(),
      zoneName: json['zone_name'],
      isDeliverable: json['is_deliverable'] ?? true,
      isInCart: json['is_in_cart'] ?? false,
      cartQuantity: json['cart_quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "uu_id": uuId,
    "actual_price": actualPrice,
    "selling_price": sellingPrice,
    "quantity": quantity,
    "uom_id": uomId,
    "uom_name": uomName,
    "uom_short_name": uomShortName,
    "sub_uom_id": subUomId,
    "sub_uom_name": subUomName,
    "sub_uom_short_name": subUomShortName,
    "conversion_factor": conversionFactor,
    "zone_name": zoneName,
    "is_deliverable": isDeliverable,
    "is_in_cart": isInCart,
    "cart_quantity": cartQuantity,
  };
}

class SharedRatingModel {
  final double avgRating;
  final int totalReviews;

  SharedRatingModel({this.avgRating = 0.0, this.totalReviews = 0});

  factory SharedRatingModel.fromJson(Map<String, dynamic> json) {
    return SharedRatingModel(
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "avg_rating": avgRating,
    "total_reviews": totalReviews,
  };
}
