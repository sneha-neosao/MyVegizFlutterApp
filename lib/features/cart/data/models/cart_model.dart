class CartResponse {
  final int status;
  final String message;
  final CartData? data;

  CartResponse({required this.status, required this.message, this.data});

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
    status: json["status"] ?? 0,
    message: json["message"] ?? "",
    data: json["data"] != null ? CartData.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class CartData {
  final int? cartId;
  final int? productVariantId;
  final int? cartItemId;
  final int? quantity;
  final double? price;
  final double? totalPrice;
  final double? totalAmount;
  final double? productsTotal;
  final double? grandTotal;
  final int? totalItems;
  final DeliveryInfo? deliveryInfo;
  final CartItem? item;
  final List<CartItem>? items;

  // Coupon fields
  final String? couponCode;
  final String? couponType;
  final double? discountAmount;
  final double? discountedTotal;
  final int? walletPointsUsed;
  final double? walletDiscountAmount;
  final int? appliedWalletPoints;

  // New detailed bill fields
  final double? mrpTotal;
  final double? productDiscount;
  final double? taxAmount;
  final double? packingCharge;

  final String? autoAssignMode;

  CartData({
    this.cartId,
    this.productVariantId,
    this.cartItemId,
    this.quantity,
    this.price,
    this.totalPrice,
    this.totalAmount,
    this.productsTotal,
    this.grandTotal,
    this.totalItems,
    this.deliveryInfo,
    this.item,
    this.items,
    this.couponCode,
    this.couponType,
    this.discountAmount,
    this.discountedTotal,
    this.walletPointsUsed,
    this.walletDiscountAmount,
    this.appliedWalletPoints,
    this.mrpTotal,
    this.productDiscount,
    this.taxAmount,
    this.packingCharge,
    this.autoAssignMode,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    // Try to find the items list in various possible keys
    var itemsList = json["items"] ?? json["cart_items"] ?? json["products"];

    List<CartItem>? parsedItems;
    if (itemsList != null && itemsList is List) {
      parsedItems = List<CartItem>.from(
        itemsList.map((x) => CartItem.fromJson(x)),
      );
    }

    // If items list is empty but 'item' exists, use it
    if ((parsedItems == null || parsedItems.isEmpty) && json["item"] != null) {
      parsedItems = [CartItem.fromJson(json["item"])];
    }

    return CartData(
      cartId: json["cart_id"],
      productVariantId: json["product_variant_id"],
      cartItemId: json["cart_item_id"],
      quantity: json["quantity"],
      price: (json["price"] as num?)?.toDouble(),
      totalPrice: (json["total_price"] as num?)?.toDouble(),
      totalAmount: (json["total_amount"] as num?)?.toDouble(),
      productsTotal: (json["products_total"] as num?)?.toDouble(),
      grandTotal: (json["grand_total"] as num?)?.toDouble(),
      totalItems: json["total_items"],
      deliveryInfo: json["delivery_info"] != null
          ? DeliveryInfo.fromJson(json["delivery_info"])
          : null,
      item: json["item"] != null ? CartItem.fromJson(json["item"]) : null,
      items: parsedItems,
      couponCode:
          json["coupon_code"] ??
          json["applied_coupon"]?["coupon_code"] ??
          json["coupon"]?["coupon_code"] ??
          json["applied_coupon_code"],
      couponType:
          json["coupon_type"] ??
          json["applied_coupon"]?["coupon_type"] ??
          json["coupon"]?["coupon_type"],
      discountAmount:
          (json["discount_amount"] as num?)?.toDouble() ??
          (json["coupon_discount"] as num?)?.toDouble() ??
          (json["applied_coupon"]?["discount_amount"] as num?)?.toDouble(),
      discountedTotal:
          (json["discounted_total"] as num?)?.toDouble() ??
          (json["applied_coupon"]?["discounted_total"] as num?)?.toDouble(),
      walletPointsUsed:
          (json["wallet_points_used"] as num?)?.toInt() ??
          (json["applied_wallet_points"] as num?)?.toInt() ??
          (json["wallet_points"] as num?)?.toInt() ??
          (json["points_used"] as num?)?.toInt(),
      walletDiscountAmount:
          (json["wallet_discount_amount"] as num?)?.toDouble() ??
          (json["wallet_discount"] as num?)?.toDouble(),
      appliedWalletPoints: (json["applied_wallet_points"] as num?)?.toInt(),
      mrpTotal:
          (json["mrp_total"] as num?)?.toDouble() ??
          (json["total_mrp"] as num?)?.toDouble(),
      productDiscount:
          (json["product_discount"] as num?)?.toDouble() ??
          (json["total_product_discount"] as num?)?.toDouble() ??
          (json["savings"] as num?)?.toDouble(),
      taxAmount:
          (json["tax_amount"] as num?)?.toDouble() ??
          (json["total_tax"] as num?)?.toDouble(),
      packingCharge: (json["packing_charge"] as num?)?.toDouble(),
      autoAssignMode: json["auto_assign_mode"],
    );
  }

  Map<String, dynamic> toJson() => {
    "cart_id": cartId,
    "product_variant_id": productVariantId,
    "cart_item_id": cartItemId,
    "quantity": quantity,
    "price": price,
    "total_price": totalPrice,
    "total_amount": totalAmount,
    "products_total": productsTotal,
    "grand_total": grandTotal,
    "total_items": totalItems,
    "delivery_info": deliveryInfo?.toJson(),
    "item": item?.toJson(),
    "items": items?.map((x) => x.toJson()).toList(),
    "coupon_code": couponCode,
    "coupon_type": couponType,
    "discount_amount": discountAmount,
    "discounted_total": discountedTotal,
    "wallet_points_used": walletPointsUsed,
    "wallet_discount_amount": walletDiscountAmount,
    "applied_wallet_points": appliedWalletPoints,
    "tax_amount": taxAmount,
    "packing_charge": packingCharge,
    "auto_assign_mode": autoAssignMode,
  };
}

class DeliveryInfo {
  final double distanceKm;
  final double freeKm;
  final double perKmCharge;
  final double deliveryCharge;
  final bool isFree;
  final String? seasonName;

  DeliveryInfo({
    required this.distanceKm,
    required this.freeKm,
    required this.perKmCharge,
    required this.deliveryCharge,
    required this.isFree,
    this.seasonName,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) => DeliveryInfo(
    distanceKm: (json["distance_km"] as num?)?.toDouble() ?? 0.0,
    freeKm: (json["free_km"] as num?)?.toDouble() ?? 0.0,
    perKmCharge: (json["per_km_charge"] as num?)?.toDouble() ?? 0.0,
    deliveryCharge: (json["delivery_charge"] as num?)?.toDouble() ?? 0.0,
    isFree: json["is_free"] ?? false,
    seasonName: json["season_name"],
  );

  Map<String, dynamic> toJson() => {
    "distance_km": distanceKm,
    "free_km": freeKm,
    "per_km_charge": perKmCharge,
    "delivery_charge": deliveryCharge,
    "is_free": isFree,
    "season_name": seasonName,
  };
}

class CartItem {
  final int id;
  final int productVariantId;
  final int quantity;
  final double price;
  final double totalPrice;
  final String variantUuId;
  final double sellingPrice;
  final double actualPrice;
  final String subUomName;
  final String subUomShortName;
  final double conversionFactor;
  final String uomName;
  final String uomShortName;
  final CartProduct? product;
  final String? vendorItemId;
  final String? vendorItem;
  final double? variantQty;
  final int? addonId;
  final Map<String, dynamic>? addonData;

  CartItem({
    required this.id,
    required this.productVariantId,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.variantUuId,
    required this.sellingPrice,
    required this.actualPrice,
    required this.subUomName,
    required this.subUomShortName,
    required this.conversionFactor,
    required this.uomName,
    required this.uomShortName,
    this.product,
    this.vendorItemId,
    this.vendorItem,
    this.variantQty,
    this.addonId,
    this.addonData,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json["id"] is int
        ? json["id"] as int
        : (json["id"] is String ? int.tryParse(json["id"]) ?? 0 : 0),
    productVariantId: json["product_variant_id"] is int
        ? json["product_variant_id"] as int
        : (json["product_variant_id"] is String &&
                  json["product_variant_id"].isNotEmpty
              ? int.tryParse(json["product_variant_id"]) ?? 0
              : 0),
    quantity: json["quantity"] is int
        ? json["quantity"] as int
        : (json["quantity"] is String
              ? int.tryParse(json["quantity"]) ?? 0
              : 0),
    price: json["price"] is num
        ? (json["price"] as num).toDouble()
        : (json["price"] is String
              ? double.tryParse(json["price"]) ?? 0.0
              : 0.0),
    totalPrice: json["total_price"] is num
        ? (json["total_price"] as num).toDouble()
        : (json["total_price"] is String
              ? double.tryParse(json["total_price"]) ?? 0.0
              : 0.0),
    variantUuId: json["variant_uu_id"] ?? "",
    sellingPrice: json["selling_price"] is num
        ? (json["selling_price"] as num).toDouble()
        : (json["selling_price"] is String
              ? double.tryParse(json["selling_price"]) ?? 0.0
              : 0.0),
    actualPrice: json["actual_price"] is num
        ? (json["actual_price"] as num).toDouble()
        : (json["actual_price"] is String
              ? double.tryParse(json["actual_price"]) ?? 0.0
              : 0.0),
    subUomName: json["sub_uom_name"] ??
        (json["product_variant"] is Map<String, dynamic>
            ? json["product_variant"]["sub_uom_name"]
            : (json["variant"] is Map<String, dynamic>
                ? json["variant"]["sub_uom_name"]
                : null)) ??
        "",
    subUomShortName: json["sub_uom_short_name"] ??
        (json["product_variant"] is Map<String, dynamic>
            ? json["product_variant"]["sub_uom_short_name"]
            : (json["variant"] is Map<String, dynamic>
                ? json["variant"]["sub_uom_short_name"]
                : null)) ??
        "",
    conversionFactor: json["conversion_factor"] is num
        ? (json["conversion_factor"] as num).toDouble()
        : (json["conversion_factor"] is String &&
                  json["conversion_factor"].isNotEmpty
              ? double.tryParse(json["conversion_factor"]) ?? 0.0
              : 0.0),
    uomName: json["uom_name"] ??
        (json["product_variant"] is Map<String, dynamic>
            ? json["product_variant"]["uom_name"]
            : (json["variant"] is Map<String, dynamic>
                ? json["variant"]["uom_name"]
                : null)) ??
        "",
    uomShortName: json["uom_short_name"] ??
        (json["product_variant"] is Map<String, dynamic>
            ? json["product_variant"]["uom_short_name"]
            : (json["variant"] is Map<String, dynamic>
                ? json["variant"]["uom_short_name"]
                : null)) ??
        "",
    product: json["product"] != null && json["product"] is Map<String, dynamic>
        ? CartProduct.fromJson(json["product"])
        : (json["product_name"] != null &&
                  json["product_name"] is String &&
                  json["product_name"].isNotEmpty
              ? CartProduct.fromJson(json)
              : null),
    vendorItemId: json["vendor_item_id"],
    vendorItem: json["vendor_item"],
    variantQty: (json["variant_qty"] as num?)?.toDouble() ??
        (json["variant_quantity"] as num?)?.toDouble() ??
        (json["product_variant"] is Map<String, dynamic>
            ? (json["product_variant"]["quantity"] as num?)?.toDouble()
            : (json["variant"] is Map<String, dynamic>
                ? (json["variant"]["quantity"] as num?)?.toDouble()
                : null)),
    addonId: json["addon_id"],
    addonData: json["addon_data"],
  );

  String get variantLabel {
    String qtyStr = '';
    if (variantQty != null && variantQty! > 0) {
      qtyStr = variantQty! % 1 == 0
          ? variantQty!.toInt().toString()
          : variantQty!.toString();
    } else if (conversionFactor > 0) {
      qtyStr = conversionFactor % 1 == 0
          ? conversionFactor.toInt().toString()
          : conversionFactor.toString();
    }

    final subUom = subUomShortName.isNotEmpty
        ? subUomShortName
        : (subUomName.isNotEmpty
            ? subUomName
            : (uomShortName.isNotEmpty
                ? uomShortName
                : uomName));

    final label = '$qtyStr $subUom'.trim();
    return label.isNotEmpty ? label : (subUom.isNotEmpty ? subUom : '');
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_variant_id": productVariantId,
    "quantity": quantity,
    "price": price,
    "total_price": totalPrice,
    "variant_uu_id": variantUuId,
    "selling_price": sellingPrice,
    "actual_price": actualPrice,
    "sub_uom_name": subUomName,
    "sub_uom_short_name": subUomShortName,
    "conversion_factor": conversionFactor,
    "uom_name": uomName,
    "uom_short_name": uomShortName,
    "product": product?.toJson(),
    "vendor_item_id": vendorItemId,
    "vendor_item": vendorItem,
    "variant_qty": variantQty,
    "addon_id": addonId,
    "addon_data": addonData,
  };
}

class CartProduct {
  final int id;
  final String uuId;
  final String productName;
  final String slug;
  final String productImage;
  final List<CartProductImage> images;

  CartProduct({
    required this.id,
    required this.uuId,
    required this.productName,
    required this.slug,
    required this.productImage,
    required this.images,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) => CartProduct(
    id: json["id"] ?? 0,
    uuId: json["uu_id"] ?? "",
    productName: json["product_name"] ?? "",
    slug: json["slug"] ?? "",
    productImage: json["product_image"] ?? "",
    images: json["images"] != null
        ? List<CartProductImage>.from(
            json["images"].map((x) => CartProductImage.fromJson(x)),
          )
        : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uu_id": uuId,
    "product_name": productName,
    "slug": slug,
    "product_image": productImage,
    "images": images.map((x) => x.toJson()).toList(),
  };
}

class CartProductImage {
  final int id;
  final String productImage;
  final bool isPrimary;
  final String publicId;

  CartProductImage({
    required this.id,
    required this.productImage,
    required this.isPrimary,
    required this.publicId,
  });

  factory CartProductImage.fromJson(Map<String, dynamic> json) =>
      CartProductImage(
        id: json["id"] ?? 0,
        productImage: json["product_image"] ?? "",
        isPrimary: json["is_primary"] ?? false,
        publicId: json["public_id"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_image": productImage,
    "is_primary": isPrimary,
    "public_id": publicId,
  };
}
