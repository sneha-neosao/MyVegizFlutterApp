import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_state.dart';
import 'package:my_vegiz_flutter/features/cart/data/models/cart_model.dart';
import 'package:my_vegiz_flutter/features/cart/presentation/widgets/cart_conflict_dialog.dart';
import 'package:my_vegiz_flutter/widgets/floating_view_cart_bar.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_event.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_state.dart';
import '../../../core/models/common_models.dart';
import '../../../core/utils/location_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/network_images.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../routes/app_route_path.dart';

class GroceryProductCard extends StatefulWidget {
  final String image;
  final List<String> images;
  final String title;
  final double rating;
  final int totalReviews;
  final int views;
  final double price;
  final double originalPrice;
  final String slug;
  final int? variantId;
  final int? productId;
  final int cartQuantity;
  /// All variants for this product — used to show the variant picker bottom sheet
  final List<SharedVariantModel> variants;
  /// Initial wishlist state from API response (used before WishlistBloc syncs)
  final bool isWishlisted;
  /// Product-level total cart quantity (sum across all variants)
  final int productCartQuantity;
  final String deliveryTime;
  final String? recipeCount;
  final bool? isDeliverable;
  final List<dynamic>? siblingProducts;
  final int? siblingIndex;

  const GroceryProductCard({
    super.key,
    required this.image,
    this.images = const [],
    required this.title,
    required this.rating,
    required this.totalReviews,
    required this.views,
    required this.price,
    required this.originalPrice,
    required this.slug,
    this.variantId,
    this.productId,
    this.cartQuantity = 0,
    this.variants = const [],
    this.isWishlisted = false,
    this.productCartQuantity = 0,
    this.deliveryTime = '9 mins',
    this.recipeCount,
    this.isDeliverable,
    this.siblingProducts,
    this.siblingIndex,
  });

  @override
  State<GroceryProductCard> createState() => _GroceryProductCardState();
}

