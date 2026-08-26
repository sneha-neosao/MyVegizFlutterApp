import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../config/injector_conf.dart';
import 'package:my_vegiz_flutter/features/grocery_category/widget/grocery_product_card.dart';
import '../data/models/homePage_model.dart';
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

class GrocerySubCategoryPage extends StatefulWidget {
  final HomeTabModel tabData;
  final Future<void> Function()? onRefresh;
  final String? initialCategorySlug;
  final String searchQuery;
  final String activeFilter;

  const GrocerySubCategoryPage({
    super.key,
    required this.tabData,
    this.onRefresh,
    this.initialCategorySlug,
    this.searchQuery = '',
    this.activeFilter = 'all',
  });

  @override
  State<GrocerySubCategoryPage> createState() => _GrocerySubCategoryPageState();
}

class _GrocerySubCategoryPageState extends State<GrocerySubCategoryPage>
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
    if (widget.initialCategorySlug != null) {
      final categories =
          widget.tabData.homeSections
              ?.expand((sec) => sec.categories ?? <CategoryModel>[])
              .toList() ??
          [];
      final match = categories.firstWhere(
        (cat) => cat.slug == widget.initialCategorySlug,
        orElse: () => CategoryModel(),
      );
      if (match.id != null && match.slug != null) {
        _navigateToProductsPage(match);
      }
    }
  }

  void _navigateToProductsPage(CategoryModel cat) {
    final loc = locationService.locationNotifier.value;
    final lat = loc?.lat ?? 0.0;
    final lng = loc?.lng ?? 0.0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<CategoryProductsBloc>(
              create: (context) => getIt<CategoryProductsBloc>()
                ..add(
                  FetchProductsAndFiltersEvent(
                    categorySlug: cat.slug!,
                    lat: lat,
                    lng: lng,
                    resetFilters: true,
                  ),
                ),
            ),
          ],
          child: GrocerySubCategoryProductsPage(
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

    if (sections.isEmpty) {
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
          slivers.add(_buildCategoryGrid(filteredCats));
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
              .where((p) => _isGroceryProductVeg(p.productName ?? ''))
              .toList();
        } else if (widget.activeFilter == 'nonveg') {
          filteredProds = filteredProds
              .where((p) => !_isGroceryProductVeg(p.productName ?? ''))
              .toList();
        }
        if (filteredProds.isNotEmpty) {
          if (section.title != null) {
            slivers.add(_buildSectionHeader(section.title!));
          }
          slivers.add(_buildProductGrid(filteredProds));
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
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 14),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<CategoryModel> categories) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.60,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () => _navigateToProductsPage(cat),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1.5,
                      ),
                    ),
                    child: cat.categoryImage != null
                        ? Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: ClipOval(
                              child: Image.network(
                                cat.categoryImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    cat.categoryName ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          );
        }, childCount: categories.length),
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
          childAspectRatio: 0.59,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
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
          );
        }, childCount: products.length),
      ),
    );
  }
}

// ── Private Top-level Helpers ──────────────────────────────────────────────────

