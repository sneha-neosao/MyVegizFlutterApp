// To parse this JSON data, do
//
//     final mainCategoryModel = mainCategoryModelFromJson(jsonString);

import 'dart:convert';

MainCategoryModel mainCategoryModelFromJson(String str) =>
    MainCategoryModel.fromJson(json.decode(str));

String mainCategoryModelToJson(MainCategoryModel data) =>
    json.encode(data.toJson());

class MainCategoryModel {
  int status;
  String message;
  List<Datum>? data;
  Pagination? pagination;

  MainCategoryModel({
    required this.status,
    required this.message,
    this.data,
    this.pagination,
  });

  factory MainCategoryModel.fromJson(Map<String, dynamic> json) =>
      MainCategoryModel(
        status: json["status"] ?? 0,
        message: json["message"] ?? "Unknown error",
        data: json["data"] != null
            ? List<Datum>.from(json["data"].map((x) => Datum.fromJson(x)))
            : null,
        pagination: json["pagination"] != null
            ? Pagination.fromJson(json["pagination"])
            : null,
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data != null
        ? List<dynamic>.from(data!.map((x) => x.toJson()))
        : null,
    "pagination": pagination?.toJson(),
  };
}

class Datum {
  int id;
  String uuId;
  String mainCategoryName;
  String slug;
  String mainCategoryImage;
  String shortDescription;
  bool isActive;
  DateTime createdAt;

  Datum({
    required this.id,
    required this.uuId,
    required this.mainCategoryName,
    required this.slug,
    required this.mainCategoryImage,
    required this.shortDescription,
    required this.isActive,
    required this.createdAt,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    uuId: json["uu_id"] ?? "",
    mainCategoryName: json["main_category_name"] ?? "",
    slug: json["slug"] ?? "",
    mainCategoryImage: json["main_category_image"] ?? "",
    shortDescription: json["short_description"] ?? "",
    isActive: json["is_active"] ?? false,
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uu_id": uuId,
    "main_category_name": mainCategoryName,
    "slug": slug,
    "main_category_image": mainCategoryImage,
    "short_description": shortDescription,
    "is_active": isActive,
    "created_at": createdAt.toIso8601String(),
  };
}

class Pagination {
  int total;
  int perPage;
  int currentPage;
  int totalPages;

  Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: json["total"],
    perPage: json["per_page"],
    currentPage: json["current_page"],
    totalPages: json["total_pages"],
  );

  Map<String, dynamic> toJson() => {
    "total": total,
    "per_page": perPage,
    "current_page": currentPage,
    "total_pages": totalPages,
  };
}
