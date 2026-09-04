import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../config/injector_conf.dart';
import 'package:my_vegiz_flutter/features/grocery_category/widget/grocery_product_card.dart';
import '../data/models/homePage_model.dart';
import '../data/models/home_tab_sub_categories_model.dart';
import '../data/models/sub_categories_by_category_model.dart';
import '../data/models/category_filters_model.dart';
import '../bloc/categoryProducts/category_products_bloc.dart';
import '../bloc/categoryProducts/category_products_event.dart';
import '../bloc/categoryProducts/category_products_state.dart';
import '../../../routes/app_route_path.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/location_service.dart';
import '../../../widgets/shimmer_placeholder.dart';
import '../../../widgets/floating_view_cart_bar.dart';
import '../widgets/grocery_banner_slider.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_state.dart';
import 'package:my_vegiz_flutter/features/cart/data/models/cart_model.dart';

class CategorySubcategoryPage extends StatefulWidget {
  final HomeTabModel tabData;
  final Future<void> Function()? onRefresh;
  final String? initialCategorySlug;
  final String searchQuery;
  final String activeFilter;
  final List<Widget>? topSlivers;
  final Widget? pinnedHeader;
  final double? pinnedHeaderHeight;

  const CategorySubcategoryPage({
    super.key,
    required this.tabData,
    this.onRefresh,
    this.initialCategorySlug,
    this.searchQuery = '',
    this.activeFilter = 'all',
    this.topSlivers,
    this.pinnedHeader,
    this.pinnedHeaderHeight,
  });

  @override
  State<CategorySubcategoryPage> createState() => _CategorySubcategoryPageState();
}

