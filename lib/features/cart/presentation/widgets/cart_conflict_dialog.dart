import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/food_cart_db.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../bloc/cart_bloc.dart';
import '../../bloc/cart_event.dart';
import '../../bloc/food_cart_bloc.dart';

enum ConflictType {
  foodVsGrocery,
  groceryVsFood,
  differentRestaurant,
}

class CartConflictDialog extends StatelessWidget {
  final ConflictType conflictType;
  final VoidCallback onClearAndAdd;

  const CartConflictDialog({
    super.key,
    required this.conflictType,
    required this.onClearAndAdd,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ConflictType conflictType,
    required VoidCallback onClearAndAdd,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => CartConflictDialog(
        conflictType: conflictType,
        onClearAndAdd: onClearAndAdd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFC8019); // Swiggy Orange
    
    String title = 'Items already in cart';
    String message = '';
    
    switch (conflictType) {
      case ConflictType.foodVsGrocery:
        message = 'Your cart contains grocery products. Please clear your cart first.';
        break;
      case ConflictType.groceryVsFood:
        message = 'Your cart contains restaurant products. Please clear your cart first.';
        break;
      case ConflictType.differentRestaurant:
        title = 'Replace cart item?';
        message = 'Your cart contains items from another restaurant. Do you want to discard them and add this item?';
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.w)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft orange circle with restaurant policy logo style icon
            Container(
              width: 64.w,
              height: 64.w,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF5ED),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  conflictType == ConflictType.differentRestaurant 
                      ? Icons.restaurant_outlined 
                      : Icons.restaurant_menu_outlined,
                  color: primaryColor,
                  size: 28.w,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            // Button 1: Clear Cart & Add Item
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                  onClearAndAdd();
                },
                icon: Icon(Icons.delete_outline, color: Colors.white, size: 18.w),
                label: Text(
                  conflictType == ConflictType.differentRestaurant 
                      ? 'Discard and add' 
                      : 'Clear cart & add item',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.w),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Button 2: Keep Existing Cart
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                icon: Icon(Icons.shopping_bag_outlined, color: const Color(0xFF475569), size: 18.w),
                label: Text(
                  'Keep existing cart',
                  style: TextStyle(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.w),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'MYVEGIZ RESTAURANT POLICY',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CartValidationHelper {
  static Future<bool> checkAndShowConflictDialog(
    BuildContext context, {
    required bool isAddingFood,
    int? newVendorId,
    required VoidCallback onClearAndAdd,
  }) async {
    if (isAddingFood) {
      // 1. Check for Grocery Conflict
      final hasGrocery = await _hasGroceryItems();
      if (hasGrocery) {
        if (context.mounted) {
          final result = await CartConflictDialog.show(
            context,
            conflictType: ConflictType.foodVsGrocery,
            onClearAndAdd: () async {
              logger.i("🛒 CartValidationHelper: Clearing Grocery cart to add Food item");
              await context.read<CartBloc>().clearCartUseCase.execute(isFood: false);
              if (context.mounted) {
                context.read<CartBloc>().add(ClearCartEvent());
              }
              onClearAndAdd();
            },
          );
          return result ?? false;
        }
        return false;
      }

      // 2. Check for Different Restaurant Conflict
      if (newVendorId != null) {
        final currentVendorId = await FoodCartDb.instance.getVendorId();
        if (currentVendorId != 0 && currentVendorId != newVendorId) {
          if (context.mounted) {
            final result = await CartConflictDialog.show(
              context,
              conflictType: ConflictType.differentRestaurant,
              onClearAndAdd: () async {
                logger.i("🛒 CartValidationHelper: Clearing Food cart to add item from different Restaurant");
                await FoodCartDb.instance.clearCart();
                await SecureStorage.saveCartData('', isFood: true);
                if (context.mounted) {
                  context.read<FoodCartBloc>().add(ClearCartEvent());
                }
                onClearAndAdd();
              },
            );
            return result ?? false;
          }
          return false;
        }
      }
    } else {
      // 3. Check for Food Conflict when adding Grocery
      final hasFood = await _hasFoodItems();
      if (hasFood) {
        if (context.mounted) {
          final result = await CartConflictDialog.show(
            context,
            conflictType: ConflictType.groceryVsFood,
            onClearAndAdd: () async {
              logger.i("🛒 CartValidationHelper: Clearing Food cart to add Grocery item");
              await FoodCartDb.instance.clearCart();
              await SecureStorage.saveCartData('', isFood: true);
              if (context.mounted) {
                context.read<FoodCartBloc>().add(ClearCartEvent());
              }
              onClearAndAdd();
            },
          );
          return result ?? false;
        }
        return false;
      }
    }
    // No conflict, run standard addition flow
    onClearAndAdd();
    return true;
  }

  static Future<bool> _hasGroceryItems() async {
    try {
      final data = await SecureStorage.getCartData(isFood: false);
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        final items = decoded['data']?['items'] as List?;
        return items != null && items.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> _hasFoodItems() async {
    try {
      final items = await FoodCartDb.instance.getCartItems();
      return items.isNotEmpty;
    } catch (_) {}
    return false;
  }
}
