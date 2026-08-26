import 'package:my_vegiz_flutter/core/utils/logger.dart';

class OrderListItemModel {
  final int id;
  final String uuId;
  final double totalAmount;
  final String? couponCode;
  final double couponDiscount;
  final double discountedTotal;
  final double deliveryDistanceKm;
  final double deliveryCharge;
  final double grandTotal;
  final int totalItems;
  final String paymentMode;
  final String paymentStatus;
  final String orderStatus;
  final String? slotStartTime;
  final String? slotEndTime;
  final String? deliveryDate;
  final String createdAt;
  final String mainCategorySlug; // Added for filtering
  final List<OrderDetailsItemModel> items;
  final double rating;
  final bool isRated;
  final String? customerNote;

  OrderListItemModel({
    required this.id,
    required this.uuId,
    required this.totalAmount,
    this.couponCode,
    required this.couponDiscount,
    required this.discountedTotal,
    required this.deliveryDistanceKm,
    required this.deliveryCharge,
    required this.grandTotal,
    required this.totalItems,
    required this.paymentMode,
    required this.paymentStatus,
    required this.orderStatus,
    this.slotStartTime,
    this.slotEndTime,
    this.deliveryDate,
    required this.createdAt,
    required this.mainCategorySlug,
    required this.items,
    required this.rating,
    required this.isRated,
    this.customerNote,
  });

