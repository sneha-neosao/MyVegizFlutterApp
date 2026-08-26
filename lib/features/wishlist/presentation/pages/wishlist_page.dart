import 'package:my_vegiz_flutter/core/models/common_models.dart';
import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import 'package:my_vegiz_flutter/features/grocery_category/widget/grocery_product_card.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_event.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_state.dart';
import 'package:my_vegiz_flutter/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    context.read<WishlistBloc>().add(FetchWishlist());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'My Wishlist',
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: BlocConsumer<WishlistBloc, WishlistState>(
        listener: (context, state) {
          if (state is WishlistError) {
            SnackbarUtils.showErrorSnackbar(context, state.message);
          }
        },
        builder: (context, state) {
          final bloc = context.read<WishlistBloc>();
          
          if ((state is WishlistLoading || state is WishlistInitial) && bloc.currentItems.isEmpty) {
            return _buildWishlistShimmer();
          }

          final items = bloc.currentItems;

          if (items.isEmpty) {
            return _buildEmptyWishlist();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WishlistBloc>().add(FetchWishlist());
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.54,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                
                // Find the specific variant if it was saved, otherwise fallback to the first
                final selectedVariant = product.variants.firstWhere(
                  (v) => v.id == product.productVariantId,
                  orElse: () => product.variants.isNotEmpty 
                      ? product.variants.first 
                      : SharedVariantModel(),
                );

                // Compute total cart quantity for the product across all its variants
                final int productCartQty = product.variants.fold<int>(
                  0,
                  (sum, v) => sum + (v.cartQuantity),
                );

                return GroceryProductCard(
                  key: ValueKey(product.productId),
                  productId: product.productId,
                  image: product.productImage,
                  images: product.productImage.isNotEmpty ? [product.productImage] : const [],
                  title: product.productName,
                  rating: product.rating?.avgRating ?? 0.0,
                  totalReviews: product.rating?.totalReviews ?? 0,
                  views: product.productViews,
                  price: selectedVariant.sellingPrice ?? 0.0,
                  originalPrice: selectedVariant.actualPrice ?? 0.0,
                  slug: product.slug,
                  variantId: selectedVariant.id,
                  variants: product.variants,
                  isWishlisted: product.isSaved,
                  cartQuantity: selectedVariant.cartQuantity,
                  productCartQuantity: productCartQty,
                )
                .animate()
                .fadeIn(delay: (40 * index).ms)
                .slideY(begin: 0.08, end: 0);
              },
            ),
          );
        },
      )),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Your wishlist is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore products and add them here!',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: ShimmerPlaceholder.rectangular(
                    height: double.infinity,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder.rounded(
                      height: 14,
                      width: 100,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ShimmerPlaceholder.rounded(
                          height: 12,
                          width: 30,
                          borderRadius: 3,
                        ),
                        const SizedBox(width: 4),
                        const ShimmerPlaceholder.circular(
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 8),
                        const ShimmerPlaceholder.circular(
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 4),
                        ShimmerPlaceholder.rounded(
                          height: 12,
                          width: 30,
                          borderRadius: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ShimmerPlaceholder.rounded(
                          height: 14,
                          width: 40,
                          borderRadius: 4,
                        ),
                        const SizedBox(width: 6),
                        ShimmerPlaceholder.rounded(
                          height: 10,
                          width: 30,
                          borderRadius: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ShimmerPlaceholder.rounded(
                      height: 32,
                      width: double.infinity,
                      borderRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
