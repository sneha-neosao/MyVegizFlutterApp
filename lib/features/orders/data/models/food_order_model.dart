class FoodOrderListItemModel {
  final int id;
  final String uuId;
  final double totalAmount;
  final String? couponCode;
  final double couponDiscount;
  final int walletPointsUsed;
  final double walletDiscountAmount;
  final double discountedTotal;
  final double deliveryDistanceKm;
  final double deliveryCharge;
  final double packingCharge;
  final String? deliverySeason;
  final double grandTotal;
  final int totalItems;
  final String paymentMode;
  final String paymentStatus;
  final String orderStatus;
  final String? deliveryDate;
  final String? deliveredAt;
  final String createdAt;
  final String? firstItemImage;
  final FoodOrderVendorModel? vendor;
  final double rating;
  final bool isRated;
  final String? customerNote;

  FoodOrderListItemModel({
    required this.id,
    required this.uuId,
    required this.totalAmount,
    this.couponCode,
    required this.couponDiscount,
    required this.walletPointsUsed,
    required this.walletDiscountAmount,
    required this.discountedTotal,
    required this.deliveryDistanceKm,
    required this.deliveryCharge,
    required this.packingCharge,
    this.deliverySeason,
    required this.grandTotal,
    required this.totalItems,
    required this.paymentMode,
    required this.paymentStatus,
    required this.orderStatus,
    this.deliveryDate,
    this.deliveredAt,
    required this.createdAt,
    this.firstItemImage,
    this.vendor,
    required this.rating,
    required this.isRated,
    this.customerNote,
  });

  factory FoodOrderListItemModel.fromJson(Map<String, dynamic> json) {
    return FoodOrderListItemModel(
      id: json['id'] ?? 0,
      uuId: json['uu_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      couponCode: json['coupon_code'],
      couponDiscount: (json['coupon_discount'] ?? 0.0).toDouble(),
      walletPointsUsed: json['wallet_points_used'] ?? 0,
      walletDiscountAmount: (json['wallet_discount_amount'] ?? 0.0).toDouble(),
      discountedTotal: (json['discounted_total'] ?? 0.0).toDouble(),
      deliveryDistanceKm: (json['delivery_distance_km'] ?? 0.0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0.0).toDouble(),
      packingCharge: (json['packing_charge'] ?? 0.0).toDouble(),
      deliverySeason: json['delivery_season'],
      grandTotal: (json['grand_total'] ?? 0.0).toDouble(),
      totalItems: json['total_items'] ?? 0,
      paymentMode: json['payment_mode'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      orderStatus: json['order_status'] ?? '',
      deliveryDate: json['delivery_date'],
      deliveredAt: json['delivered_at'],
      createdAt: json['created_at'] ?? '',
      firstItemImage: json['first_item_image'],
      vendor: json['vendor'] != null
          ? FoodOrderVendorModel.fromJson(
              json['vendor'] as Map<String, dynamic>,
            )
          : null,
      rating: json['rating'] != null
          ? (double.tryParse(json['rating'].toString()) ?? 0.0)
          : 0.0,
      isRated: json['is_rated'] != null
          ? (json['is_rated'] == true ||
                json['is_rated'] == 1 ||
                json['is_rated'].toString() == '1' ||
                json['is_rated'].toString() == 'true')
          : (json['rating'] != null &&
                (double.tryParse(json['rating'].toString()) ?? 0.0) > 0),
      customerNote: json['customer_note'] as String?,
    );
  }
}

class FoodOrderListResponse {
  final List<FoodOrderListItemModel> orders;
  final int total;
  final int currentPage;
  final int totalPages;

  FoodOrderListResponse({
    required this.orders,
    required this.total,
    required this.currentPage,
    required this.totalPages,
  });

  factory FoodOrderListResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] ?? {};
    return FoodOrderListResponse(
      orders:
          (json['data'] as List<dynamic>?)
              ?.map(
                (e) =>
                    FoodOrderListItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      total: pagination['total'] ?? 0,
      currentPage: pagination['current_page'] ?? 1,
      totalPages: pagination['total_pages'] ?? 1,
    );
  }
}

class FoodOrderDetailsModel {
  final int id;
  final String uuId;
  final double totalAmount;
  final String? couponCode;
  final double couponDiscount;
  final int walletPointsUsed;
  final double walletDiscountAmount;
  final double discountedTotal;
  final double deliveryDistanceKm;
  final double deliveryCharge;
  final double packingCharge;
  final String? deliverySeason;
  final double grandTotal;
  final int totalItems;
  final String paymentMode;
  final String paymentStatus;
  final double platformCharges;
  final String orderStatus;
  final String createdAt;
  final String? deliveryDate;
  final String? deliveredAt;
  final FoodOrderDeliveryDetailsModel? deliveryDetails;
  final List<FoodOrderDetailsItemModel> items;
  final List<FoodOrderStatusLogModel> statusLogs;
  final FoodOrderVendorModel? vendor;
  final String? customerNote;

  FoodOrderDetailsModel({
    required this.id,
    required this.uuId,
    required this.totalAmount,
    this.couponCode,
    required this.couponDiscount,
    required this.walletPointsUsed,
    required this.walletDiscountAmount,
    required this.discountedTotal,
    required this.deliveryDistanceKm,
    required this.deliveryCharge,
    required this.packingCharge,
    this.deliverySeason,
    required this.grandTotal,
    required this.totalItems,
    required this.paymentMode,
    required this.paymentStatus,
    required this.platformCharges,
    required this.orderStatus,
    required this.createdAt,
    this.deliveryDate,
    this.deliveredAt,
    this.deliveryDetails,
    required this.items,
    required this.statusLogs,
    this.vendor,
    this.customerNote,
  });

  factory FoodOrderDetailsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return FoodOrderDetailsModel(
      id: data['id'] ?? 0,
      uuId: data['uu_id'] ?? '',
      totalAmount: (data['total_amount'] ?? 0.0).toDouble(),
      couponCode: data['coupon_code'],
      couponDiscount: (data['coupon_discount'] ?? 0.0).toDouble(),
      walletPointsUsed: data['wallet_points_used'] ?? 0,
      walletDiscountAmount: (data['wallet_discount_amount'] ?? 0.0).toDouble(),
      discountedTotal: (data['discounted_total'] ?? 0.0).toDouble(),
      deliveryDistanceKm: (data['delivery_distance_km'] ?? 0.0).toDouble(),
      deliveryCharge: (data['delivery_charge'] ?? 0.0).toDouble(),
      packingCharge: (data['packing_charge'] ?? 0.0).toDouble(),
      deliverySeason: data['delivery_season'],
      platformCharges: (data['platform_charges'] ?? 0.0).toDouble(),
      grandTotal: (data['grand_total'] ?? 0.0).toDouble(),
      totalItems: data['total_items'] ?? 0,
      paymentMode: data['payment_mode'] ?? '',
      paymentStatus: data['payment_status'] ?? '',
      orderStatus: data['order_status'] ?? '',
      createdAt: data['created_at'] ?? '',
      deliveryDate: data['delivery_date'],
      deliveredAt: data['delivered_at'],
      deliveryDetails: data['delivery_details'] != null
          ? FoodOrderDeliveryDetailsModel.fromJson(
              data['delivery_details'] as Map<String, dynamic>,
            )
          : (data['delivery_name'] != null
                ? FoodOrderDeliveryDetailsModel(
                    name: data['delivery_name'] ?? '',
                    phone: data['delivery_phone'] ?? '',
                    address: data['delivery_address'] ?? '',
                    pincode: data['delivery_pincode'] ?? '',
                  )
                : null),
      items:
          (data['items'] as List<dynamic>?)
              ?.map(
                (e) => FoodOrderDetailsItemModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      statusLogs:
          (data['status_logs'] as List<dynamic>?)
              ?.map(
                (e) =>
                    FoodOrderStatusLogModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      vendor: data['vendor'] != null
          ? FoodOrderVendorModel.fromJson(
              data['vendor'] as Map<String, dynamic>,
            )
          : null,
      customerNote: data['customer_note'] as String?,
    );
  }
}

class FoodOrderVendorModel {
  final int id;
  final String uuId;
  final String entityName;
  final String? entityImage;
  final double? lat;
  final double? lng;

  FoodOrderVendorModel({
    required this.id,
    required this.uuId,
    required this.entityName,
    this.entityImage,
    this.lat,
    this.lng,
  });

  factory FoodOrderVendorModel.fromJson(Map<String, dynamic> json) {
    return FoodOrderVendorModel(
      id: json['id'] ?? 0,
      uuId: json['uu_id'] ?? json['vendor_uu_id'] ?? '',
      entityName: json['entity_name'] ?? '',
      entityImage: json['entity_image'],
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}

class FoodOrderDeliveryDetailsModel {
  final String name;
  final String phone;
  final String address;
  final String pincode;
  final double? lat;
  final double? lng;

  FoodOrderDeliveryDetailsModel({
    required this.name,
    required this.phone,
    required this.address,
    required this.pincode,
    this.lat,
    this.lng,
  });

  factory FoodOrderDeliveryDetailsModel.fromJson(Map<String, dynamic> json) {
    return FoodOrderDeliveryDetailsModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      pincode: json['pincode'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}

class FoodOrderDetailsItemModel {
  final int itemId;
  final String vendorItemName;
  final String variantName;
  final int quantity;
  final double price;
  final double totalPrice;
  final List<String> images;

  FoodOrderDetailsItemModel({
    required this.itemId,
    required this.vendorItemName,
    required this.variantName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.images,
  });

  factory FoodOrderDetailsItemModel.fromJson(Map<String, dynamic> json) {
    return FoodOrderDetailsItemModel(
      itemId: json['item_id'] ?? 0,
      vendorItemName: json['vendor_item_name'] ?? '',
      variantName: json['variant_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class FoodOrderStatusLogModel {
  final String? fromStatus;
  final String toStatus;
  final String changedBy;
  final String note;
  final String createdAt;

  FoodOrderStatusLogModel({
    this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    required this.note,
    required this.createdAt,
  });

  factory FoodOrderStatusLogModel.fromJson(Map<String, dynamic> json) {
    return FoodOrderStatusLogModel(
      fromStatus: json['from_status'],
      toStatus: json['to_status'] ?? '',
      changedBy: json['changed_by'] ?? '',
      note: json['note'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class FoodCancelOrderResponseModel {
  final int orderId;
  final String uuId;
  final String fromStatus;
  final String toStatus;
  final String orderStatus;
  final String paymentStatus;

  FoodCancelOrderResponseModel({
    required this.orderId,
    required this.uuId,
    required this.fromStatus,
    required this.toStatus,
    required this.orderStatus,
    required this.paymentStatus,
  });

  factory FoodCancelOrderResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return FoodCancelOrderResponseModel(
      orderId: data['order_id'] ?? 0,
      uuId: data['uu_id'] ?? '',
      fromStatus: data['from_status'] ?? '',
      toStatus: data['to_status'] ?? '',
      orderStatus: data['order_status'] ?? '',
      paymentStatus: data['payment_status'] ?? '',
    );
  }
}