class _GroceryProductCardState extends State<GroceryProductCard> {
  bool _loading = false;
  bool _wishlistLoading = false;
  late bool _localIsWishlisted;
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _localIsWishlisted = widget.isWishlisted;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GroceryProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.productId != oldWidget.productId) {
      _wishlistLoading = false;
      _loading = false;
      _localIsWishlisted = widget.isWishlisted;
      _currentImageIndex = 0;
    }
  }

  String _variantLabel(SharedVariantModel v) {
    final qty = v.quantity != null
        ? (v.quantity! % 1 == 0 ? v.quantity!.toInt().toString() : v.quantity!.toString())
        : '';
    final subUom = v.subUomShortName ?? v.uomShortName ?? v.subUomName ?? '';
    return '$qty $subUom'.trim();
  }

  List<String> _getAllImages() {
    final list = <String>[];
    if (widget.images.isNotEmpty) {
      list.addAll(widget.images.where((s) => s.isNotEmpty));
    }
    if (list.isEmpty && widget.image.isNotEmpty) {
      list.add(widget.image);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final imageList = _getAllImages();
    final title = widget.title;
    final price = widget.price;
    final originalPrice = widget.originalPrice;
    final slug = widget.slug;
    final variantId = widget.variantId ?? (widget.variants.isNotEmpty ? widget.variants.first.id : null);
    final productId = widget.productId;
    final firstVariant = widget.variants.isNotEmpty ? widget.variants.first : null;
    final primaryVariantLabel = firstVariant != null ? _variantLabel(firstVariant) : '';
    final hasAnyDeliverable = (widget.isDeliverable ?? true) &&
        (widget.variants.isNotEmpty
            ? widget.variants.any((v) => v.isDeliverable && (v.sellingPrice ?? 0) > 0)
            : (widget.price > 0 && widget.variantId != null));

    return GestureDetector(
      onTap: () {
        logger.i(
          '📦 GroceryProductCard: Product tapped → slug="$slug", title="$title", variantId=$variantId',
        );
        context.push(
          AppRoutePath.productDetails,
          extra: {
            'slug': slug,
            'variantId': variantId,
            'products': widget.siblingProducts,
            'initialIndex': widget.siblingIndex ?? 0,
          },
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── TOP SECTION: Image + Blueish Weight & Action Bar (Clean Rounded Card) ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.1.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Slider Section with Dots & Wishlist (White Background)
                    Container(
                      color: Colors.white,
                      child: AspectRatio(
                        aspectRatio: 1.08,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: imageList.isNotEmpty
                                  ? PageView.builder(
                                      controller: _pageController,
                                      itemCount: imageList.length,
                                      physics: const ClampingScrollPhysics(),
                                      onPageChanged: (idx) {
                                        setState(() => _currentImageIndex = idx);
                                      },
                                      itemBuilder: (context, index) {
                                        final currentImg = imageList[index];
                                        return (currentImg.startsWith('http'))
                                            ? Image.network(
                                                currentImg,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.white,
                                                  child: Icon(
                                                    Icons.eco_rounded,
                                                    color: Colors.green.shade300,
                                                    size: 32.w,
                                                  ),
                                                ),
                                              )
                                            : Image.network(
                                                NetworkImages.mapAssetToNetwork(currentImg),
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.white,
                                                  child: Icon(
                                                    Icons.eco_rounded,
                                                    color: Colors.green.shade300,
                                                    size: 32.w,
                                                  ),
                                                ),
                                              );
                                      },
                                    )
                                  : Container(
                                      color: Colors.white,
                                      child: Icon(
                                        Icons.eco_rounded,
                                        color: Colors.green.shade300,
                                        size: 32.w,
                                      ),
                                    ),
                            ),

                            // Indicator Dots at Bottom Left
                            if (imageList.length > 1)
                              Positioned(
                                bottom: 6.h,
                                left: 8.w,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(imageList.length, (idx) {
                                    final isActive = idx == _currentImageIndex;
                                    return Container(
                                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                                      width: isActive ? 5.5.w : 4.w,
                                      height: isActive ? 5.5.w : 4.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1).withValues(alpha: 0.8),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                            // Wishlist Icon at Top Right
                            Positioned(
                              top: 6.h,
                              right: 6.w,
                              child: BlocConsumer<WishlistBloc, WishlistState>(
                                listenWhen: (previous, current) {
                                  return (current is WishlistActionSuccess && current.productId == productId) ||
                                      current is WishlistActionError;
                                },
                                listener: (context, state) {
                                  if (state is WishlistActionSuccess) {
                                    if (_wishlistLoading) {
                                      setState(() {
                                        _wishlistLoading = false;
                                        _localIsWishlisted = state.isSaved;
                                      });
                                    }
                                    if (state.isSaved) {
                                      SnackbarUtils.showSuccessSnackbar(
                                        context,
                                        state.message,
                                      );
                                    } else {
                                      SnackbarUtils.showErrorSnackbar(
                                        context,
                                        state.message,
                                      );
                                    }
                                  } else if (state is WishlistActionError) {
                                    if (_wishlistLoading) {
                                      setState(() {
                                        _wishlistLoading = false;
                                      });
                                    }
                                    SnackbarUtils.showErrorSnackbar(context, state.message);
                                  }
                                },
                                builder: (context, state) {
                                  bool isSaved = false;
                                  if (productId != null) {
                                    final blocIds = context.read<WishlistBloc>().wishlistedProductIds;
                                    isSaved = blocIds.isNotEmpty
                                        ? blocIds.contains(productId)
                                        : _localIsWishlisted;
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      if (productId != null && !_wishlistLoading) {
                                        setState(() {
                                          _wishlistLoading = true;
                                        });
                                        context.read<WishlistBloc>().add(
                                          ToggleWishlistEvent(productId),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: _wishlistLoading
                                          ? SizedBox(
                                              width: 14.w,
                                              height: 14.w,
                                              child: const CircularProgressIndicator(
                                                color: Colors.red,
                                                strokeWidth: 1.5,
                                              ),
                                            )
                                          : Icon(
                                              isSaved ? Icons.favorite : Icons.favorite_border,
                                              size: 15.w,
                                              color: isSaved ? Colors.red : Colors.black87,
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Integrated Blueish Weight & Action Bar Container
                    Container(
                      height: 40.h,
                      color: const Color(0xFFF0F5FA),
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      child: BlocConsumer<CartBloc, CartState>(
                        listener: (context, state) {
                          if (state is CartActionSuccess || state is CartError || state is CartLoaded) {
                            if (_loading) {
                              setState(() => _loading = false);
                            }
                          }
                        },
                        builder: (context, state) {
                          CartData? cartData;
                          if (state is CartLoaded) {
                            cartData = state.cartData;
                          } else if (state is CartLoading) {
                            cartData = state.cartData;
                          } else if (state is CartActionSuccess) {
                            cartData = state.cartData;
                          } else if (state is CartError) {
                            cartData = state.cartData;
                          }

                          CartItem? cartItem;
                          if (cartData?.items != null && variantId != null) {
                            for (final item in cartData!.items!) {
                              if (item.productVariantId == variantId) {
                                cartItem = item;
                                break;
                              }
                            }
                          }

                          final bool isCartStateAvailable = (state is CartLoaded ||
                                  state is CartActionSuccess ||
                                  state is CartLoading ||
                                  state is CartError) &&
                              cartData != null;

                          int effectiveQuantity = 0;
                          if (cartItem != null) {
                            effectiveQuantity = cartItem.quantity;
                          } else {
                            effectiveQuantity = !isCartStateAvailable ? widget.cartQuantity : 0;
                          }

                          final isMultiVariant = widget.variants.length > 1;
                          int multiQty = 0;
                          if (isMultiVariant) {
                            if (isCartStateAvailable && cartData.items != null) {
                              final variantIds = widget.variants.map((v) => v.id).toSet();
                              for (final item in cartData.items!) {
                                if (variantIds.contains(item.productVariantId)) {
                                  multiQty += item.quantity;
                                }
                              }
                            } else {
                              multiQty = widget.productCartQuantity;
                            }
                          }

                          final displayQty = isMultiVariant ? multiQty : effectiveQuantity;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Variant text (e.g. 200 g)
                              Expanded(
                                child: Text(
                                  primaryVariantLabel.isNotEmpty ? primaryVariantLabel : '1 unit',
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E242B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              // Right: Action button
                              _buildActionButton(
                                context: context,
                                variantId: variantId,
                                firstVariant: firstVariant,
                                isMultiVariant: isMultiVariant,
                                displayQty: displayQty,
                                cartItem: cartItem,
                                hasAnyDeliverable: hasAnyDeliverable,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Product Details Section (Plain background) ──
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pricing Row (₹48 ₹58)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${price.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5.sp,
                          color: const Color(0xFF1E242B),
                        ),
                      ),
                      if (originalPrice > price) ...[
                        SizedBox(width: 4.w),
                        Text(
                          '₹${originalPrice.toInt()}',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // Product Title
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: const Color(0xFF1E242B),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Recipe Badge (e.g. 29 recipes ▶)
                  if (widget.recipeCount != null && widget.recipeCount!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EE),
                        borderRadius: BorderRadius.circular(6.w),
                        border: Border.all(color: const Color(0xFFC8E6C9), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.recipeCount!,
                            style: TextStyle(
                              color: const Color(0xFF2E7D32),
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 10.sp,
                            color: const Color(0xFF2E7D32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required int? variantId,
    required SharedVariantModel? firstVariant,
    required bool isMultiVariant,
    required int displayQty,
    required CartItem? cartItem,
    required bool hasAnyDeliverable,
  }) {
    if (!hasAnyDeliverable) {
      return Container(
        width: 76.w,
        height: 36.h,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEF0),
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(color: const Color(0xFFFFD2D7)),
        ),
        child: Text(
          'Not deliverable',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFC62828),
            fontSize: 8.sp,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      );
    }

    // In Cart: Glossy green stepper button
    if (displayQty > 0) {
      return Container(
        width: 76.w,
        height: 36.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(10.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isMultiVariant
            ? GestureDetector(
                onTap: () {
                  final loc = locationService.locationNotifier.value;
                  _showVariantBottomSheet(context, loc?.lat ?? 0.0, loc?.lng ?? 0.0);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.remove, color: Colors.white, size: 16),
                      Text(
                        '$displayQty',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.sp,
                        ),
                      ),
                      const Icon(Icons.add, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              )
            : (_loading
                ? Center(
                    child: SizedBox(
                      width: 13.w,
                      height: 13.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          final loc = locationService.locationNotifier.value;
                          setState(() => _loading = true);
                          if (cartItem != null) {
                            if (cartItem.quantity > 1) {
                              context.read<CartBloc>().add(
                                UpdateCartEvent(
                                  cartItemId: cartItem.id,
                                  quantity: cartItem.quantity - 1,
                                  lat: loc?.lat ?? 0.0,
                                  lng: loc?.lng ?? 0.0,
                                ),
                              );
                            } else {
                              context.read<CartBloc>().add(
                                RemoveCartItemEvent(cartItem.id),
                              );
                            }
                          } else if (displayQty > 1 && variantId != null) {
                            context.read<CartBloc>().add(
                              AddToCartEvent(
                                productVariantId: variantId,
                                quantity: displayQty - 1,
                                lat: loc?.lat ?? 0.0,
                                lng: loc?.lng ?? 0.0,
                              ),
                            );
                          } else if (displayQty == 1 && variantId != null) {
                            context.read<CartBloc>().add(
                              AddToCartEvent(
                                productVariantId: variantId,
                                quantity: 0,
                                lat: loc?.lat ?? 0.0,
                                lng: loc?.lng ?? 0.0,
                              ),
                            );
                          } else {
                            setState(() => _loading = false);
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                          child: const Icon(Icons.remove, color: Colors.white, size: 16),
                        ),
                      ),
                      Text(
                        '$displayQty',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.sp,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          final loc = locationService.locationNotifier.value;
                          setState(() => _loading = true);
                          if (cartItem != null) {
                            context.read<CartBloc>().add(
                              UpdateCartEvent(
                                cartItemId: cartItem.id,
                                quantity: cartItem.quantity + 1,
                                lat: loc?.lat ?? 0.0,
                                lng: loc?.lng ?? 0.0,
                              ),
                            );
                          } else if (variantId != null) {
                            context.read<CartBloc>().add(
                              AddToCartEvent(
                                productVariantId: variantId,
                                quantity: displayQty + 1,
                                lat: loc?.lat ?? 0.0,
                                lng: loc?.lng ?? 0.0,
                              ),
                            );
                          } else {
                            setState(() => _loading = false);
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  )),
      );
    }

    // Not In Cart: Multi-variant ADD button with options text
    if (isMultiVariant) {
      return GestureDetector(
        onTap: () {
          final loc = locationService.locationNotifier.value;
          _showVariantBottomSheet(context, loc?.lat ?? 0.0, loc?.lng ?? 0.0);
        },
        child: Container(
          width: 76.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.w),
            border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9.w),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'ADD',
                      style: TextStyle(
                        color: const Color(0xFF2E7D32),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  color: const Color(0xFFE8F5E9),
                  child: Center(
                    child: Text(
                      '${widget.variants.length} options',
                      style: TextStyle(
                        color: const Color(0xFF2E7D32),
                        fontSize: 7.5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Single-variant ADD button
    return GestureDetector(
      onTap: _loading
          ? null
          : () {
              if (variantId == null) return;
              final loc = locationService.locationNotifier.value;
              final lat = loc?.lat ?? 0.0;
              final lng = loc?.lng ?? 0.0;
              setState(() => _loading = true);
              CartValidationHelper.checkAndShowConflictDialog(
                context,
                isAddingFood: false,
                onClearAndAdd: () {
                  context.read<CartBloc>().add(
                    AddToCartEvent(
                      productVariantId: variantId,
                      quantity: 1,
                      lat: lat,
                      lng: lng,
                    ),
                  );
                },
              ).then((success) {
                if (!success && mounted) {
                  setState(() => _loading = false);
                }
              });
            },
      child: Container(
        width: 76.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? SizedBox(
                  width: 13.w,
                  height: 13.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                )
              : Text(
                  'ADD',
                  style: TextStyle(
                    color: const Color(0xFF2E7D32),
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Variant Picker Bottom Sheet ───────────────────────────────────────────────
  void _showVariantBottomSheet(BuildContext context, double lat, double lng) {
    final cartBloc = context.read<CartBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cartBloc,
        child: _VariantBottomSheet(
          productName: widget.title,
          productImage: widget.image,
          variants: widget.variants,
          lat: lat,
          lng: lng,
        ),
      ),
    );
  }
}

// ── Variant Bottom Sheet Widget ───────────────────────────────────────────────
class _VariantBottomSheet extends StatefulWidget {
  final String productName;
  final String productImage;
  final List<SharedVariantModel> variants;
  final double lat;
  final double lng;

  const _VariantBottomSheet({
    required this.productName,
    required this.productImage,
    required this.variants,
    required this.lat,
    required this.lng,
  });

  @override
  State<_VariantBottomSheet> createState() => _VariantBottomSheetState();
}

class _VariantBottomSheetState extends State<_VariantBottomSheet> {
  final Map<int, bool> _loadingMap = {};

  String _variantLabel(SharedVariantModel v) {
    final qty = v.quantity != null
        ? (v.quantity! % 1 == 0 ? v.quantity!.toInt().toString() : v.quantity!.toString())
        : '';
    final subUom = v.subUomShortName ?? v.uomShortName ?? v.subUomName ?? '';
    return '$qty $subUom'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.80;

    return BlocConsumer<CartBloc, CartState>(
      listener: (context, cartState) {
        if (cartState is CartActionSuccess ||
            cartState is CartLoaded ||
            cartState is CartError) {
          if (_loadingMap.values.any((v) => v)) {
            setState(() => _loadingMap.updateAll((_, __) => false));
          }
        }
      },
      builder: (context, cartState) {
        CartData? cartData;
        if (cartState is CartLoaded) {
          cartData = cartState.cartData;
        } else if (cartState is CartActionSuccess) {
          cartData = cartState.cartData;
        } else if (cartState is CartLoading) {
          cartData = cartState.cartData;
        } else if (cartState is CartError) {
          cartData = cartState.cartData;
        }

        final hasCartItems = cartData != null &&
            ((cartData.items != null && cartData.items!.isNotEmpty) ||
                (cartData.totalItems ?? 0) > 0);

        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating Dark Circular Close Button on Top
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF484850),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20.w,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Sheet Container
              Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title Header
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
                      child: Text(
                        widget.productName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    // Variant List
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                        itemCount: widget.variants.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final variant = widget.variants[index];
                          return _buildVariantCard(context, variant, cartData);
                        },
                      ),
                    ),

                    // Floating View Cart Bar if items exist in cart
                    if (hasCartItems)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                        child: FloatingViewCartBar(
                          margin: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            context.push(AppRoutePath.cart, extra: false);
                          },
                        ),
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

  Widget _buildVariantCard(
    BuildContext context,
    SharedVariantModel variant,
    CartData? cartData,
  ) {
    final vid = variant.id;
    final vLabel = _variantLabel(variant);
    final sellingPrice = variant.sellingPrice ?? 0.0;
    final actualPrice = variant.actualPrice ?? 0.0;
    final discountPct = (actualPrice > sellingPrice && actualPrice > 0)
        ? ((actualPrice - sellingPrice) / actualPrice * 100).round()
        : 0;

    // Find cart quantity for this variant
    CartItem? cartItem;
    if (cartData?.items != null && vid != null) {
      for (final item in cartData!.items!) {
        if (item.productVariantId == vid) {
          cartItem = item;
          break;
        }
      }
    }
    final int qty = cartItem != null ? cartItem.quantity : 0;
    final bool inCart = qty > 0;
    final bool isLoading = vid != null && _loadingMap[vid] == true;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Product image thumbnail with blue discount badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.w),
                  color: const Color(0xFFF8FAF9),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.w),
                  child: Image.network(
                    widget.productImage.startsWith('http')
                        ? widget.productImage
                        : NetworkImages.mapAssetToNetwork(widget.productImage),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F8E9),
                      child: Icon(
                        Icons.eco_rounded,
                        color: Colors.green.shade300,
                        size: 28.w,
                      ),
                    ),
                  ),
                ),
              ),
              if (discountPct > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.w),
                        bottomRight: Radius.circular(8.w),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$discountPct%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 14.w),

          // Middle: Variant Name / Weight (e.g. 2 x 200 g or 200 g)
          Expanded(
            child: Text(
              vLabel.isNotEmpty ? vLabel : '1 unit',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),

          // Pricing (₹67 ₹85)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${sellingPrice.toInt()}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (actualPrice > sellingPrice) ...[
                SizedBox(width: 4.w),
                Text(
                  '₹${actualPrice.toInt()}',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(width: 12.w),

          // Right: ADD / Stepper Button
          if (!variant.isDeliverable)
            Container(
              width: 76.w,
              height: 32.h,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF0),
                borderRadius: BorderRadius.circular(8.w),
                border: Border.all(color: const Color(0xFFFFD2D7)),
              ),
              child: Text(
                'Not deliverable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFC62828),
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (inCart)
            Container(
              width: 76.w,
              height: 32.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 13.w,
                        height: 13.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (vid == null) return;
                              setState(() => _loadingMap[vid] = true);
                              if (cartItem != null) {
                                if (cartItem.quantity > 1) {
                                  context.read<CartBloc>().add(
                                    UpdateCartEvent(
                                      cartItemId: cartItem.id,
                                      quantity: cartItem.quantity - 1,
                                      lat: widget.lat,
                                      lng: widget.lng,
                                    ),
                                  );
                                } else {
                                  context.read<CartBloc>().add(
                                    RemoveCartItemEvent(cartItem.id),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                              child: const Icon(Icons.remove, color: Colors.white, size: 16),
                            ),
                          ),
                          Text(
                            '$qty',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.sp,
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (vid == null) return;
                              setState(() => _loadingMap[vid] = true);
                              if (cartItem != null) {
                                context.read<CartBloc>().add(
                                  UpdateCartEvent(
                                    cartItemId: cartItem.id,
                                    quantity: cartItem.quantity + 1,
                                    lat: widget.lat,
                                    lng: widget.lng,
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
              ),
            )
          else
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      if (vid == null) return;
                      setState(() => _loadingMap[vid] = true);
                      CartValidationHelper.checkAndShowConflictDialog(
                        context,
                        isAddingFood: false,
                        onClearAndAdd: () {
                          context.read<CartBloc>().add(
                            AddToCartEvent(
                              productVariantId: vid,
                              quantity: 1,
                              lat: widget.lat,
                              lng: widget.lng,
                            ),
                          );
                        },
                      ).then((success) {
                        if (!success && mounted) {
                          setState(() => _loadingMap[vid] = false);
                        }
                      });
                    },
              child: Container(
                width: 76.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.w),
                  border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 13.w,
                          height: 13.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                          ),
                        )
                      : Text(
                          'ADD',
                          style: TextStyle(
                            color: const Color(0xFF2E7D32),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