bool _isGroceryProductVeg(String productName) {
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

// ── GrocerySubCategoryProductsPage ─────────────────────────────────────────────

class GrocerySubCategoryProductsPage extends StatefulWidget {
  final CategoryModel category;
  final HomeTabModel tabData;
  final String searchQuery;
  final String activeFilter;
  final Future<void> Function()? onRefresh;

  const GrocerySubCategoryProductsPage({
    super.key,
    required this.category,
    required this.tabData,
    this.searchQuery = '',
    this.activeFilter = 'all',
    this.onRefresh,
  });

  @override
  State<GrocerySubCategoryProductsPage> createState() =>
      _GrocerySubCategoryProductsPageState();
}

class _GrocerySubCategoryProductsPageState
    extends State<GrocerySubCategoryProductsPage> {
  SubCategoryModel? selectedSubCategory;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartActionSuccess) {
          logger.i('🛒 GrocerySubCategoryProductsPage: CartActionSuccess detected! Re-fetching product list.');
          final prodBloc = context.read<CategoryProductsBloc>();
          final prodState = prodBloc.state;
          if (prodState is CategoryProductsLoaded) {
            prodBloc.add(FilterSubCategoryChangedEvent(prodState.selectedSubCategoryUuId));
          } else if (widget.category.slug != null) {
            final loc = locationService.locationNotifier.value;
            prodBloc.add(
              FetchProductsAndFiltersEvent(
                categorySlug: widget.category.slug!,
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
                                _buildFilterBar(state),
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
                context.read<CategoryProductsBloc>().add(
                  FetchProductsAndFiltersEvent(
                    categorySlug: widget.category.slug!,
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
    final subCategories =
        state.categoryFiltersResponse.data?.subCategories ?? [];
    final productsSubCategories =
        state.categoryProductsResponse.data?.subCategories ?? [];

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
          final isSelected = state.selectedSubCategoryUuId == sub.key;

          final matchedSub = widget.category.subCategories?.firstWhere(
                (psub) => psub.uuId == sub.key,
                orElse: () => productsSubCategories.firstWhere(
                  (psub) => psub.uuId == sub.key,
                  orElse: () => SubCategoryModel(),
                ),
              ) ??
              SubCategoryModel();
          final image = matchedSub.subCategoryImage;

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

  Widget _buildFilterBar(CategoryProductsLoaded state) {
    final filters = state.categoryFiltersResponse.data?.tags ?? [];
    if (filters.isEmpty) return const SizedBox.shrink();

    final activeFilter = state.selectedTagUuId;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showSortOptionsBottomSheet(context, state),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Sort',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: filters.map((filter) {
                  final isSelected = activeFilter == filter.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        context.read<CategoryProductsBloc>().add(
                          FilterTagChangedEvent(filter.key),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFC8019)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFC8019)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          filter.label ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
    var products = (state.categoryProductsResponse.products ??
        state.categoryProductsResponse.data?.subCategories
            ?.where((sub) => activeSubUuid == null || sub.uuId == activeSubUuid)
            .expand((sub) => sub.products ?? <ProductModel>[])
            .toList() ??
        []);

    // Filter by subcategory client-side to ensure only products of selected subcategory are shown
    if (activeSubUuid != null) {
      products = products
          .where((p) => p.subCategoryUuId == activeSubUuid)
          .toList();
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
          .where((p) => _isGroceryProductVeg(p.productName ?? ''))
          .toList();
    } else if (widget.activeFilter == 'nonveg') {
      products = products
          .where((p) => !_isGroceryProductVeg(p.productName ?? ''))
          .toList();
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(4.w, 4.h, 6.w, 90.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.59,
        crossAxisSpacing: 5.w,
        mainAxisSpacing: 6.h,
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
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
          Text(
            widget.searchQuery.isNotEmpty
                ? 'No products matching your search'
                : 'No products in this sub-category',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
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
    final sorts = state.categoryFiltersResponse.data?.sortOptions ?? [];
    if (sorts.isEmpty) return;

    final activeSort = state.selectedSortBy;
    final cartBloc = context.read<CartBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: cartBloc,
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              CartData? cart;
              if (cartState is CartLoaded) {
                cart = cartState.cartData;
              } else if (cartState is CartActionSuccess && cartState.cartData != null) {
                cart = cartState.cartData;
              } else if (cartState is CartLoading && cartState.cartData != null) {
                cart = cartState.cartData;
              } else if (cartState is CartError && cartState.cartData != null) {
                cart = cartState.cartData;
              }

              final hasCartItems = cart != null &&
                  ((cart.items != null && cart.items!.isNotEmpty) ||
                      (cart.totalItems ?? 0) > 0);

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sort by',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: sorts.map((sort) {
                        final isSelected = activeSort == sort.key;
                        return InkWell(
                          onTap: () {
                            this.context.read<CategoryProductsBloc>().add(
                                  FilterSortChangedEvent(sort.key),
                                );
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sort.label ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFFFC8019)
                                        : Colors.black87,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFFFC8019),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (hasCartItems) ...[
                      const SizedBox(height: 16),
                      FloatingViewCartBar(
                        margin: EdgeInsets.zero,
                        onTap: () {
                          Navigator.pop(context);
                          this.context.push(AppRoutePath.cart, extra: false);
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
