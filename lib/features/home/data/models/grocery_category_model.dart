class GroceryCategoryResponse {
  final int? status;
  final String? message;
  final List<GroceryCategoryModel>? data;
  final GroceryCategoryPagination? pagination;

  GroceryCategoryResponse({
    this.status,
    this.message,
    this.data,
    this.pagination,
  });

  factory GroceryCategoryResponse.fromJson(Map<String, dynamic> json) {
    return GroceryCategoryResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => GroceryCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      pagination: json['pagination'] != null
          ? GroceryCategoryPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class GroceryCategoryModel {
  final int? id;
  final int? mainCategoryId;
  final String? mainCategoryName;
  final int? homeSectionId;
  final String? homeSectionTitle;
  final String? homeSectionSectionType;
  final String? uuId;
  final String? categoryName;
  final String? slug;
  final String? categoryImage;
  final bool? isActive;
  final String? createdAt;

  GroceryCategoryModel({
    this.id,
    this.mainCategoryId,
    this.mainCategoryName,
    this.homeSectionId,
    this.homeSectionTitle,
    this.homeSectionSectionType,
    this.uuId,
    this.categoryName,
    this.slug,
    this.categoryImage,
    this.isActive,
    this.createdAt,
  });

  factory GroceryCategoryModel.fromJson(Map<String, dynamic> json) {
    return GroceryCategoryModel(
      id: json['id'] as int?,
      mainCategoryId: json['main_category_id'] as int?,
      mainCategoryName: json['main_category_name'] as String?,
      homeSectionId: json['home_section_id'] as int?,
      homeSectionTitle: json['home_section_title'] as String?,
      homeSectionSectionType: json['home_section_section_type'] as String?,
      uuId: json['uu_id'] as String?,
      categoryName: json['category_name'] as String?,
      slug: json['slug'] as String?,
      categoryImage: json['category_image'] as String?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class GroceryCategoryPagination {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  GroceryCategoryPagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory GroceryCategoryPagination.fromJson(Map<String, dynamic> json) {
    return GroceryCategoryPagination(
      total: json['total'] as int?,
      perPage: json['per_page'] as int?,
      currentPage: json['current_page'] as int?,
      totalPages: json['total_pages'] as int?,
    );
  }
}
