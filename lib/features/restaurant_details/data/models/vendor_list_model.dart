// ─── Vendor Filters Response ─────────────────────────────────────────────────

class VendorFiltersResponse {
  final int? status;
  final String? message;
  final VendorFiltersData? data;

  VendorFiltersResponse({this.status, this.message, this.data});

  factory VendorFiltersResponse.fromJson(Map<String, dynamic> json) {
    return VendorFiltersResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? VendorFiltersData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VendorFiltersData {
  final List<VendorFilterOption>? sortOptions;
  final List<VendorFilterOption>? foodTypes;

  VendorFiltersData({this.sortOptions, this.foodTypes});

  factory VendorFiltersData.fromJson(Map<String, dynamic> json) {
    return VendorFiltersData(
      sortOptions: json['sort_options'] != null
          ? (json['sort_options'] as List)
              .map((e) => VendorFilterOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      foodTypes: json['food_types'] != null
          ? (json['food_types'] as List)
              .map((e) => VendorFilterOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class VendorFilterOption {
  final String? key;
  final String? label;

  VendorFilterOption({this.key, this.label});

  factory VendorFilterOption.fromJson(Map<String, dynamic> json) {
    return VendorFilterOption(
      key: json['key'] as String?,
      label: json['label'] as String?,
    );
  }
}

// ─── Vendor List Response ─────────────────────────────────────────────────────

class VendorListResponse {
  final int? status;
  final String? message;
  final List<VendorModel>? data;
  final VendorListPagination? pagination;

  VendorListResponse({
    this.status,
    this.message,
    this.data,
    this.pagination,
  });

  factory VendorListResponse.fromJson(Map<String, dynamic> json) {
    return VendorListResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
          .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
      pagination: json['pagination'] != null
          ? VendorListPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VendorModel {
  final int? id;
  final String? uuId;
  final String? entityName;
  final String? entityImage;
  final String? entityContact;
  final String? city;
  final String? area;
  final String? address;
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
  final List<MenuCategoryModel>? menuCategories;

  VendorModel({
    this.id,
    this.uuId,
    this.entityName,
    this.entityImage,
    this.entityContact,
    this.city,
    this.area,
    this.address,
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
    this.menuCategories,
  });

  bool get isServiceable => adminIsServiceable == true;

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      entityName: json['entity_name'] as String?,
      entityImage: json['entity_image'] as String?,
      entityContact: json['entity_contact'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      address: json['address'] as String?,
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
      menuCategories: json['menu_categories'] != null
          ? (json['menu_categories'] as List)
          .map((e) => MenuCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
    );
  }
}

class MenuCategoryModel {
  final int? id;
  final String? uuId;
  final String? menuCategoryName;
  final bool? isAvailable;
  final int? priority;
  final List<VendorItemModel>? vendorItems;

  MenuCategoryModel({
    this.id,
    this.uuId,
    this.menuCategoryName,
    this.isAvailable,
    this.priority,
    this.vendorItems,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      menuCategoryName: json['menu_category_name'] as String?,
      isAvailable: json['is_available'] as bool?,
      priority: json['priority'] as int?,
      vendorItems: json['vendor_items'] != null
          ? (json['vendor_items'] as List)
          .map((e) => VendorItemModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
    );
  }
}

class VendorItemModel {
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
  final String? primaryImage;
  final bool? itemStatus;
  final bool? isActive;
  final double? avgRating;
  final int? totalReviews;
  final int? cartQuantity;
  final bool? isCustomize;
  final List<CustomizedCategoryModel>? customizedCategories;

  VendorItemModel({
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
    this.primaryImage,
    this.itemStatus,
    this.isActive,
    this.avgRating,
    this.totalReviews,
    this.cartQuantity,
    this.isCustomize,
    this.customizedCategories,
  });

  factory VendorItemModel.fromJson(Map<String, dynamic> json) {
    return VendorItemModel(
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
      primaryImage: json['primary_image'] as String?,
      itemStatus: json['item_status'] as bool?,
      isActive: json['is_active'] as bool?,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
      cartQuantity: json['cart_quantity'] as int?,
      isCustomize: json['is_customize'] as bool?,
      customizedCategories: json['customized_categories'] != null
          ? (json['customized_categories'] as List)
          .map((e) => CustomizedCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
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

class VendorListPagination {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  VendorListPagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory VendorListPagination.fromJson(Map<String, dynamic> json) {
    return VendorListPagination(
      total: json['total'] as int?,
      perPage: json['per_page'] as int?,
      currentPage: json['current_page'] as int?,
      totalPages: json['total_pages'] as int?,
    );
  }
}