  factory OrderListItemModel.fromJson(Map<String, dynamic> json) {
    return OrderListItemModel(
      id: json['id'] ?? 0,
      uuId: json['uu_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      couponCode: json['coupon_code'],
      couponDiscount: (json['coupon_discount'] ?? 0.0).toDouble(),
      discountedTotal: (json['discounted_total'] ?? 0.0).toDouble(),
      deliveryDistanceKm: (json['delivery_distance_km'] ?? 0.0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0.0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0.0).toDouble(),
      totalItems: json['total_items'] ?? 0,
      paymentMode: json['payment_mode'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      orderStatus: json['order_status'] ?? '',
      slotStartTime: json['slot_start_time'],
      slotEndTime: json['slot_end_time'],
      deliveryDate: json['delivery_date'],
      createdAt: json['created_at'] ?? '',
      mainCategorySlug: json['main_category_slug'] ?? 'grocery-vegetables',
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) =>
                    OrderDetailsItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
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

class OrderListResponse {
  final List<OrderListItemModel> orders;

  OrderListResponse({required this.orders});

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      orders:
          (json['data'] as List<dynamic>?)
              ?.map(
                (e) => OrderListItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class OrderDetailsModel {
  final int id;
  final String uuId;
  final double totalAmount;
  final String? couponCode;
  final double couponDiscount;
  final double discountedTotal;
  final double deliveryDistanceKm;
  final double deliveryCharge;
  final double grandTotal;
  final int totalItems;
  final String paymentMode;
  final String paymentStatus;
  final String orderStatus;
  final String createdAt;
  final String? slotStartTime;
  final String? slotEndTime;
  final String? deliveryDate;
  final OrderDeliveryDetailsModel deliveryDetails;
  final List<OrderDetailsItemModel> items;
  final List<OrderStatusLogModel> statusLogs;
  final String? customerNote;

  OrderDetailsModel({
    required this.id,
    required this.uuId,
    required this.totalAmount,
    this.couponCode,
    required this.couponDiscount,
    required this.discountedTotal,
    required this.deliveryDistanceKm,
    required this.deliveryCharge,
    required this.grandTotal,
    required this.totalItems,
    required this.paymentMode,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    this.slotStartTime,
    this.slotEndTime,
    this.deliveryDate,
    required this.deliveryDetails,
    required this.items,
    required this.statusLogs,
    this.customerNote,
  });

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return OrderDetailsModel(
      id: data['id'] ?? 0,
      uuId: data['uu_id'] ?? '',
      totalAmount: (data['total_amount'] ?? 0.0).toDouble(),
      couponCode: data['coupon_code'],
      couponDiscount: (data['coupon_discount'] ?? 0.0).toDouble(),
      discountedTotal: (data['discounted_total'] ?? 0.0).toDouble(),
      deliveryDistanceKm: (data['delivery_distance_km'] ?? 0.0).toDouble(),
      deliveryCharge: (data['delivery_charge'] ?? 0.0).toDouble(),
      grandTotal: (data['grand_total'] ?? 0.0).toDouble(),
      totalItems: data['total_items'] ?? 0,
      paymentMode: data['payment_mode'] ?? '',
      paymentStatus: data['payment_status'] ?? '',
      orderStatus: data['order_status'] ?? '',
      createdAt: data['created_at'] ?? '',
      slotStartTime: data['slot_start_time'],
      slotEndTime: data['slot_end_time'],
      deliveryDate: data['delivery_date'],
      deliveryDetails: OrderDeliveryDetailsModel.fromJson(
        data['delivery_details'] ?? {},
      ),
      items:
          (data['items'] as List<dynamic>?)
              ?.map(
                (e) =>
                    OrderDetailsItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      statusLogs:
          (data['status_logs'] as List<dynamic>?)
              ?.map(
                (e) => OrderStatusLogModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      customerNote: data['customer_note'] as String?,
    );
  }
}

class OrderDeliveryDetailsModel {
  final String name;
  final String phone;
  final String address;
  final String pincode;
  final double? lat;
  final double? lng;

  OrderDeliveryDetailsModel({
    required this.name,
    required this.phone,
    required this.address,
    required this.pincode,
    this.lat,
    this.lng,
  });

  factory OrderDeliveryDetailsModel.fromJson(Map<String, dynamic> json) {
    return OrderDeliveryDetailsModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      pincode: json['pincode'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}

class OrderDetailsItemModel {
  final int id;
  final String productName;
  final String variantName;
  final String uomName;
  final int quantity;
  final double price;
  final double totalPrice;
  final List<String> images;

  OrderDetailsItemModel({
    required this.id,
    required this.productName,
    required this.variantName,
    required this.uomName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.images,
  });

  // factory OrderDetailsItemModel.fromJson(Map<String, dynamic> json) {
  //   return OrderDetailsItemModel(
  //     id: json['id'] ?? json['item_id'] ?? 0,
  //     productName: json['product_name'] ?? '',
  //     variantName: json['variant_name'] ?? '',
  //     uomName: json['uom_name'] ?? '',
  //     quantity: json['quantity'] ?? 0,
  //     price: (json['price'] ?? 0.0).toDouble(),
  //     totalPrice: (json['total_price'] ?? 0.0).toDouble(),
  //     images:
  //         (json['images'] as List<dynamic>?)
  //             ?.map((e) => e.toString())
  //             .toList() ??
  //         [],
  //   );
  // }
  factory OrderDetailsItemModel.fromJson(Map<String, dynamic> json) {
    logger.d('Order Item Json => $json');

    return OrderDetailsItemModel(
      id: json['id'] ?? json['item_id'] ?? 0,
      productName: json['product_name'] ?? '',
      variantName: json['variant_name'] ?? '',
      uomName: json['uom_name'] ?? '',
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

class OrderStatusLogModel {
  final String? fromStatus;
  final String toStatus;
  final String changedBy;
  final String note;
  final String createdAt;

  OrderStatusLogModel({
    this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    required this.note,
    required this.createdAt,
  });

  factory OrderStatusLogModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusLogModel(
      fromStatus: json['from_status'],
      toStatus: json['to_status'] ?? '',
      changedBy: json['changed_by'] ?? '',
      note: json['note'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CancelOrderResponseModel {
  final int orderId;
  final String uuId;
  final String fromStatus;
  final String toStatus;
  final String orderStatus;
  final String paymentStatus;

  CancelOrderResponseModel({
    required this.orderId,
    required this.uuId,
    required this.fromStatus,
    required this.toStatus,
    required this.orderStatus,
    required this.paymentStatus,
  });

  factory CancelOrderResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return CancelOrderResponseModel(
      orderId: data['order_id'] ?? 0,
      uuId: data['uu_id'] ?? '',
      fromStatus: data['from_status'] ?? '',
      toStatus: data['to_status'] ?? '',
      orderStatus: data['order_status'] ?? '',
      paymentStatus: data['payment_status'] ?? '',
    );
  }
}
