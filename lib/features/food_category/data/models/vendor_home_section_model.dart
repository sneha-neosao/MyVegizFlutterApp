import 'vendor_entity_category_model.dart';

class VendorHomeSectionResponse {
  final int? status;
  final String? message;
  final List<VendorHomeSection>? data;

  VendorHomeSectionResponse({this.status, this.message, this.data});

  factory VendorHomeSectionResponse.fromJson(Map<String, dynamic> json) {
    return VendorHomeSectionResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => VendorHomeSection.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class VendorHomeSection {
  final int? id;
  final String? uuId;
  final String? slug;
  final String? title;
  final String? sectionType;
  final String? description;
  final int? priority;
  final bool? isActive;
  final String? createdAt;
  final List<HomeSectionBanner>? banners;
  final List<HomeSectionVendor>? vendors;
  final List<HomeSectionVendorItem>? vendorItems;

  VendorHomeSection({
    this.id,
    this.uuId,
    this.slug,
    this.title,
    this.sectionType,
    this.description,
    this.priority,
    this.isActive,
    this.createdAt,
    this.banners,
    this.vendors,
    this.vendorItems,
  });

  factory VendorHomeSection.fromJson(Map<String, dynamic> json) {
    return VendorHomeSection(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      slug: json['slug'] as String?,
      title: json['title'] as String?,
      sectionType: json['section_type'] as String?,
      description: json['description'] as String?,
      priority: json['priority'] as int?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] as String?,
      banners: json['banners'] != null
          ? (json['banners'] as List)
              .map((e) => HomeSectionBanner.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      vendors: json['vendors'] != null
          ? (json['vendors'] as List)
              .map((e) => HomeSectionVendor.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      vendorItems: json['vendor_items'] != null
          ? (json['vendor_items'] as List)
              .map((e) => HomeSectionVendorItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class HomeSectionBanner {
  final int? id;
  final String? uuId;
  final String? slug;
  final String? title;
  final String? image;
  final bool? isHomeSection;
  final bool? isActive;
  final int? vendorId;
  final String? vendorUuId;
  final String? entityName;
  final bool? isDeliverable;
  final double? distanceKm;
  final double? lat;
  final double? lng;
  final double? avgRating;
  final int? totalReviews;

  HomeSectionBanner({
    this.id,
    this.uuId,
    this.slug,
    this.title,
    this.image,
    this.isHomeSection,
    this.isActive,
    this.vendorId,
    this.vendorUuId,
    this.entityName,
    this.isDeliverable,
    this.distanceKm,
    this.lat,
    this.lng,
    this.avgRating,
    this.totalReviews,
  });

  factory HomeSectionBanner.fromJson(Map<String, dynamic> json) {
    return HomeSectionBanner(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      slug: json['slug'] as String?,
      title: json['title'] as String?,
      image: json['image'] as String?,
      isHomeSection: json['is_homesection'] as bool?,
      isActive: json['is_active'] as bool?,
      vendorId: json['vendor_id'] as int?,
      vendorUuId: json['vendor_uu_id'] as String?,
      entityName: json['entity_name'] as String?,
      isDeliverable: json['is_deliverable'] == null
          ? null
          : (json['is_deliverable'] is bool
              ? json['is_deliverable'] as bool
              : (json['is_deliverable'] is num
                  ? (json['is_deliverable'] as num) == 1
                  : json['is_deliverable'].toString().toLowerCase() == 'true' ||
                      json['is_deliverable'].toString() == '1')),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
    );
  }
}

class HomeSectionVendor {
  final int? id;
  final String? uuId;
  final String? entityName;
  final String? entityImage;
  final bool? isActive;
  final bool? isPopular;
  final bool? adminIsServiceable;
  final bool? autoIsServiceable;
  final String? foodType;
  final bool? isDeliverable;
  final double? distanceKm;
  final double? lat;
  final double? lng;
  final double? avgRating;
  final int? totalReviews;

  HomeSectionVendor({
    this.id,
    this.uuId,
    this.entityName,
    this.entityImage,
    this.isActive,
    this.isPopular,
    this.adminIsServiceable,
    this.autoIsServiceable,
    this.foodType,
    this.isDeliverable,
    this.distanceKm,
    this.lat,
    this.lng,
    this.avgRating,
    this.totalReviews,
  });

  bool get isServiceable {
    return adminIsServiceable == true;
  }

  factory HomeSectionVendor.fromJson(Map<String, dynamic> json) {
    return HomeSectionVendor(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      entityName: json['entity_name'] as String?,
      entityImage: json['entity_image'] as String?,
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
                  : json['is_deliverable'].toString().toLowerCase() == 'true' ||
                      json['is_deliverable'].toString() == '1')),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
    );
  }
}

class HomeSectionVendorItem {
  final int? id;
  final String? uuId;
  final String? code;
  final String? itemName;
  final double? salePrice;
  final double? packingCharges;
  final String? cuisineType;
  final String? description;
  final int? preparationTime;
  final int? defaultDeliveryMinutes;
  final int? totalDeliveryTime;
  final bool? isActive;
  final bool? isApproved;
  final bool? itemStatus;
  final String? primaryImage;
  final double? avgRating;
  final int? totalReviews;
  final HomeSectionVendor? vendor;

  HomeSectionVendorItem({
    this.id,
    this.uuId,
    this.code,
    this.itemName,
    this.salePrice,
    this.packingCharges,
    this.cuisineType,
    this.description,
    this.preparationTime,
    this.defaultDeliveryMinutes,
    this.totalDeliveryTime,
    this.isActive,
    this.isApproved,
    this.itemStatus,
    this.primaryImage,
    this.avgRating,
    this.totalReviews,
    this.vendor,
  });

  factory HomeSectionVendorItem.fromJson(Map<String, dynamic> json) {
    return HomeSectionVendorItem(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      code: json['code'] as String?,
      itemName: json['item_name'] as String?,
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      packingCharges: (json['packing_charges'] as num?)?.toDouble(),
      cuisineType: json['cuisine_type'] as String?,
      description: json['description'] as String?,
      preparationTime: json['preparation_time'] as int?,
      defaultDeliveryMinutes: json['default_delivery_minutes'] as int?,
      totalDeliveryTime: json['total_delivery_time'] as int?,
      isActive: json['is_active'] as bool?,
      isApproved: json['is_approved'] as bool?,
      itemStatus: json['item_status'] as bool?,
      primaryImage: json['primary_image'] as String?,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
      vendor: json['vendor'] != null
          ? HomeSectionVendor.fromJson(json['vendor'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VendorHomeSectionFiltersResponse {
  final int? status;
  final String? message;
  final VendorHomeSectionFiltersData? data;

  VendorHomeSectionFiltersResponse({this.status, this.message, this.data});

  factory VendorHomeSectionFiltersResponse.fromJson(Map<String, dynamic> json) {
    return VendorHomeSectionFiltersResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? VendorHomeSectionFiltersData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VendorHomeSectionFiltersData {
  final List<FilterOption>? sortOptions;
  final List<FilterOption>? foodTypes;

  VendorHomeSectionFiltersData({this.sortOptions, this.foodTypes});

  factory VendorHomeSectionFiltersData.fromJson(Map<String, dynamic> json) {
    return VendorHomeSectionFiltersData(
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
}