class _CategorySubcategoryPageState extends State<CategorySubcategoryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialCategory();
    });
  }

  void _handleInitialCategory() {
    if (widget.initialCategorySlug != null && widget.initialCategorySlug!.isNotEmpty) {
      final categories =
          widget.tabData.homeSections
              ?.expand((sec) => sec.categories ?? <CategoryModel>[])
              .toList() ??
          [];
      final match = categories.firstWhere(
        (cat) => cat.slug == widget.initialCategorySlug,
        orElse: () => CategoryModel(),
      );
      final targetCat = (match.id != null && match.slug != null)
          ? match
          : CategoryModel(
              id: 0,
              slug: widget.initialCategorySlug,
              categoryName: widget.initialCategorySlug?.replaceAll('-', ' ').toUpperCase(),
            );
      if (targetCat.slug != null && targetCat.slug!.isNotEmpty) {
        _navigateToProductsPage(targetCat);
      }
    }
  }

  void _navigateToProductsPage(CategoryModel cat) {
    final loc = locationService.locationNotifier.value;
    final lat = loc?.lat ?? 0.0;
    final lng = loc?.lng ?? 0.0;
    final firstSubUuid = cat.subCategories?.firstOrNull?.uuId;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<CategoryProductsBloc>(
              create: (context) => getIt<CategoryProductsBloc>()
                ..add(
                  FetchProductsAndFiltersEvent(
                    homeTabId: null,
                    homeTabUuId: null,
                    categorySlug: cat.slug,
                    subCategoryUuId: null,
                    lat: lat,
                    lng: lng,
                    resetFilters: true,
                  ),
                ),
            ),
          ],
          child: CategorySubcategoryProductPage(
            category: cat,
            tabData: widget.tabData,
            searchQuery: widget.searchQuery,
            activeFilter: widget.activeFilter,
            onRefresh: widget.onRefresh,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sections = widget.tabData.homeSections ?? [];

    if (sections.isEmpty && (widget.topSlivers == null || widget.topSlivers!.isEmpty)) {
      return const Center(
        child: Text(
          'No specific data for this tab',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: CustomScrollView(
        key: PageStorageKey('grocery_scroll_${widget.tabData.id}'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: _buildSlivers(sections),
      ),
    );
  }

  List<Widget> _buildSlivers(List<HomeSectionModel> sections) {
    // This is for the main Category discovery page (when no category is selected)
    final slivers = <Widget>[];

    // Prepend top slivers (e.g. banners)
    if (widget.topSlivers != null && widget.topSlivers!.isNotEmpty) {
      slivers.addAll(widget.topSlivers!);
    }

    // Header for category cards & ongoing order
    if (widget.pinnedHeader != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: widget.pinnedHeader!,
        ),
      );
    }

    for (var section in sections) {
      if (section.sectionType == 'banner' &&
          section.banners != null &&
          section.banners!.isNotEmpty) {
        if (widget.searchQuery.isEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: GroceryBannerSlider(banners: section.banners!),
            ),
          );
        }
      } else if (section.sectionType == 'category_list' &&
          section.categories != null &&
          section.categories!.isNotEmpty) {
        var filteredCats = section.categories!;
        if (widget.searchQuery.isNotEmpty) {
          filteredCats = filteredCats
              .where(
                (c) => (c.categoryName ?? '').toLowerCase().contains(
                  widget.searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }
        if (filteredCats.isNotEmpty) {
          if (section.title != null) {
            slivers.add(_buildSectionHeader(section.title!));
          }
          slivers.add(_buildHorizontalCategoryList(filteredCats));
        }
      } else if (section.sectionType == 'product_list' &&
          section.products != null &&
          section.products!.isNotEmpty) {
        var filteredProds = section.products!;
        if (widget.searchQuery.isNotEmpty) {
          filteredProds = filteredProds
              .where(
                (p) => (p.productName ?? '').toLowerCase().contains(
                  widget.searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }
        if (widget.activeFilter == 'veg') {
          filteredProds = filteredProds
              .where((p) => _isCategoryProductVeg(p.productName ?? ''))
              .toList();
        } else if (widget.activeFilter == 'nonveg') {
          filteredProds = filteredProds
              .where((p) => !_isCategoryProductVeg(p.productName ?? ''))
              .toList();
        }
        if (filteredProds.isNotEmpty) {
          if (section.title != null) {
            slivers.add(_buildSectionHeader(section.title!));
          }
          // Always use horizontal scroll showing 3 products at a time
          slivers.add(_buildHorizontalProductList(filteredProds));
        }
      }
    }

    if (slivers.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.searchQuery.isNotEmpty
                        ? 'No matches found'
                        : 'No items available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.searchQuery.isNotEmpty)
                    Text(
                      "We couldn't find anything matching '${widget.searchQuery}'.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: const Color(0xFF111827),
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCategoryList(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 98.h,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (context, index) => SizedBox(width: 12.w),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return GestureDetector(
              onTap: () => _navigateToProductsPage(cat),
              child: SizedBox(
                width: 72.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                      ),
                      child: cat.categoryImage != null && cat.categoryImage!.isNotEmpty
                          ? ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Image.network(
                                  cat.categoryImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.category, size: 26.w, color: Colors.grey.shade400),
                                ),
                              ),
                            )
                          : Icon(Icons.category, size: 26.w, color: Colors.grey.shade400),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      cat.categoryName ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No products available')),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.57,
          crossAxisSpacing: 11,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          final imagesList = (product.images != null && product.images!.isNotEmpty)
              ? product.images!
                  .map((img) => img.productImage ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList()
              : (product.productImage != null && product.productImage!.isNotEmpty
                  ? [product.productImage!]
                  : <String>[]);

          return GroceryProductCard(
            key: ValueKey(product.id),
            productId: product.id,
            image: product.productImage ?? '',
            images: imagesList,
            title: product.productName ?? 'Product',
            rating: product.rating?.avgRating ?? 0.0,
            totalReviews: product.rating?.totalReviews ?? 0,
            views: product.productViews ?? 0,
            price: product.variants?.firstOrNull?.sellingPrice ?? 0.0,
            originalPrice: product.variants?.firstOrNull?.actualPrice ?? 0.0,
            slug: product.slug ?? '',
            variantId: product.variants?.firstOrNull?.id,
            cartQuantity: product.variants?.firstOrNull?.cartQuantity ?? 0,
            variants: product.variants ?? [],
            isWishlisted: product.isWishlisted ?? false,
            productCartQuantity: product.cartQuantity ?? 0,
            tags: product.tags,
          );
        }, childCount: products.length),
      ),
    );
  }

  Widget _buildHorizontalProductList(List<ProductModel> products) {
    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Exactly 3 cards visible per line with comfortable padding and spacing
          final screenWidth = constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          const double horizontalPadding = 14.0;
          const double itemSpacing = 8.0;
          final double cardWidth =
              (screenWidth - (horizontalPadding * 2) - (itemSpacing * 2)) / 3;

          return SizedBox(
            height: 225.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => SizedBox(width: itemSpacing.w),
              itemBuilder: (context, index) {
                final product = products[index];
                final imagesList = (product.images != null && product.images!.isNotEmpty)
                    ? product.images!
                        .map((img) => img.productImage ?? '')
                        .where((s) => s.isNotEmpty)
                        .toList()
                    : (product.productImage != null && product.productImage!.isNotEmpty
                        ? [product.productImage!]
                        : <String>[]);

                return SizedBox(
                  width: cardWidth,
                  child: GroceryProductCard(
                    key: ValueKey('h_prod_${product.id}'),
                    productId: product.id,
                    image: product.productImage ?? '',
                    images: imagesList,
                    title: product.productName ?? 'Product',
                    rating: product.rating?.avgRating ?? 0.0,
                    totalReviews: product.rating?.totalReviews ?? 0,
                    views: product.productViews ?? 0,
                    price: product.variants?.firstOrNull?.sellingPrice ?? 0.0,
                    originalPrice: product.variants?.firstOrNull?.actualPrice ?? 0.0,
                    slug: product.slug ?? '',
                    variantId: product.variants?.firstOrNull?.id,
                    cartQuantity: product.variants?.firstOrNull?.cartQuantity ?? 0,
                    variants: product.variants ?? [],
                    isWishlisted: product.isWishlisted ?? false,
                    productCartQuantity: product.cartQuantity ?? 0,
                    tags: product.tags,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Private Top-level Helpers ──────────────────────────────────────────────────

bool _isCategoryProductVeg(String productName) {
  final name = productName.toLowerCase();
  final nonVegKeywords = [
    'chicken',
    'meat',
    'egg',
    'fish',
    'pork',
    'beef',
    'mutton',
    'lamb',
    'prawn',
    'crab',
    'shrimp',
    'seafood',
    'bacon',
    'sausage',
    'salami',
    'nonveg',
    'non-veg',
  ];
  for (final keyword in nonVegKeywords) {
    if (name.contains(keyword)) {
      return false;
    }
  }
  return true;
}

// ── CategorySubcategoryProductPage ─────────────────────────────────────────────

class CategorySubcategoryProductPage extends StatefulWidget {
  final CategoryModel category;
  final HomeTabModel tabData;
  final String searchQuery;
  final String activeFilter;
  final Future<void> Function()? onRefresh;

  const CategorySubcategoryProductPage({
    super.key,
    required this.category,
    required this.tabData,
    this.searchQuery = '',
    this.activeFilter = 'all',
    this.onRefresh,
  });

  @override
  State<CategorySubcategoryProductPage> createState() =>
      _CategorySubcategoryProductPageState();
}

class _CategorySubcategoryProductPageState
    extends State<CategorySubcategoryProductPage> {
  SubCategoryModel? selectedSubCategory;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartActionSuccess) {
          logger.i('🛒 CategorySubcategoryProductPage: CartActionSuccess detected! Re-fetching product list.');
          final prodBloc = context.read<CategoryProductsBloc>();
          final prodState = prodBloc.state;
          if (prodState is CategoryProductsLoaded) {
            prodBloc.add(FilterSubCategoryChangedEvent(prodState.selectedSubCategoryUuId));
          } else if (widget.category.slug != null) {
            final loc = locationService.locationNotifier.value;
            final firstSubUuid = selectedSubCategory?.uuId ?? widget.category.subCategories?.firstOrNull?.uuId;
            prodBloc.add(
              FetchProductsAndFiltersEvent(
                homeTabId: null,
                homeTabUuId: null,
                categorySlug: widget.category.slug,
                subCategoryUuId: firstSubUuid,
                lat: loc?.lat ?? 0.0,
                lng: loc?.lng ?? 0.0,
                resetFilters: false,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.category.categoryName ?? '',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: Colors.black87,
                size: 24.w,
              ),
              onPressed: () {
                context.push(AppRoutePath.search);
              },
            ),
            IconButton(
              icon: Image.asset(
                'assets/images/heart_icon.png',
                width: 28.w,
                height: 28.w,
                fit: BoxFit.contain,
              ),
              onPressed: () {
                context.push(AppRoutePath.wishlist);
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.grey.shade200,
              height: 1,
            ),
          ),
        ),
        body: SafeArea(
          bottom: true,
          top: false,
          child: Stack(
            children: [
              BlocBuilder<CategoryProductsBloc, CategoryProductsState>(
                builder: (context, state) {
                  if (state is CategoryProductsLoading) {
                    return _buildLoadingState();
                  } else if (state is CategoryProductsError) {
                    return _buildErrorState(state.message);
                  } else if (state is CategoryProductsLoaded) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 6.w),
                          child: _buildSubCategorySidebar(state),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                _buildSortBar(state),
                                Expanded(child: _buildProductContent(state)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Positioned(
                bottom: 20.h,
                left: 0,
                right: 0,
                child: const FloatingViewCartBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 6.w),
          child: Container(
            width: 68.w,
            color: Colors.grey.shade50,
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 8.w,
                ),
                child: Column(
                  children: [
                    ShimmerPlaceholder.circular(height: 46.w, width: 46.w),
                    SizedBox(height: 6.h),
                    ShimmerPlaceholder.rounded(height: 10.h, width: 42.w),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: _buildShimmerProductsGrid()),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (widget.category.slug != null) {
                final loc = locationService.locationNotifier.value;
                final firstSubUuid = selectedSubCategory?.uuId ?? widget.category.subCategories?.firstOrNull?.uuId;
                context.read<CategoryProductsBloc>().add(
                  FetchProductsAndFiltersEvent(
                    homeTabId: null,
                    homeTabUuId: null,
                    categorySlug: widget.category.slug,
                    subCategoryUuId: firstSubUuid,
                    lat: loc?.lat ?? 0.0,
                    lng: loc?.lng ?? 0.0,
                    resetFilters: true,
                  ),
                );
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategorySidebar(CategoryProductsLoaded state) {
    List<FilterOption> subCategories = [];

    if (state.subCategoriesByCategory != null && state.subCategoriesByCategory!.isNotEmpty) {
      subCategories = state.subCategoriesByCategory!
          .map((s) => FilterOption(
                key: (s.subCategoryUuid != null && s.subCategoryUuid!.isNotEmpty) ? s.subCategoryUuid! : s.uuId,
                label: s.subCategoryName,
              ))
          .toList();
    } else if (state.categoryFiltersResponse.data?.subCategories != null && state.categoryFiltersResponse.data!.subCategories!.isNotEmpty) {
      subCategories = state.categoryFiltersResponse.data!.subCategories!;
    } else if (state.homeTabSubCategories != null && state.homeTabSubCategories!.isNotEmpty) {
      subCategories = state.homeTabSubCategories!
          .map((s) => FilterOption(key: s.uuId, label: s.subCategoryName))
          .toList();
    }

    if (subCategories.isEmpty && widget.tabData.homeSections != null && widget.tabData.homeSections!.isNotEmpty) {
      final seenUuids = <String>{};
      final list = <FilterOption>[];
      for (var section in widget.tabData.homeSections!) {
        if (section.categories != null) {
          for (var cat in section.categories!) {
            if (cat.subCategories != null) {
              for (var sub in cat.subCategories!) {
                final uuid = sub.uuId ?? '';
                final name = sub.subCategoryName ?? '';
                if (uuid.isNotEmpty && !seenUuids.contains(uuid)) {
                  seenUuids.add(uuid);
                  list.add(FilterOption(key: uuid, label: name));
                }
              }
            }
          }
        }
      }
      if (list.isNotEmpty) subCategories = list;
    }

    if (subCategories.isEmpty && widget.category.subCategories != null && widget.category.subCategories!.isNotEmpty) {
      subCategories = widget.category.subCategories!
          .where((s) => (s.uuId ?? '').isNotEmpty)
          .map((s) => FilterOption(key: s.uuId!, label: s.subCategoryName ?? ''))
          .toList();
    }

    if (subCategories.isEmpty && state.categoryProductsResponse.data?.subCategories != null && state.categoryProductsResponse.data!.subCategories!.isNotEmpty) {
      subCategories = state.categoryProductsResponse.data!.subCategories!
          .where((s) => (s.uuId ?? '').isNotEmpty)
          .map((s) => FilterOption(key: s.uuId!, label: s.subCategoryName ?? ''))
          .toList();
    }

    final subCatsByCategory = state.subCategoriesByCategory ?? [];
    final homeTabSubs = state.homeTabSubCategories ?? [];
    final productsSubCategories =
        state.categoryProductsResponse.data?.subCategories ?? [];

    final String? activeSelectedKey = state.selectedSubCategoryUuId ??
        (subCategories.isNotEmpty ? subCategories.first.key : null);

    return Container(
      width: 68.w,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView.builder(
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          final sub = subCategories[index];
          final isSelected = activeSelectedKey == sub.key;

          String? image;
          if (subCatsByCategory.isNotEmpty) {
            final matched = subCatsByCategory.firstWhere(
              (s) => s.uuId == sub.key || s.subCategoryUuid == sub.key,
              orElse: () => SubCategoryByCategoryItemModel(
                id: 0,
                uuId: '',
                subCategoryName: '',
                slug: '',
                isActive: true,
                createdAt: '',
              ),
            );
            if (matched.subCategoryImage != null && matched.subCategoryImage!.isNotEmpty) {
              image = matched.subCategoryImage;
            }
          }

          if ((image == null || image.isEmpty) && homeTabSubs.isNotEmpty) {
            final matched = homeTabSubs.firstWhere(
              (s) => s.uuId == sub.key,
              orElse: () => HomeTabSubCategoryItemModel(
                id: 0,
                uuId: '',
                subCategoryName: '',
                slug: '',
                isActive: true,
                createdAt: '',
              ),
            );
            if (matched.subCategoryImage != null && matched.subCategoryImage!.isNotEmpty) {
              image = matched.subCategoryImage;
            }
          }

          if ((image == null || image.isEmpty) && widget.tabData.homeSections != null) {
            for (var section in widget.tabData.homeSections!) {
              if (section.categories != null) {
                for (var cat in section.categories!) {
                  if (cat.subCategories != null) {
                    for (var s in cat.subCategories!) {
                      if (s.uuId == sub.key && s.subCategoryImage != null && s.subCategoryImage!.isNotEmpty) {
                        image = s.subCategoryImage;
                        break;
                      }
                    }
                  }
                  if (image != null && image.isNotEmpty) break;
                }
              }
              if (image != null && image.isNotEmpty) break;
            }
          }

          if (image == null || image.isEmpty) {
            final matchedSub = widget.category.subCategories?.firstWhere(
                  (psub) => psub.uuId == sub.key,
                  orElse: () => productsSubCategories.firstWhere(
                    (psub) => psub.uuId == sub.key,
                    orElse: () => SubCategoryModel(),
                  ),
                ) ??
                SubCategoryModel();
            image = matchedSub.subCategoryImage;
          }

          return InkWell(
            onTap: () {
              context.read<CategoryProductsBloc>().add(
                FilterSubCategoryChangedEvent(sub.key),
              );
            },
            child: Container(
              height: 98.h,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0F7F4) : Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFF03B875),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 8.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 46.w,
                            height: 46.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF03B875) : Colors.white,
                                width: isSelected ? 1.5 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.08),
                                  blurRadius: isSelected ? 4 : 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (image != null && image.isNotEmpty)
                                  ? Image.network(
                                      image,
                                      width: 46.w,
                                      height: 46.w,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.white,
                                        child: Icon(
                                          Icons.category_outlined,
                                          size: 20.w,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.white,
                                      child: Icon(
                                        Icons.category_outlined,
                                        size: 20.w,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            sub.label ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF028A58)
                                  : const Color(0xFF5A6F82),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _sortLabel(String? key) {
    switch (key) {
      case 'price_asc':
        return 'Price: Low to High';
      case 'price_desc':
        return 'Price: High to Low';
      case 'rating_asc':
        return 'Rating: Low to High';
      case 'rating_desc':
        return 'Rating: High to Low';
      default:
        return 'Sort';
    }
  }

  Widget _buildSortBar(CategoryProductsLoaded state) {
    final activeSort = state.selectedSortBy;
    final bool isSorted = activeSort != null && activeSort.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 10.w, 4.h),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _showSortOptionsBottomSheet(context, state),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: isSorted ? const Color(0xFFEAF7EE) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(
                  color: isSorted ? const Color(0xFF028A58) : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 15.w,
                    color: isSorted ? const Color(0xFF028A58) : const Color(0xFF475569),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _sortLabel(activeSort),
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: isSorted ? FontWeight.w700 : FontWeight.w600,
                      color: isSorted ? const Color(0xFF028A58) : const Color(0xFF334155),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15.w,
                    color: isSorted ? const Color(0xFF028A58) : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (isSorted)
            GestureDetector(
              onTap: () {
                context.read<CategoryProductsBloc>().add(
                  FilterSortChangedEvent(null),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerProductsGrid() {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(4.w, 12, 6.w, 80.h),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  child: Center(
                    child: ShimmerPlaceholder.rounded(
                      height: 80,
                      width: 80,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ShimmerPlaceholder.rounded(height: 14, width: 100),
              const SizedBox(height: 6),
              ShimmerPlaceholder.rounded(height: 12, width: 60),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerPlaceholder.rounded(height: 16, width: 40),
                  ShimmerPlaceholder.rounded(height: 28, width: 45),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductContent(CategoryProductsLoaded state) {
    if (state.isProductsLoading) {
      return _buildShimmerProductsGrid();
    }

    final activeSubUuid = state.selectedSubCategoryUuId;
    List<ProductModel> products = [];
    if (state.categoryProductsResponse.products != null) {
      products.addAll(state.categoryProductsResponse.products!);
    } else if (state.categoryProductsResponse.data?.subCategories != null) {
      for (final sub in state.categoryProductsResponse.data!.subCategories!) {
        if (activeSubUuid == null || sub.uuId == activeSubUuid) {
          if (sub.products != null) {
            products.addAll(sub.products!);
          }
        }
      }
    }

    // Only filter by subcategory client-side if products have explicit subCategoryUuId populated
    if (activeSubUuid != null &&
        products.any((p) => p.subCategoryUuId != null && p.subCategoryUuId!.isNotEmpty)) {
      final filtered = products.where((p) => p.subCategoryUuId == activeSubUuid).toList();
      if (filtered.isNotEmpty) {
        products = filtered;
      }
    }

    if (widget.searchQuery.isNotEmpty) {
      products = products
          .where(
            (p) => (p.productName ?? '').toLowerCase().contains(
              widget.searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    if (widget.activeFilter == 'veg') {
      products = products
          .where((p) => _isCategoryProductVeg(p.productName ?? ''))
          .toList();
    } else if (widget.activeFilter == 'nonveg') {
      products = products
          .where((p) => !_isCategoryProductVeg(p.productName ?? ''))
          .toList();
    }

    final activeSort = state.selectedSortBy;
    if (activeSort != null && activeSort.isNotEmpty) {
      if (activeSort == 'price_asc') {
        products.sort((a, b) {
          final pA = a.variants?.firstOrNull?.sellingPrice ?? 0.0;
          final pB = b.variants?.firstOrNull?.sellingPrice ?? 0.0;
          return pA.compareTo(pB);
        });
      } else if (activeSort == 'price_desc') {
        products.sort((a, b) {
          final pA = a.variants?.firstOrNull?.sellingPrice ?? 0.0;
          final pB = b.variants?.firstOrNull?.sellingPrice ?? 0.0;
          return pB.compareTo(pA);
        });
      } else if (activeSort == 'rating_asc') {
        products.sort((a, b) {
          final rA = a.rating?.avgRating ?? 0.0;
          final rB = b.rating?.avgRating ?? 0.0;
          return rA.compareTo(rB);
        });
      } else if (activeSort == 'rating_desc') {
        products.sort((a, b) {
          final rA = a.rating?.avgRating ?? 0.0;
          final rB = b.rating?.avgRating ?? 0.0;
          return rB.compareTo(rA);
        });
      }
    }

    if (products.isEmpty) {
      return _buildEmptyState(state);
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(5.w, 4.h, 5.w, 90.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.57,
        crossAxisSpacing: 11.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final imagesList = (product.images != null && product.images!.isNotEmpty)
            ? product.images!
                .map((img) => img.productImage ?? '')
                .where((s) => s.isNotEmpty)
                .toList()
            : (product.productImage != null && product.productImage!.isNotEmpty
                ? [product.productImage!]
                : <String>[]);

        return GroceryProductCard(
          key: ValueKey(product.id),
          productId: product.id,
          image: product.productImage ?? '',
          images: imagesList,
          title: product.productName ?? 'Product',
          rating: product.rating?.avgRating ?? 0.0,
          totalReviews: product.rating?.totalReviews ?? 0,
          views: product.productViews ?? 0,
          price: product.variants?.firstOrNull?.sellingPrice ?? 0.0,
          originalPrice: product.variants?.firstOrNull?.actualPrice ?? 0.0,
          slug: product.slug ?? '',
          variantId: product.variants?.firstOrNull?.id,
          cartQuantity: product.variants?.firstOrNull?.cartQuantity ?? 0,
          variants: product.variants ?? [],
          isWishlisted: product.isWishlisted ?? false,
          productCartQuantity: product.cartQuantity ?? 0,
          siblingProducts: products
              .map((p) => {
                    'slug': p.slug ?? '',
                    'variantId': p.variants?.firstOrNull?.id,
                    'title': p.productName ?? '',
                    'image': p.productImage ?? '',
                  })
              .toList(),
          siblingIndex: index,
          tags: product.tags,
        );
      },
    );
  }

  Widget _buildEmptyState(CategoryProductsLoaded state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (widget.category.slug != null) {
                final loc = locationService.locationNotifier.value;
                final activeSubUuid = state.selectedSubCategoryUuId;
                context.read<CategoryProductsBloc>().add(
                  FetchProductsAndFiltersEvent(
                    homeTabId: null,
                    homeTabUuId: null,
                    categorySlug: widget.category.slug,
                    subCategoryUuId: activeSubUuid,
                    lat: loc?.lat ?? 0.0,
                    lng: loc?.lng ?? 0.0,
                    resetFilters: false,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC8019),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptionsBottomSheet(
    BuildContext context,
    CategoryProductsLoaded state,
  ) {
    final activeSort = state.selectedSortBy;
    final parentContext = context;

    final sortOptions = [
      {'key': 'price_asc', 'label': 'Price Low To High'},
      {'key': 'price_desc', 'label': 'Price High To low'},
      {'key': 'rating_asc', 'label': 'Rating Low To High'},
      {'key': 'rating_desc', 'label': 'Rating high To Low'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort by',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E242B),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (activeSort != null)
                        TextButton(
                          onPressed: () {
                            parentContext.read<CategoryProductsBloc>().add(
                              FilterSortChangedEvent(null),
                            );
                            Navigator.pop(bottomSheetContext);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      SizedBox(width: 4.w),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 6.h),
              ...sortOptions.map((opt) {
                final key = opt['key']!;
                final label = opt['label']!;
                final isSelected = activeSort == key;

                return InkWell(
                  onTap: () {
                    parentContext.read<CategoryProductsBloc>().add(
                      FilterSortChangedEvent(isSelected ? null : key),
                    );
                    Navigator.pop(bottomSheetContext);
                  },
                  borderRadius: BorderRadius.circular(10.w),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                    child: Row(
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF028A58)
                                  : const Color(0xFFCBD5E1),
                              width: isSelected ? 6.w : 1.5.w,
                            ),
                            color: isSelected ? Colors.white : Colors.transparent,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF028A58)
                                  : const Color(0xFF1E242B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StickyCategoryCardsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyCategoryCardsHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryCardsHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
