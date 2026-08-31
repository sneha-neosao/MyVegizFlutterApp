class HomeTabSubCategoriesResponse {
  final int status;
  final String message;
  final List<HomeTabSubCategoryItemModel> data;
  final HomeTabSubCategoriesPagination? pagination;

  HomeTabSubCategoriesResponse({
    required this.status,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory HomeTabSubCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return HomeTabSubCategoriesResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => HomeTabSubCategoryItemModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? HomeTabSubCategoriesPagination.fromJson(
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

class HomeTabSubCategoryItemModel {
  final int id;
  final int? categoryId;
  final String? categoryName;
  final String uuId;
  final String subCategoryName;
  final String slug;
  final String? subCategoryImage;
  final bool isActive;
  final String createdAt;

  HomeTabSubCategoryItemModel({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.uuId,
    required this.subCategoryName,
    required this.slug,
    this.subCategoryImage,
    required this.isActive,
    required this.createdAt,
  });

  factory HomeTabSubCategoryItemModel.fromJson(Map<String, dynamic> json) {
    return HomeTabSubCategoryItemModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      uuId: json['uu_id'] ?? '',
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
      'uu_id': uuId,
      'sub_category_name': subCategoryName,
      'slug': slug,
      'sub_category_image': subCategoryImage,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

class HomeTabSubCategoriesPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPages;

  HomeTabSubCategoriesPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory HomeTabSubCategoriesPagination.fromJson(Map<String, dynamic> json) {
    return HomeTabSubCategoriesPagination(
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
