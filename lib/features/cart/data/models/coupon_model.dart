class CouponModel {
  final String couponCode;
  final String? couponType;
  final double? discValue;
  final double? capLimit;
  final double? orderValue;
  final String? couponDescription;
  final String? termscondition;
  final String? expiryDate;
  final bool isApplicable;
  final double? discountPreview;
  final double? minOrderNeeded;

  CouponModel({
    required this.couponCode,
    this.couponType,
    this.discValue,
    this.capLimit,
    this.orderValue,
    this.couponDescription,
    this.termscondition,
    this.expiryDate,
    required this.isApplicable,
    this.discountPreview,
    this.minOrderNeeded,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
        couponCode: json["coupon_code"] ?? "",
        couponType: json["coupon_type"],
        discValue: (json["disc_value"] as num?)?.toDouble(),
        capLimit: (json["cap_limit"] as num?)?.toDouble(),
        orderValue: (json["order_value"] as num?)?.toDouble(),
        couponDescription: json["coupon_description"],
        termscondition: json["termscondition"],
        expiryDate: json["expiry_date"],
        isApplicable: json["is_applicable"] ?? false,
        discountPreview: (json["discount_preview"] as num?)?.toDouble(),
        minOrderNeeded: (json["min_order_needed"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "coupon_code": couponCode,
        "coupon_type": couponType,
        "disc_value": discValue,
        "cap_limit": capLimit,
        "order_value": orderValue,
        "coupon_description": couponDescription,
        "termscondition": termscondition,
        "expiry_date": expiryDate,
        "is_applicable": isApplicable,
        "discount_preview": discountPreview,
        "min_order_needed": minOrderNeeded,
      };
}

class CouponListResponse {
  final int status;
  final String message;
  final List<CouponModel>? data;

  CouponListResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CouponListResponse.fromJson(Map<String, dynamic> json) =>
      CouponListResponse(
        status: json["status"] ?? 0,
        message: json["message"] ?? "",
        data: json["data"] != null
            ? List<CouponModel>.from(
                json["data"].map((x) => CouponModel.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.map((x) => x.toJson()).toList(),
      };
}

class ApplyCouponResponse {
  final int status;
  final String message;
  final ApplyCouponData? data;

  ApplyCouponResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ApplyCouponResponse.fromJson(Map<String, dynamic> json) =>
      ApplyCouponResponse(
        status: json["status"] ?? 0,
        message: json["message"] ?? "",
        data: json["data"] != null
            ? ApplyCouponData.fromJson(json["data"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class ApplyCouponData {
  final double? productsTotal;
  final String? couponCode;
  final String? couponType;
  final double? discountAmount;
  final double? discountedTotal;

  ApplyCouponData({
    this.productsTotal,
    this.couponCode,
    this.couponType,
    this.discountAmount,
    this.discountedTotal,
  });

  factory ApplyCouponData.fromJson(Map<String, dynamic> json) =>
      ApplyCouponData(
        productsTotal: (json["products_total"] as num?)?.toDouble(),
        couponCode: json["coupon_code"],
        couponType: json["coupon_type"],
        discountAmount: (json["discount_amount"] as num?)?.toDouble(),
        discountedTotal: (json["discounted_total"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "products_total": productsTotal,
        "coupon_code": couponCode,
        "coupon_type": couponType,
        "discount_amount": discountAmount,
        "discounted_total": discountedTotal,
      };
}

class ValidateCouponResponse {
  final int status;
  final ApplyCouponData? data;

  ValidateCouponResponse({
    required this.status,
    this.data,
  });

  factory ValidateCouponResponse.fromJson(Map<String, dynamic> json) =>
      ValidateCouponResponse(
        status: json["status"] ?? 0,
        data: json["data"] != null
            ? ApplyCouponData.fromJson(json["data"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": data?.toJson(),
      };
}
