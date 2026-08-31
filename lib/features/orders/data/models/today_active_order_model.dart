class TodayActiveOrdersResponse {
  final int status;
  final String message;
  final List<TodayActiveOrderItemModel> data;
  final TodayActiveOrdersPagination? pagination;

  TodayActiveOrdersResponse({
    required this.status,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory TodayActiveOrdersResponse.fromJson(Map<String, dynamic> json) {
    return TodayActiveOrdersResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) =>
                  TodayActiveOrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? TodayActiveOrdersPagination.fromJson(
              json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }
}

class TodayActiveOrderItemModel {
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
  final String? deliverySeason;
  final double grandTotal;
  final int totalItems;
  final String paymentMode;
  final String paymentStatus;
  final String orderStatus;
  final String? slotStartTime;
  final String? slotEndTime;
  final String? deliveryDate;
  final String createdAt;
  final String? firstItemImage;

  TodayActiveOrderItemModel({
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
    this.deliverySeason,
    required this.grandTotal,
    required this.totalItems,
    required this.paymentMode,
    required this.paymentStatus,
    required this.orderStatus,
    this.slotStartTime,
    this.slotEndTime,
    this.deliveryDate,
    required this.createdAt,
    this.firstItemImage,
  });

  factory TodayActiveOrderItemModel.fromJson(Map<String, dynamic> json) {
    return TodayActiveOrderItemModel(
      id: json['id'] ?? 0,
      uuId: json['uu_id'] ?? '',
      totalAmount: (json['total_amount'] != null)
          ? double.tryParse(json['total_amount'].toString()) ?? 0.0
          : 0.0,
      couponCode: json['coupon_code'] as String?,
      couponDiscount: (json['coupon_discount'] != null)
          ? double.tryParse(json['coupon_discount'].toString()) ?? 0.0
          : 0.0,
      walletPointsUsed: json['wallet_points_used'] is int
          ? json['wallet_points_used']
          : int.tryParse(json['wallet_points_used']?.toString() ?? '0') ?? 0,
      walletDiscountAmount: (json['wallet_discount_amount'] != null)
          ? double.tryParse(json['wallet_discount_amount'].toString()) ?? 0.0
          : 0.0,
      discountedTotal: (json['discounted_total'] != null)
          ? double.tryParse(json['discounted_total'].toString()) ?? 0.0
          : 0.0,
      deliveryDistanceKm: (json['delivery_distance_km'] != null)
          ? double.tryParse(json['delivery_distance_km'].toString()) ?? 0.0
          : 0.0,
      deliveryCharge: (json['delivery_charge'] != null)
          ? double.tryParse(json['delivery_charge'].toString()) ?? 0.0
          : 0.0,
      deliverySeason: json['delivery_season'] as String?,
      grandTotal: (json['grand_total'] != null)
          ? double.tryParse(json['grand_total'].toString()) ?? 0.0
          : 0.0,
      totalItems: json['total_items'] is int
          ? json['total_items']
          : int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      paymentMode: json['payment_mode'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      orderStatus: json['order_status'] ?? '',
      slotStartTime: json['slot_start_time'] as String?,
      slotEndTime: json['slot_end_time'] as String?,
      deliveryDate: json['delivery_date'] as String?,
      createdAt: json['created_at'] ?? '',
      firstItemImage: json['first_item_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uu_id': uuId,
      'total_amount': totalAmount,
      'coupon_code': couponCode,
      'coupon_discount': couponDiscount,
      'wallet_points_used': walletPointsUsed,
      'wallet_discount_amount': walletDiscountAmount,
      'discounted_total': discountedTotal,
      'delivery_distance_km': deliveryDistanceKm,
      'delivery_charge': deliveryCharge,
      'delivery_season': deliverySeason,
      'grand_total': grandTotal,
      'total_items': totalItems,
      'payment_mode': paymentMode,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'slot_start_time': slotStartTime,
      'slot_end_time': slotEndTime,
      'delivery_date': deliveryDate,
      'created_at': createdAt,
      'first_item_image': firstItemImage,
    };
  }
}

class TodayActiveOrdersPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPages;

  TodayActiveOrdersPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory TodayActiveOrdersPagination.fromJson(Map<String, dynamic> json) {
    return TodayActiveOrdersPagination(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 10,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'per_page': perPage,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }
}
