import '../../../../core/models/common_models.dart';

class HomePageModel {
  final int? status;
  final String? message;
  final HomePageData? data;

  HomePageModel({this.status, this.message, this.data});

  factory HomePageModel.fromJson(Map<String, dynamic> json) {
    return HomePageModel(
      status: json['status'] ?? 0,
      message: json['message'] ?? "Unknown Error",
      data: json['data'] != null ? HomePageData.fromJson(json['data']) : null,
    );
  }
}

class HomePageData {
  final HomeMainCategory? mainCategory;
  final List<HomeTabModel>? homeTabs;

  HomePageData({this.mainCategory, this.homeTabs});

  factory HomePageData.fromJson(Map<String, dynamic> json) {
    return HomePageData(
      mainCategory: json['main_category'] != null
          ? HomeMainCategory.fromJson(json['main_category'])
          : null,
      homeTabs: json['home_tabs'] != null
          ? (json['home_tabs'] as List)
                .map((v) => HomeTabModel.fromJson(v))
                .toList()
          : [],
    );
  }
}

class HomeMainCategory {
  final int? id;
  final String? uuId;
  final String? mainCategoryName;
  final String? slug;
  final String? mainCategoryImage;

  HomeMainCategory({
    this.id,
    this.uuId,
    this.mainCategoryName,
    this.slug,
    this.mainCategoryImage,
  });

  factory HomeMainCategory.fromJson(Map<String, dynamic> json) {
    return HomeMainCategory(
      id: json['id'] ?? 0,
      uuId: json['uu_id'] ?? "",
      mainCategoryName: json['main_category_name'] ?? "",
      slug: json['slug'] ?? "",
      mainCategoryImage: json['main_category_image'] ?? "",
    );
  }
}

class HomeTabModel {
  final int? id;
  final String? uuId;
  final String? slug;
  final String? tabName;
  final String? homeIcon;
  final int? priority;
  final bool? isActive;
  final List<HomeSectionModel>? homeSections;

  HomeTabModel({
    this.id,
    this.uuId,
    this.slug,
    this.tabName,
    this.homeIcon,
    this.priority,
    this.isActive,
    this.homeSections,
  });

  factory HomeTabModel.fromJson(Map<String, dynamic> json) {
    return HomeTabModel(
      id: json['id'] ?? 0,
      uuId: json['uu_id'] ?? "",
      slug: json['slug'] ?? "",
      tabName: json['tab_name'] ?? "",
      homeIcon: json['home_icon'] ?? "",
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? false,
      homeSections: json['home_sections'] != null
          ? (json['home_sections'] as List)
                .map((v) => HomeSectionModel.fromJson(v))
                .toList()
          : [],
    );
  }
}

class HomeSectionModel {
  final int? id;
  final String? title;
  final String? slug;
  final String? sectionType;
  final String? description;
  final List<BannerModel>? banners;
  final List<CategoryModel>? categories;
  final List<ProductModel>? products;

  HomeSectionModel({
    this.id,
    this.title,
    this.slug,
    this.sectionType,
    this.description,
    this.banners,
    this.categories,
    this.products,
  });

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    return HomeSectionModel(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      sectionType: json['section_type'],
      description: json['description'],
      banners: json['banners'] != null
          ? (json['banners'] as List)
                .map((v) => BannerModel.fromJson(v))
                .toList()
          : [],
      categories: json['categories'] != null
          ? (json['categories'] as List)
                .map((v) => CategoryModel.fromJson(v))
                .toList()
          : [],
      products: json['products'] != null
          ? (json['products'] as List)
                .map((v) => ProductModel.fromJson(v))
                .toList()
          : [],
    );
  }
}

class BannerModel {
  final int? id;
  final String? title;
  final String? image;
  final ProductModel? product;

  BannerModel({this.id, this.title, this.image, this.product});

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'])
          : null,
    );
  }
}

class CategoryModel {
  final int? id;
  final String? uuId;
  final String? categoryName;
  final String? slug;
  final String? categoryImage;
  final List<SubCategoryModel>? subCategories;

  CategoryModel({
    this.id,
    this.uuId,
    this.categoryName,
    this.slug,
    this.categoryImage,
    this.subCategories,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      uuId: json['uu_id'],
      categoryName: json['category_name'],
      slug: json['slug'],
      categoryImage: json['category_image'],
      subCategories: json['sub_categories'] != null
          ? (json['sub_categories'] as List)
                .map((v) => SubCategoryModel.fromJson(v))
                .toList()
          : [],
    );
  }
}

class SubCategoryModel {
  final int? id;
  final String? uuId;
  final String? subCategoryName;
  final String? slug;
  final String? subCategoryImage;
  final List<ProductModel>? products;

  SubCategoryModel({
    this.id,
    this.uuId,
    this.subCategoryName,
    this.slug,
    this.subCategoryImage,
    this.products,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id'],
      uuId: json['uu_id'],
      subCategoryName: json['sub_category_name'],
      slug: json['slug'],
      subCategoryImage: json['sub_category_image'],
      products: json['products'] != null
          ? (json['products'] as List)
                .map((v) => ProductModel.fromJson(v))
                .toList()
          : [],
    );
  }
}

