class EntityCategoryResponse {
  final int? status;
  final String? message;
  final List<EntityCategoryModel>? data;
  final EntityCategoryPagination? pagination;

  EntityCategoryResponse({
    this.status,
    this.message,
    this.data,
    this.pagination,
  });

  factory EntityCategoryResponse.fromJson(Map<String, dynamic> json) {
    return EntityCategoryResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => EntityCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      pagination: json['pagination'] != null
          ? EntityCategoryPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EntityCategoryModel {
  final int? id;
  final String? uuId;
  final String? code;
  final String? entityCategory;
  final String? image;
  final int? vendorCategoryId;
  final String? vendorCategoryName;
  final int? mainCategoryId;
  final String? mainCategoryName;
  final bool? isActive;
  final String? createdAt;

  EntityCategoryModel({
    this.id,
    this.uuId,
    this.code,
    this.entityCategory,
    this.image,
    this.vendorCategoryId,
    this.vendorCategoryName,
    this.mainCategoryId,
    this.mainCategoryName,
    this.isActive,
    this.createdAt,
  });

  factory EntityCategoryModel.fromJson(Map<String, dynamic> json) {
    return EntityCategoryModel(
      id: json['id'] as int?,
      uuId: json['uu_id'] as String?,
      code: json['code'] as String?,
      entityCategory: json['entity_category'] as String?,
      image: json['image'] as String?,
      vendorCategoryId: json['vendor_category_id'] as int?,
      vendorCategoryName: json['vendor_category_name'] as String?,
      mainCategoryId: json['main_category_id'] as int?,
      mainCategoryName: json['main_category_name'] as String?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class EntityCategoryPagination {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  EntityCategoryPagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory EntityCategoryPagination.fromJson(Map<String, dynamic> json) {
    return EntityCategoryPagination(
      total: json['total'] as int?,
      perPage: json['per_page'] as int?,
      currentPage: json['current_page'] as int?,
      totalPages: json['total_pages'] as int?,
    );
  }
}
