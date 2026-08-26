import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/cart/bloc/cart_bloc.dart';
import '../features/cart/bloc/cart_state.dart';
import '../features/cart/data/models/cart_model.dart';
import '../routes/app_route_path.dart';
import '../core/utils/responsive_utils.dart';

class FloatingViewCartBar extends StatelessWidget {
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? maxWidth;

  const FloatingViewCartBar({
    super.key,
    this.onTap,
    this.margin,
    this.width,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
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

        if (cart == null) return const SizedBox.shrink();

        final hasItems = (cart.items != null && cart.items!.isNotEmpty) ||
            (cart.totalItems ?? 0) > 0;

        if (!hasItems) return const SizedBox.shrink();

        final int itemCount = cart.totalItems ??
            cart.items?.fold<int>(0, (sum, it) => sum + it.quantity) ??
            cart.items?.length ??
            0;

        // Extract up to 3 distinct product images from cart items
        final List<String> itemImages = (cart.items ?? [])
            .map((item) {
              if (item.product?.productImage != null &&
                  item.product!.productImage.isNotEmpty) {
                return item.product!.productImage;
              }
              if (item.product?.images != null &&
                  item.product!.images.isNotEmpty &&
                  item.product!.images.first.productImage.isNotEmpty) {
                return item.product!.images.first.productImage;
              }
              return '';
            })
            .where((img) => img.isNotEmpty)
            .toSet()
            .take(3)
            .toList();

        return Center(
          child: Padding(
            padding: margin ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
            child: GestureDetector(
              onTap: onTap ?? () => context.push(AppRoutePath.cart, extra: false),
              child: Container(
                width: width,
                constraints: BoxConstraints(maxWidth: maxWidth ?? 250.w),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4CAF50),
                      Color(0xFF388E3C),
                      Color(0xFF2E7D32),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Overlapping Images Stack
                    if (itemImages.isNotEmpty)
                      SizedBox(
                        width: 32.w + ((itemImages.length - 1) * 14.w),
                        height: 34.w,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            for (int i = 0; i < itemImages.length; i++)
                              Positioned(
                                left: i * 14.w,
                                child: Container(
                                  width: 32.w,
                                  height: 32.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.8),
                                    color: Colors.grey.shade100,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      itemImages[i],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFE8F5E9),
                                        child: Icon(
                                          Icons.shopping_basket_rounded,
                                          size: 16.w,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 18.w,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    SizedBox(width: 8.w),
                    // View Cart & Items Text
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            '$itemCount items',
                            style: TextStyle(
                              color: const Color(0xFFE8F5E9),
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Dark Green Circular Button with Chevron
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B5E20),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 20.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(
                  begin: 0.8,
                  end: 0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                ),
          ),
        );
      },
    );
  }
}
