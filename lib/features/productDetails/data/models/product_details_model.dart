import 'dart:convert';
import '../../../../core/models/common_models.dart';

ProductDetailsModel productDetailsModelFromJson(String str) =>
    ProductDetailsModel.fromJson(json.decode(str));

String productDetailsModelToJson(ProductDetailsModel data) =>
    json.encode(data.toJson());

class ProductDetailsModel {
  final int? status;
  final String? message;
  final List<ProductData> data;
  final Pagination? pagination;

  ProductDetailsModel({
    this.status,
    this.message,
    this.data = const [],
    this.pagination,
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    List<ProductData> parsedData = [];
    if (json['data'] != null) {
      if (json['data'] is List) {
        parsedData = (json['data'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(ProductData.fromJson)
            .toList();
      } else if (json['data'] is Map<String, dynamic>) {
        parsedData = [ProductData.fromJson(json['data'] as Map<String, dynamic>)];
      }
    }
    return ProductDetailsModel(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: parsedData,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data.map((x) => x.toJson()).toList(),
    "pagination": pagination?.toJson(),
  };
}

class ProductData {
  final int id;
  final String? uuId;
  final String productName;
  final String? productShortName;
  final String slug;
  final String shortDescription;
  final String longDescription;
  final String? hsnCode;
  final String? skuCode;
  final int categoryId;
  final int subCategoryId;
  final String categoryName;
  final String subCategoryName;
  final List<ProductImage> images;
  final List<SharedVariantModel> variants;
  final SharedRatingModel? rating;
  final int cartQuantity;
  final bool isWishlisted;

  ProductData({
    required this.id,
    this.uuId,
    required this.productName,
    this.productShortName,
    required this.slug,
    required this.shortDescription,
    required this.longDescription,
    this.hsnCode,
    this.skuCode,
    required this.categoryId,
    required this.subCategoryId,
    required this.categoryName,
    required this.subCategoryName,
    required this.images,
    required this.variants,
    this.rating,
    this.cartQuantity = 0,
    this.isWishlisted = false,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      id: json['id'] as int? ?? 0,
      uuId: json['uu_id'] as String?,
      productName: json['product_name'] as String? ?? '',
      productShortName: json['product_short_name'] as String?,
      slug: json['slug'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      longDescription: json['long_description'] as String? ?? '',
      hsnCode: json['hsn_code']?.toString(),
      skuCode: json['sku_code']?.toString(),
      categoryId: json['category_id'] as int? ?? 0,
      subCategoryId: json['sub_category_id'] as int? ?? 0,
      categoryName: json['category_name'] as String? ?? '',
      subCategoryName: json['sub_category_name'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProductImage.fromJson)
          .toList(),
      variants: (json['variants'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SharedVariantModel.fromJson)
          .toList(),
      rating: json['rating'] != null
          ? SharedRatingModel.fromJson(json['rating'])
          : null,
      cartQuantity: json['cart_quantity'] as int? ?? 0,
      isWishlisted: json['is_wishlisted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "uu_id": uuId,
    "product_name": productName,
    "product_short_name": productShortName,
    "slug": slug,
    "short_description": shortDescription,
    "long_description": longDescription,
    "hsn_code": hsnCode,
    "sku_code": skuCode,
    "category_id": categoryId,
    "sub_category_id": subCategoryId,
    "category_name": categoryName,
    "sub_category_name": subCategoryName,
    "images": images.map((x) => x.toJson()).toList(),
    "variants": variants.map((x) => x.toJson()).toList(),
    "rating": rating?.toJson(),
    "cart_quantity": cartQuantity,
    "is_wishlisted": isWishlisted,
  };
}

class ProductImage {
  final int id;
  final String productImage;
  final bool isPrimary;
  final String? publicId;

  ProductImage({
    required this.id,
    required this.productImage,
    required this.isPrimary,
    this.publicId,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int? ?? 0,
      productImage: json['product_image'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      publicId: json['public_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_image": productImage,
    "is_primary": isPrimary,
    "public_id": publicId,
  };
}

class Pagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "total": total,
    "per_page": perPage,
    "current_page": currentPage,
    "total_pages": totalPages,
  };
}
