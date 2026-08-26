import '../../../grocery_subCtegory/data/models/homePage_model.dart';
import '../../../mainCetegories/data/models/mainCategory_model.dart';

class GrocerySearchResponse {
  final int? status;
  final String? message;
  final Pagination? pagination;
  final List<ProductModel>? products;

  GrocerySearchResponse({
    this.status,
    this.message,
    this.pagination,
    this.products,
  });

  factory GrocerySearchResponse.fromJson(Map<String, dynamic> json) {
    List<ProductModel> parsedProducts = [];

    if (json['data'] != null) {
      if (json['data'] is List) {
        parsedProducts = (json['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((v) => ProductModel.fromJson(v))
            .toList();
      } else if (json['data'] is Map<String, dynamic>) {
        final dataMap = json['data'] as Map<String, dynamic>;
        if (dataMap['products'] is List) {
          parsedProducts = (dataMap['products'] as List)
              .whereType<Map<String, dynamic>>()
              .map((v) => ProductModel.fromJson(v))
              .toList();
        } else if (dataMap['data'] is List) {
          parsedProducts = (dataMap['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((v) => ProductModel.fromJson(v))
              .toList();
        } else if (dataMap['sub_categories'] is List) {
          final subCats = (dataMap['sub_categories'] as List)
              .whereType<Map<String, dynamic>>()
              .map((v) => SubCategoryModel.fromJson(v))
              .toList();
          for (final sub in subCats) {
            if (sub.products != null) {
              parsedProducts.addAll(sub.products!);
            }
          }
        }
      }
    } else if (json['products'] != null && json['products'] is List) {
      parsedProducts = (json['products'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductModel.fromJson(v))
          .toList();
    }

    Pagination? parsedPagination;
    if (json['pagination'] != null && json['pagination'] is Map<String, dynamic>) {
      parsedPagination = Pagination.fromJson(json['pagination'] as Map<String, dynamic>);
    } else if (json['data'] is Map<String, dynamic> &&
        json['data']['pagination'] != null &&
        json['data']['pagination'] is Map<String, dynamic>) {
      parsedPagination = Pagination.fromJson(json['data']['pagination'] as Map<String, dynamic>);
    }

    return GrocerySearchResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      pagination: parsedPagination,
      products: parsedProducts,
    );
  }
}
