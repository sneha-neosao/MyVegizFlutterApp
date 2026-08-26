class VendorBannerListResponse {
  final int? status;
  final String? message;
  final List<VendorBannerModel>? data;
  final BannerPagination? pagination;

  VendorBannerListResponse({
    this.status,
    this.message,
    this.data,
    this.pagination,
  });

  factory VendorBannerListResponse.fromJson(Map<String, dynamic> json) {
    return VendorBannerListResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => VendorBannerModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      pagination: json['pagination'] != null
          ? BannerPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VendorBannerModel {
  final int? id;
  final String? uuId;
  final String? slug;
  final int? vendorId;
  final String? vendorName;
  final double? vendorLat;
  final double? vendorLng;
  final bool? isDeliverable;
  final double? distanceKm;
  final String? title;
  final String? image;
  final bool? isActive;
  final bool? isHomeSection;
  final String? createdAt;

  VendorBannerModel({
    this.id,
    this.uuId,
    this.slug,
    this.vendorId,
    this.vendorName,
    this.vendorLat,
    this.vendorLng,
    this.isDeliverable,
    this.distanceKm,
    this.title,
    this.image,
    this.isActive,
    this.isHomeSection,
    this.createdAt,
  });

  factory VendorBannerModel.fromJson(Map<String, dynamic> json) {
    return VendorBannerModel(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      slug: json['slug'] as String?,
      vendorId: json['vendor_id'] as int?,
      vendorName: json['vendor_name'] as String?,
      vendorLat: (json['vendor_lat'] as num?)?.toDouble(),
      vendorLng: (json['vendor_lng'] as num?)?.toDouble(),
      isDeliverable: json['is_deliverable'] as bool?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      title: json['title'] as String?,
      image: json['image'] as String?,
      isActive: json['is_active'] as bool?,
      isHomeSection: json['is_homesection'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class BannerPagination {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  BannerPagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory BannerPagination.fromJson(Map<String, dynamic> json) {
    return BannerPagination(
      total: json['total'] as int?,
      perPage: json['per_page'] as int?,
      currentPage: json['current_page'] as int?,
      totalPages: json['total_pages'] as int?,
    );
  }
}