class ProductTagModel {
  final int? id;
  final String? uuId;
  final String? tagName;

  ProductTagModel({this.id, this.uuId, this.tagName});

  factory ProductTagModel.fromJson(Map<String, dynamic> json) {
    return ProductTagModel(
      id: json['id'],
      uuId: json['uu_id'],
      tagName: json['tag_name'],
    );
  }
}

class ProductModel {
  final int? id;
  final String? uuId;
  final String? productName;
  final String? productShortName;
  final String? slug;
  final String? shortDescription;
  final String? longDescription;
  final String? hsnCode;
  final String? skuCode;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String? categoryUuId;
  final int? subCategoryId;
  final String? subCategoryName;
  final String? subCategorySlug;
  final String? subCategoryUuId;
  final String? productImage;
  final bool? isActive;
  final bool? isDeliverable;
  final bool? isWishlisted;
  final int? cartQuantity;
  final List<SharedVariantModel>? variants;
  final List<ImageModel>? images;
  final SharedRatingModel? rating;
  final List<ProductTagModel>? tags;
  final int? productViews;

  ProductModel({
    this.id,
    this.uuId,
    this.productName,
    this.productShortName,
    this.slug,
    this.shortDescription,
    this.longDescription,
    this.hsnCode,
    this.skuCode,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.categoryUuId,
    this.subCategoryId,
    this.subCategoryName,
    this.subCategorySlug,
    this.subCategoryUuId,
    this.productImage,
    this.isActive,
    this.isDeliverable,
    this.isWishlisted,
    this.cartQuantity,
    this.variants,
    this.images,
    this.rating,
    this.tags,
    this.productViews,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      uuId: json['uu_id'],
      productName: json['product_name'],
      productShortName: json['product_short_name'],
      slug: json['slug'],
      shortDescription: json['short_description'],
      longDescription: json['long_description'],
      hsnCode: json['hsn_code'],
      skuCode: json['sku_code'],
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'],
      categorySlug: json['category_slug'],
      categoryUuId: json['category_uu_id'],
      subCategoryId: json['sub_category_id'] as int?,
      subCategoryName: json['sub_category_name'],
      subCategorySlug: json['sub_category_slug'],
      subCategoryUuId: json['sub_category_uu_id'],
      productImage: json['product_image'] ??
          (() {
            final List? imgs = json['images'] as List?;
            if (imgs == null || imgs.isEmpty) return null;
            final primary = imgs.firstWhere(
              (img) => img is Map && img['is_primary'] == true,
              orElse: () => imgs.first,
            );
            return primary is Map ? primary['product_image'] : null;
          })(),
      isActive: json['is_active'],
      isDeliverable: (json['is_deliverable'] is bool)
          ? json['is_deliverable'] as bool
          : (json['is_deliverable'] == 1 || json['is_deliverable'] == '1' || json['is_deliverable'] == 'true'),
      isWishlisted: json['is_wishlisted'] as bool?,
      cartQuantity: (json['cart_quantity'] as num?)?.toInt(),
      variants: json['variants'] != null
          ? (json['variants'] as List)
                .map((v) => SharedVariantModel.fromJson(v))
                .toList()
          : [],
      images: json['images'] != null
          ? (json['images'] as List).map((v) => ImageModel.fromJson(v)).toList()
          : [],
      rating: json['rating'] != null ? SharedRatingModel.fromJson(json['rating']) : null,
      tags: json['tags'] != null
          ? (json['tags'] as List).map((v) => ProductTagModel.fromJson(v)).toList()
          : [],
      productViews: (json['product_views'] as num?)?.toInt() ?? (json['views'] as num?)?.toInt() ?? 0,
    );
  }
}

// Shared models moved to common_models.dart

class ImageModel {
  final int? id;
  final String? productImage;
  final bool? isPrimary;
  final String? publicId;

  ImageModel({this.id, this.productImage, this.isPrimary, this.publicId});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      productImage: json['product_image'],
      isPrimary: json['is_primary'],
      publicId: json['public_id'],
    );
  }
}

class CategoryProductsResponse {
  final int? status;
  final String? message;
  final CategoryModel? data;
  final List<ProductModel>? products;

  CategoryProductsResponse({this.status, this.message, this.data, this.products});

  factory CategoryProductsResponse.fromJson(Map<String, dynamic> json) {
    CategoryModel? parsedData;
    List<ProductModel>? parsedProducts;

    if (json['data'] != null) {
      if (json['data'] is List) {
        final list = json['data'] as List;
        parsedProducts = list
            .whereType<Map<String, dynamic>>()
            .map((v) => ProductModel.fromJson(v))
            .toList();
      } else if (json['data'] is Map<String, dynamic>) {
        parsedData = CategoryModel.fromJson(json['data'] as Map<String, dynamic>);
      }
    }

    return CategoryProductsResponse(
      status: json['status'],
      message: json['message'],
      data: parsedData,
      products: parsedProducts,
    );
  }
}
