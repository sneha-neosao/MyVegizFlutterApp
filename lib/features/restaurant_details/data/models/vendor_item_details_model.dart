class VendorItemDetailsResponse {
  final int? status;
  final String? message;
  final VendorItemDetailsData? data;

  VendorItemDetailsResponse({
    this.status,
    this.message,
    this.data,
  });

  factory VendorItemDetailsResponse.fromJson(Map<String, dynamic> json) {
    return VendorItemDetailsResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? VendorItemDetailsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VendorItemDetailsData {
  final int? id;
  final String? uuId;
  final String? code;
  final String? itemName;
  final double? salePrice;
  final double? packingCharges;
  final int? maxOrderQuantity;
  final String? cuisineType;
  final String? description;
  final int? preparationTime;
  final int? defaultDeliveryMinutes;
  final int? totalDeliveryTime;
  final bool? itemStatus;
  final bool? isApproved;
  final bool? isActive;
  final String? createdAt;
  final VendorBriefModel? vendor;
  final CategoryBriefModel? menuCategory;
  final double? avgRating;
  final int? totalReviews;
  final int? cartQuantity;
  final bool? isCustomize;
  final List<CustomizedCategoryModel>? customizedCategories;
  final List<VendorImageModel>? images;

  VendorItemDetailsData({
    this.id,
    this.uuId,
    this.code,
    this.itemName,
    this.salePrice,
    this.packingCharges,
    this.maxOrderQuantity,
    this.cuisineType,
    this.description,
    this.preparationTime,
    this.defaultDeliveryMinutes,
    this.totalDeliveryTime,
    this.itemStatus,
    this.isApproved,
    this.isActive,
    this.createdAt,
    this.vendor,
    this.menuCategory,
    this.avgRating,
    this.totalReviews,
    this.cartQuantity,
    this.isCustomize,
    this.customizedCategories,
    this.images,
  });

  factory VendorItemDetailsData.fromJson(Map<String, dynamic> json) {
    return VendorItemDetailsData(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      code: json['code'] as String?,
      itemName: json['item_name'] as String?,
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      packingCharges: (json['packing_charges'] as num?)?.toDouble(),
      maxOrderQuantity: json['max_order_quantity'] as int?,
      cuisineType: json['cuisine_type'] as String?,
      description: json['description'] as String?,
      preparationTime: json['preparation_time'] as int?,
      defaultDeliveryMinutes: json['default_delivery_minutes'] as int?,
      totalDeliveryTime: json['total_delivery_time'] as int?,
      itemStatus: json['item_status'] as bool?,
      isApproved: json['is_approved'] as bool?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] as String?,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
      cartQuantity: json['cart_quantity'] as int?,
      isCustomize: json['is_customize'] as bool?,
      customizedCategories: json['customized_categories'] != null
          ? (json['customized_categories'] as List)
          .map((e) => CustomizedCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
      vendor: json['vendor'] != null
          ? VendorBriefModel.fromJson(json['vendor'] as Map<String, dynamic>)
          : null,
      menuCategory: json['menu_category'] != null
          ? CategoryBriefModel.fromJson(json['menu_category'] as Map<String, dynamic>)
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
          .map((e) => VendorImageModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
    );
  }
}

class VendorBriefModel {
  final int? id;
  final String? uuId;
  final String? entityName;
  final String? entityImage;
  final bool? adminIsServiceable;
  final bool? autoIsServiceable;
  final bool? isPopular;
  final String? foodType;
  final bool? isDeliverable;
  final double? distanceKm;
  final double? lat;
  final double? lng;
  final double? avgRating;
  final int? totalReviews;

  VendorBriefModel({
    this.id,
    this.uuId,
    this.entityName,
    this.entityImage,
    this.adminIsServiceable,
    this.autoIsServiceable,
    this.isPopular,
    this.foodType,
    this.isDeliverable,
    this.distanceKm,
    this.lat,
    this.lng,
    this.avgRating,
    this.totalReviews,
  });

  bool get isServiceable => adminIsServiceable == true;

  factory VendorBriefModel.fromJson(Map<String, dynamic> json) {
    return VendorBriefModel(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      entityName: json['entity_name'] as String?,
      entityImage: json['entity_image'] as String?,
      adminIsServiceable: json['admin_is_serviceable'] as bool?,
      autoIsServiceable: json['auto_is_serviceable'] as bool?,
      isPopular: json['is_popular'] as bool?,
      foodType: json['food_type'] as String?,
      isDeliverable: json['is_deliverable'] as bool?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
    );
  }
}

class CategoryBriefModel {
  final int? id;
  final String? menuCategoryName;
  final bool? isAvailable;
  final int? priority;

  CategoryBriefModel({
    this.id,
    this.menuCategoryName,
    this.isAvailable,
    this.priority,
  });

  factory CategoryBriefModel.fromJson(Map<String, dynamic> json) {
    return CategoryBriefModel(
      id: json['id'] as int?,
      menuCategoryName: json['menu_category_name'] as String?,
      isAvailable: json['is_available'] as bool?,
      priority: json['priority'] as int?,
    );
  }
}

class VendorImageModel {
  final int? id;
  final String? itemImage;
  final bool? isPrimary;
  final bool? isActive;

  VendorImageModel({
    this.id,
    this.itemImage,
    this.isPrimary,
    this.isActive,
  });

  factory VendorImageModel.fromJson(Map<String, dynamic> json) {
    return VendorImageModel(
      id: json['id'] as int?,
      itemImage: json['item_image'] as String?,
      isPrimary: json['is_primary'] as bool?,
      isActive: json['is_active'] as bool?,
    );
  }
}

class CustomizedCategoryModel {
  final int? id;
  final String? uuId;
  final String? categoryTitle;
  final String? categoryType;
  final bool? isEnabled;
  final List<LineEntryModel>? lineEntries;

  CustomizedCategoryModel({
    this.id,
    this.uuId,
    this.categoryTitle,
    this.categoryType,
    this.isEnabled,
    this.lineEntries,
  });

  factory CustomizedCategoryModel.fromJson(Map<String, dynamic> json) {
    return CustomizedCategoryModel(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      categoryTitle: json['category_title'] as String?,
      categoryType: json['category_type'] as String?,
      isEnabled: json['is_enabled'] as bool?,
      lineEntries: json['line_entries'] != null
          ? (json['line_entries'] as List)
          .map((e) => LineEntryModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
    );
  }
}

class LineEntryModel {
  final int? id;
  final String? uuId;
  final String? subCategoryTitle;
  final double? price;
  final bool? isEnabled;

  LineEntryModel({
    this.id,
    this.uuId,
    this.subCategoryTitle,
    this.price,
    this.isEnabled,
  });

  factory LineEntryModel.fromJson(Map<String, dynamic> json) {
    return LineEntryModel(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      subCategoryTitle: json['sub_category_title'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      isEnabled: json['is_enabled'] as bool?,
    );
  }
}
