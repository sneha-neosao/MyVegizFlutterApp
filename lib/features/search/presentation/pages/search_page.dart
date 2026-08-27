import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/location_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../routes/app_route_path.dart';
import '../../../../widgets/custom_bottom_nav_bar.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import '../../../grocery_category/widget/grocery_product_card.dart';
import '../../bloc/search_bloc.dart';
import '../../bloc/search_event.dart';
import '../../bloc/search_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final loc = locationService.locationNotifier.value;
      context.read<SearchBloc>().add(
            SearchLoadMoreEvent(lat: loc?.lat, lng: loc?.lng),
          );
    }
  }

  void _onSearchChanged(String val) {
    setState(() {});
    final trimmed = val.trim();
    if (trimmed.isNotEmpty) {
      final loc = locationService.locationNotifier.value;
      context.read<SearchBloc>().add(
            SearchQueryChangedEvent(
              query: trimmed,
              lat: loc?.lat,
              lng: loc?.lng,
            ),
          );
    } else {
      context.read<SearchBloc>().add(const SearchClearEvent());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(AppRoutePath.home);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Search',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () {
              context.go(AppRoutePath.home);
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.w,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search product',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade500,
                      size: 20.w,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: Icon(
                              Icons.clear,
                              color: Colors.grey.shade500,
                              size: 18.w,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return _buildShimmerGrid();
                  } else if (state is SearchError) {
                    return _buildErrorState(state.message);
                  } else if (state is SearchLoaded) {
                    if (state.products.isEmpty) {
                      return _buildEmptyState(state.query);
                    }
                    return _buildProductsGrid(state);
                  }
                  return _buildInitialPrompt();
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
      ),
    );
  }

  Widget _buildProductsGrid(SearchLoaded state) {
    final products = state.products;
    final totalCount = products.length + (state.isPaginating ? 2 : 0);

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 80.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.59,
        crossAxisSpacing: 6.w,
        mainAxisSpacing: 6.h,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index >= products.length) {
          return ShimmerPlaceholder.rounded(
            height: 200.h,
            borderRadius: 12.w,
          );
        }
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
          isDeliverable: product.isDeliverable,
          productCartQuantity: product.cartQuantity ?? 0,
          tags: product.tags,
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 80.h),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ShimmerPlaceholder.rounded(
          height: 200.h,
          borderRadius: 12.w,
        );
      },
    );
  }

  Widget _buildInitialPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64.w,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 12.h),
          Text(
            'Search for grocery products',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64.w,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16.h),
            Text(
              "No results found",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "We couldn't find anything matching '$query'.\nTry checking the spelling or searching for different keywords.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.w,
              color: Colors.red.shade300,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _onSearchChanged(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC8019),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.w),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
