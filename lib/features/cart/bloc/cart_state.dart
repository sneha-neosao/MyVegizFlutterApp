import 'package:my_vegiz_flutter/features/cart/data/models/cart_model.dart';
import 'package:my_vegiz_flutter/features/cart/data/models/coupon_model.dart';

abstract class CartState {}

class CartInitial extends CartState {}

class CartLoading extends CartState {
  final CartData? cartData;
  CartLoading({this.cartData});
}

class CartLoaded extends CartState {
  final CartData cartData;
  CartLoaded(this.cartData);
}

class CartActionSuccess extends CartState {
  final String message;
  final CartData? cartData;
  CartActionSuccess(this.message, {this.cartData});
}

class CartError extends CartState {
  final String message;
  final CartData? cartData;
  CartError(this.message, {this.cartData});
}

// --- Coupon States ---

class CouponsLoaded extends CartState {
  final List<CouponModel> coupons;
  CouponsLoaded(this.coupons);
}

class CouponActionSuccess extends CartState {
  final String message;
  final ApplyCouponData? data;
  CouponActionSuccess(this.message, {this.data});
}

class CouponValidationSuccess extends CartState {
  final ApplyCouponData data;
  CouponValidationSuccess(this.data);
}
