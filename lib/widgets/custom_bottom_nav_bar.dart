import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/cart/bloc/cart_bloc.dart';
import '../features/cart/bloc/food_cart_bloc.dart';
import '../features/cart/bloc/cart_state.dart';
import '../routes/app_route_path.dart';
import '../core/utils/responsive_utils.dart';
import '../features/cart/data/cart_data.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        context.go(AppRoutePath.home);
        break;
      case 1:
        context.go(AppRoutePath.search);
        break;
      case 2:
        // Intelligently decide which cart to show
        final foodCartState = context.read<FoodCartBloc>().state;
        bool showFoodCart = false;
        if (foodCartState is CartLoaded &&
            foodCartState.cartData.items != null &&
            foodCartState.cartData.items!.isNotEmpty) {
          showFoodCart = true;
        } else if (isFoodCart) {
          showFoodCart = true;
        }

        context.go(AppRoutePath.cart, extra: showFoodCart);
        break;
      case 3:
        context.go(AppRoutePath.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalHeight = 64.h + (bottomPadding > 0 ? bottomPadding : 12.h) + 6.h;

    return SizedBox(
      height: totalHeight,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: bottomPadding > 0 ? bottomPadding : 12.h,
          top: 6.h,
        ),
        child: Center(
          child: Container(
            height: 64.h,
            width: 340.w,
            padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFFC8019).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, index: 0, label: 'Home'),
                _buildNavItem(context, index: 1, label: 'Search'),
                _buildNavItem(context, index: 2, label: 'Cart'),
                _buildNavItem(context, index: 3, label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required int index, required String label}) {
    final bool isSelected = currentIndex == index;

    Widget iconWidget;
    if (index == 0) {
      iconWidget = isSelected
          ? Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFC8019),
                borderRadius: BorderRadius.circular(7.w),
              ),
              child: Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 16.w,
              ),
            )
          : Icon(
              Icons.home_outlined,
              color: Colors.grey.shade500,
              size: 24.w,
            );
    } else if (index == 1) {
      iconWidget = isSelected
          ? Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFC8019),
                borderRadius: BorderRadius.circular(7.w),
              ),
              child: Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 16.w,
              ),
            )
          : Icon(
              Icons.search_rounded,
              color: Colors.grey.shade500,
              size: 24.w,
            );
    } else if (index == 2) {
      iconWidget = _buildCartIcon(context, isSelected: isSelected);
    } else {
      iconWidget = isSelected
          ? Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFC8019),
                borderRadius: BorderRadius.circular(7.w),
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 15.w,
              ),
            )
          : Icon(
              Icons.person_outline_rounded,
              color: Colors.grey.shade500,
              size: 24.w,
            );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(context, index),
      child: isSelected
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE0),
                borderRadius: BorderRadius.circular(18.w),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  SizedBox(height: 2.h),
                  Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFFFC8019),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              child: Center(
                child: iconWidget,
              ),
            ),
    );
  }

  Widget _buildCartIcon(BuildContext context, {required bool isSelected}) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, groceryState) {
        return BlocBuilder<FoodCartBloc, CartState>(
          builder: (context, foodState) {
            int totalItems = 0;

            int getCount(CartState state) {
              if (state is CartLoaded) {
                return state.cartData.totalItems ?? 0;
              } else if (state is CartActionSuccess && state.cartData != null) {
                return state.cartData!.totalItems ?? 0;
              } else if (state is CartLoading && state.cartData != null) {
                return state.cartData!.totalItems ?? 0;
              }
              return 0;
            }

            final bool isSameBloc =
                context.read<CartBloc>() == context.read<FoodCartBloc>();

            if (isSameBloc) {
              totalItems = getCount(foodState);
            } else {
              totalItems = getCount(groceryState) + getCount(foodState);
            }

            final iconWidget = isSelected
                ? Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC8019),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 16.w,
                    ),
                  )
                : Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.grey.shade500,
                    size: 24.w,
                  );

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                iconWidget,
                if (totalItems > 0)
                  Positioned(
                    right: isSelected ? -4 : -6,
                    top: isSelected ? -4 : -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFC8019),
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w,
                        minHeight: 16.w,
                      ),
                      child: Text(
                        '$totalItems',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

