class SubCategoriesByCategoryResponse {
  final int status;
  final String message;
  final List<SubCategoryByCategoryItemModel> data;
  final SubCategoriesByCategoryPagination? pagination;

  SubCategoriesByCategoryResponse({
    required this.status,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory SubCategoriesByCategoryResponse.fromJson(Map<String, dynamic> json) {
    return SubCategoriesByCategoryResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => SubCategoryByCategoryItemModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? SubCategoriesByCategoryPagination.fromJson(
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

class SubCategoryByCategoryItemModel {
  final int id;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String uuId;
  final String? subCategoryUuid;
  final String subCategoryName;
  final String slug;
  final String? subCategoryImage;
  final bool isActive;
  final String createdAt;

  SubCategoryByCategoryItemModel({
    required this.id,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    required this.uuId,
    this.subCategoryUuid,
    required this.subCategoryName,
    required this.slug,
    this.subCategoryImage,
    required this.isActive,
    required this.createdAt,
  });

  factory SubCategoryByCategoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawUuid = json['uu_id'] ?? json['sub_category_uuid'] ?? '';
    return SubCategoryByCategoryItemModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      categorySlug: json['category_slug'] as String?,
      uuId: rawUuid,
      subCategoryUuid: json['sub_category_uuid'] as String? ?? rawUuid,
      subCategoryName: json['sub_category_name'] ?? '',
      slug: json['slug'] ?? '',
      subCategoryImage: json['sub_category_image'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_slug': categorySlug,
      'uu_id': uuId,
      'sub_category_uuid': subCategoryUuid,
      'sub_category_name': subCategoryName,
      'slug': slug,
      'sub_category_image': subCategoryImage,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

class SubCategoriesByCategoryPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPages;

  SubCategoriesByCategoryPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory SubCategoriesByCategoryPagination.fromJson(Map<String, dynamic> json) {
    return SubCategoriesByCategoryPagination(
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
