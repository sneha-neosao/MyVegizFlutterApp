class VendorEntityCategoryResponse {
  final int? status;
  final String? message;
  final List<VendorEntityCategoryData>? data;

  VendorEntityCategoryResponse({this.status, this.message, this.data});

  factory VendorEntityCategoryResponse.fromJson(Map<String, dynamic> json) {
    return VendorEntityCategoryResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
                .map(
                  (e) => VendorEntityCategoryData.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
    );
  }
}

class VendorEntityCategoryData {
  final int? id;
  final String? uuId;
  final String? code;
  final String? entityCategory;
  final String? image;
  final bool? isActive;
  final List<EntityCategoryVendor>? vendors;

  VendorEntityCategoryData({
    this.id,
    this.uuId,
    this.code,
    this.entityCategory,
    this.image,
    this.isActive,
    this.vendors,
  });

  factory VendorEntityCategoryData.fromJson(Map<String, dynamic> json) {
    return VendorEntityCategoryData(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      code: json['code'] as String?,
      entityCategory: json['entity_category'] as String?,
      image: json['image'] as String?,
      isActive: json['is_active'] as bool?,
      vendors: json['vendors'] != null
          ? (json['vendors'] as List)
                .map(
                  (e) =>
                      EntityCategoryVendor.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

class EntityCategoryVendor {
  final int? id;
  final String? uuId;
  final String? entityName;
  final String? entityImage;
  final String? entityContact;
  final String? city;
  final String? area;
  final bool? isActive;
  final bool? isPopular;
  final bool? adminIsServiceable;
  final bool? autoIsServiceable;
  final String? foodType;
  final bool? isDeliverable;
  final List<EntityCategoryVendorItem>? vendorItems;

  // API-driven dynamic fields
  final double? rating;
  final double? avgRating;
  final int? totalReviews;
  // final String? ratingsCount;
  final String? deliveryTime;
  final double? distanceKm;
  final bool? isAd;
  final double? lat;
  final double? lng;
  final bool? isAvailableInZone;

  /// true if admin has marked this vendor as serviceable OR auto-serviceable logic applies
  bool get isServiceable {
    return adminIsServiceable == true;
  }

  // Clean API-driven getters with direct fallbacks if values are null
  double get displayRating => avgRating ?? rating ?? 0.0;

  // String get displayRatingsCount =>
  //     ratingsCount != null ? "$ratingsCount ratings" : "0 ratings";

  String get displayDeliveryTime {
    if (deliveryTime != null && deliveryTime!.isNotEmpty) {
      return deliveryTime!;
    }
    if (vendorItems != null && vendorItems!.isNotEmpty) {
      final totalTimes = vendorItems!
          .map((item) => item.totalDeliveryTime)
          .whereType<int>()
          .toList();
      if (totalTimes.isNotEmpty) {
        final maxTime = totalTimes.reduce((a, b) => a > b ? a : b);
        if (maxTime > 0) {
          return "$maxTime mins";
        }
      }
    }
    final dist = displayDistance;
    if (dist <= 0.0) {
      return "10-15 mins";
    } else if (dist <= 1.0) {
      return "15-20 mins";
    } else if (dist <= 2.0) {
      return "20-25 mins";
    } else if (dist <= 3.0) {
      return "25-30 mins";
    } else {
      return "30-40 mins";
    }
  }

  bool get displayIsAd => isAd ?? false;

  double get displayDistance => distanceKm ?? 0.0;

  // Dynamically compute minimum price from items
  double get minPrice {
    double min = 0.0;
    if (vendorItems != null && vendorItems!.isNotEmpty) {
      for (var item in vendorItems!) {
        final price = item.salePrice;
        if (price != null && (min == 0.0 || price < min)) {
          min = price;
        }
      }
    }
    return min;
  }

  String get priceText =>
      minPrice > 0.0 ? "ITEMS AT ₹${minPrice.toInt()}" : "DEALS AVAILABLE";

  // Dynamically compute cuisines string
  String get cuisinesString {
    final List<String> cuisinesList = [];
    if (vendorItems != null && vendorItems!.isNotEmpty) {
      for (var item in vendorItems!) {
        final categoryName = item.menuCategory?.menuCategoryName;
        if (categoryName != null &&
            categoryName.isNotEmpty &&
            !cuisinesList.contains(categoryName)) {
          cuisinesList.add(categoryName);
        }
      }
      if (cuisinesList.isEmpty) {
        for (var item in vendorItems!) {
          if (item.itemName != null && item.itemName!.isNotEmpty) {
            cuisinesList.add(item.itemName!);
          }
        }
      }
    }
    if (cuisinesList.isEmpty) {
      return "";
    }
    return cuisinesList.take(3).join(", ");
  }

  EntityCategoryVendor({
    this.id,
    this.uuId,
    this.entityName,
    this.entityImage,
    this.entityContact,
    this.city,
    this.area,
    this.isActive,
    this.isPopular,
    this.adminIsServiceable,
    this.autoIsServiceable,
    this.foodType,
    this.isDeliverable,
    this.vendorItems,
    this.rating,
    this.avgRating,
    this.totalReviews,
    // this.ratingsCount,
    this.deliveryTime,
    this.distanceKm,
    this.isAd,
    this.lat,
    this.lng,
    this.isAvailableInZone,
  });

  factory EntityCategoryVendor.fromJson(Map<String, dynamic> json) {
    // ── DEBUG: Distance trace ─────────────────────────────────────────────
    final rawDistanceKm = json['distance_km'];
    final rawDistance = json['distance'];
    final parsedDistanceKm = (json['distance_km'] as num?)?.toDouble();
    // ignore: avoid_print
    print('[DISTANCE_DEBUG] fromJson vendor=${json['entity_name']} | raw distance_km=$rawDistanceKm (${rawDistanceKm?.runtimeType}) | raw distance=$rawDistance (${rawDistance?.runtimeType}) | parsed distanceKm=$parsedDistanceKm');
    // ─────────────────────────────────────────────────────────────────────
    return EntityCategoryVendor(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      entityName: json['entity_name'] as String?,
      entityImage: json['entity_image'] as String?,
      entityContact: json['entity_contact'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      isActive: json['is_active'] as bool?,
      isPopular: json['is_popular'] as bool?,
      adminIsServiceable: json['admin_is_serviceable'] as bool?,
      autoIsServiceable: json['auto_is_serviceable'] as bool?,
      foodType: json['food_type'] as String?,
      isDeliverable: json['is_deliverable'] == null
          ? null
          : (json['is_deliverable'] is bool
                ? json['is_deliverable'] as bool
                : (json['is_deliverable'] is num
                      ? (json['is_deliverable'] as num) == 1
                      : json['is_deliverable'].toString().toLowerCase() ==
                                'true' ||
                            json['is_deliverable'].toString() == '1')),
      vendorItems: json['vendor_items'] != null
          ? (json['vendor_items'] as List)
                .map(
                  (e) => EntityCategoryVendorItem.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
      rating:
          (json['rating'] as num?)?.toDouble() ??
          (json['avg_rating'] as num?)?.toDouble(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
      // ratingsCount: json['ratings_count']?.toString() ?? json['reviews_count']?.toString(),
      deliveryTime:
          json['delivery_time'] as String? ??
          json['estimated_delivery_time'] as String?,
      // Always use the API-provided distance_km value directly.
      // Never fall back to a local 'distance' key or recalculate from lat/lng.
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isAd: json['is_ad'] as bool? ?? json['is_sponsored'] as bool?,
      lat:
          (json['lat'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble(),
      lng:
          (json['lng'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble(),
      isAvailableInZone: json['is_available_in_zone'] == null
          ? null
          : (json['is_available_in_zone'] is bool
                ? json['is_available_in_zone'] as bool
                : (json['is_available_in_zone'] is num
                      ? (json['is_available_in_zone'] as num) == 1
                      : json['is_available_in_zone'].toString().toLowerCase() ==
                                'true' ||
                            json['is_available_in_zone'].toString() == '1')),
    );
  }
}

class EntityCategoryVendorItem {
  final int? id;
  final String? uuId;
  final String? code;
  final String? itemName;
  final double? salePrice;
  final double? packingCharges;
  final int? maxOrderQuantity;
  final String? cuisineType;
  final String? description;
  final bool? itemStatus;
  final bool? isApproved;
  final bool? isActive;
  final String? primaryImage;
  final double? avgRating;
  final int? totalReviews;
  final EntityCategoryMenuCategoryBrief? menuCategory;
  final List<EntityCategoryVendorItemImage>? images;
  final int? preparationTime;
  final int? defaultDeliveryMinutes;
  final int? totalDeliveryTime;

  EntityCategoryVendorItem({
    this.id,
    this.uuId,
    this.code,
    this.itemName,
    this.salePrice,
    this.packingCharges,
    this.maxOrderQuantity,
    this.cuisineType,
    this.description,
    this.itemStatus,
    this.isApproved,
    this.isActive,
    this.primaryImage,
    this.avgRating,
    this.totalReviews,
    this.menuCategory,
    this.images,
    this.preparationTime,
    this.defaultDeliveryMinutes,
    this.totalDeliveryTime,
  });

  factory EntityCategoryVendorItem.fromJson(Map<String, dynamic> json) {
    return EntityCategoryVendorItem(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      code: json['code'] as String?,
      itemName: json['item_name'] as String?,
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      packingCharges: (json['packing_charges'] as num?)?.toDouble(),
      maxOrderQuantity: json['max_order_quantity'] as int?,
      cuisineType: json['cuisine_type'] as String?,
      description: json['description'] as String?,
      itemStatus: json['item_status'] as bool?,
      isApproved: json['is_approved'] as bool?,
      isActive: json['is_active'] as bool?,
      primaryImage: json['primary_image'] as String?,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
      menuCategory: json['menu_category'] != null
          ? EntityCategoryMenuCategoryBrief.fromJson(
              json['menu_category'] as Map<String, dynamic>,
            )
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
                .map(
                  (e) => EntityCategoryVendorItemImage.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
      preparationTime: json['preparation_time'] as int?,
      defaultDeliveryMinutes: json['default_delivery_minutes'] as int?,
      totalDeliveryTime: json['total_delivery_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uu_id': uuId,
      'code': code,
      'item_name': itemName,
      'sale_price': salePrice,
      'packing_charges': packingCharges,
      'max_order_quantity': maxOrderQuantity,
      'cuisine_type': cuisineType,
      'description': description,
      'item_status': itemStatus,
      'is_approved': isApproved,
      'is_active': isActive,
      'primary_image': primaryImage,
      'avg_rating': avgRating,
      'total_reviews': totalReviews,
      'menu_category': menuCategory?.toJson(),
      'images': images?.map((e) => e.toJson()).toList(),
      'preparation_time': preparationTime,
      'default_delivery_minutes': defaultDeliveryMinutes,
      'total_delivery_time': totalDeliveryTime,
    };
  }

  EntityCategoryVendorItem copyWith({
    int? id,
    String? uuId,
    String? code,
    String? itemName,
    double? salePrice,
    double? packingCharges,
    int? maxOrderQuantity,
    String? cuisineType,
    String? description,
    bool? itemStatus,
    bool? isApproved,
    bool? isActive,
    String? primaryImage,
    double? avgRating,
    int? totalReviews,
    EntityCategoryMenuCategoryBrief? menuCategory,
    List<EntityCategoryVendorItemImage>? images,
    int? preparationTime,
    int? defaultDeliveryMinutes,
    int? totalDeliveryTime,
  }) {
    return EntityCategoryVendorItem(
      id: id ?? this.id,
      uuId: uuId ?? this.uuId,
      code: code ?? this.code,
      itemName: itemName ?? this.itemName,
      salePrice: salePrice ?? this.salePrice,
      packingCharges: packingCharges ?? this.packingCharges,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity,
      cuisineType: cuisineType ?? this.cuisineType,
      description: description ?? this.description,
      itemStatus: itemStatus ?? this.itemStatus,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      primaryImage: primaryImage ?? this.primaryImage,
      avgRating: avgRating ?? this.avgRating,
      totalReviews: totalReviews ?? this.totalReviews,
      menuCategory: menuCategory ?? this.menuCategory,
      images: images ?? this.images,
      preparationTime: preparationTime ?? this.preparationTime,
      defaultDeliveryMinutes: defaultDeliveryMinutes ?? this.defaultDeliveryMinutes,
      totalDeliveryTime: totalDeliveryTime ?? this.totalDeliveryTime,
    );
  }
}

class EntityCategoryMenuCategoryBrief {
  final int? id;
  final String? menuCategoryName;
  final bool? isAvailable;

  EntityCategoryMenuCategoryBrief({
    this.id,
    this.menuCategoryName,
    this.isAvailable,
  });

  factory EntityCategoryMenuCategoryBrief.fromJson(Map<String, dynamic> json) {
    return EntityCategoryMenuCategoryBrief(
      id: json['id'] as int?,
      menuCategoryName: json['menu_category_name'] as String?,
      isAvailable: json['is_available'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_category_name': menuCategoryName,
      'is_available': isAvailable,
    };
  }

  EntityCategoryMenuCategoryBrief copyWith({
    int? id,
    String? menuCategoryName,
    bool? isAvailable,
  }) {
    return EntityCategoryMenuCategoryBrief(
      id: id ?? this.id,
      menuCategoryName: menuCategoryName ?? this.menuCategoryName,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class EntityCategoryVendorItemImage {
  final int? id;
  final String? itemImage;
  final bool? isPrimary;
  final bool? isActive;

  EntityCategoryVendorItemImage({
    this.id,
    this.itemImage,
    this.isPrimary,
    this.isActive,
  });

  factory EntityCategoryVendorItemImage.fromJson(Map<String, dynamic> json) {
    return EntityCategoryVendorItemImage(
      id: json['id'] as int?,
      itemImage: json['item_image'] as String?,
      isPrimary: json['is_primary'] as bool?,
      isActive: json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_image': itemImage,
      'is_primary': isPrimary,
      'is_active': isActive,
    };
  }

  EntityCategoryVendorItemImage copyWith({
    int? id,
    String? itemImage,
    bool? isPrimary,
    bool? isActive,
  }) {
    return EntityCategoryVendorItemImage(
      id: id ?? this.id,
      itemImage: itemImage ?? this.itemImage,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
    );
  }
}

class VendorEntityCategoryFilterResponse {
  final int? status;
  final String? message;
  final VendorEntityCategoryFilterData? data;

  VendorEntityCategoryFilterResponse({this.status, this.message, this.data});

  factory VendorEntityCategoryFilterResponse.fromJson(Map<String, dynamic> json) {
    return VendorEntityCategoryFilterResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? VendorEntityCategoryFilterData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }

  VendorEntityCategoryFilterResponse copyWith({
    int? status,
    String? message,
    VendorEntityCategoryFilterData? data,
  }) {
    return VendorEntityCategoryFilterResponse(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}

class VendorEntityCategoryFilterData {
  final List<FilterOption>? sortOptions;
  final List<FilterOption>? foodTypes;

  VendorEntityCategoryFilterData({this.sortOptions, this.foodTypes});

  factory VendorEntityCategoryFilterData.fromJson(Map<String, dynamic> json) {
    return VendorEntityCategoryFilterData(
      sortOptions: json['sort_options'] != null
          ? (json['sort_options'] as List)
              .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      foodTypes: json['food_types'] != null
          ? (json['food_types'] as List)
              .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sort_options': sortOptions?.map((e) => e.toJson()).toList(),
      'food_types': foodTypes?.map((e) => e.toJson()).toList(),
    };
  }

  VendorEntityCategoryFilterData copyWith({
    List<FilterOption>? sortOptions,
    List<FilterOption>? foodTypes,
  }) {
    return VendorEntityCategoryFilterData(
      sortOptions: sortOptions ?? this.sortOptions,
      foodTypes: foodTypes ?? this.foodTypes,
    );
  }
}

class FilterOption {
  final String? key;
  final String? label;

  FilterOption({this.key, this.label});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      key: json['key'] as String?,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
    };
  }

  FilterOption copyWith({
    String? key,
    String? label,
  }) {
    return FilterOption(
      key: key ?? this.key,
      label: label ?? this.label,
    );
  }
}
