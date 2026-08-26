class CmsPageResponse {
  final int? status;
  final String? message;
  final CmsPageModel? data;

  CmsPageResponse({
    this.status,
    this.message,
    this.data,
  });

  factory CmsPageResponse.fromJson(Map<String, dynamic> json) {
    return CmsPageResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null ? CmsPageModel.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }
}

class CmsPageModel {
  final int? id;
  final String? pageKey;
  final String? metaTitle;
  final String? subtitle;
  final String? metaDescription;
  final String? pageContent;
  final bool? isActive;
  final bool? isUpdate;
  final String? createdAt;
  final String? updatedAt;

  CmsPageModel({
    this.id,
    this.pageKey,
    this.metaTitle,
    this.subtitle,
    this.metaDescription,
    this.pageContent,
    this.isActive,
    this.isUpdate,
    this.createdAt,
    this.updatedAt,
  });

  factory CmsPageModel.fromJson(Map<String, dynamic> json) {
    return CmsPageModel(
      id: json['id'] as int?,
      pageKey: json['page_key'] as String?,
      metaTitle: json['meta_title'] as String?,
      subtitle: json['subtitle'] as String?,
      metaDescription: json['meta_description'] as String?,
      pageContent: json['page_content'] as String?,
      isActive: json['is_active'] as bool?,
      isUpdate: json['is_update'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
