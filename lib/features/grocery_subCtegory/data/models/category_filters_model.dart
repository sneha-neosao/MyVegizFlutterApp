class CategoryFiltersResponse {
  final int? status;
  final String? message;
  final CategoryFiltersData? data;

  CategoryFiltersResponse({this.status, this.message, this.data});

  factory CategoryFiltersResponse.fromJson(Map<String, dynamic> json) {
    return CategoryFiltersResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? CategoryFiltersData.fromJson(json['data']) : null,
    );
  }
}

class CategoryFiltersData {
  final List<FilterOption>? sortOptions;
  final List<FilterOption>? subCategories;
  final List<FilterOption>? tags;

  CategoryFiltersData({this.sortOptions, this.subCategories, this.tags});

  factory CategoryFiltersData.fromJson(Map<String, dynamic> json) {
    return CategoryFiltersData(
      sortOptions: json['sort_options'] != null
          ? (json['sort_options'] as List)
              .map((v) => FilterOption.fromJson(v))
              .toList()
          : [],
      subCategories: json['sub_categories'] != null
          ? (json['sub_categories'] as List)
              .map((v) => FilterOption.fromJson(v))
              .toList()
          : [],
      tags: json['tags'] != null
          ? (json['tags'] as List)
              .map((v) => FilterOption.fromJson(v))
              .toList()
          : [],
    );
  }
}

class FilterOption {
  final String? key;
  final String? label;

  FilterOption({this.key, this.label});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      key: json['key']?.toString(),
      label: json['label']?.toString(),
    );
  }
}
