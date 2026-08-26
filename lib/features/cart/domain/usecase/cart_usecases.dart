import '../../data/models/cart_model.dart';
import '../../data/models/coupon_model.dart';
import '../../data/repository/cart_repo.dart';

class AddToCartUseCase {
  final CartRepository repository;

  AddToCartUseCase(this.repository);

  Future<CartResponse> execute({
    required int productVariantId,
    required int quantity,
    required double lat,
    required double lng,
    required bool isFood,
    List<int>? addonIds,
    List<Map<String, dynamic>>? addonData,
  }) async {
    return await repository.addToCart(
      productVariantId: productVariantId,
      quantity: quantity,
      lat: lat,
      lng: lng,
      isFood: isFood,
      addonIds: addonIds,
      addonData: addonData,
    );
  }
}

class GetCartListUseCase {
  final CartRepository repository;

  GetCartListUseCase(this.repository);

  Future<CartResponse> execute({
    required double lat,
    required double lng,
    required bool isFood,
  }) async {
    return await repository.getCartList(lat: lat, lng: lng, isFood: isFood);
  }
}

class UpdateCartUseCase {
  final CartRepository repository;

  UpdateCartUseCase(this.repository);

  Future<CartResponse> execute({
    required int cartItemId,
    required int quantity,
    required double lat,
    required double lng,
    required bool isFood,
  }) async {
    return await repository.updateCart(
      cartItemId: cartItemId,
      quantity: quantity,
      lat: lat,
      lng: lng,
      isFood: isFood,
    );
  }
}

class ClearCartUseCase {
  final CartRepository repository;

  ClearCartUseCase(this.repository);

  Future<CartResponse> execute({required bool isFood}) async {
    return await repository.clearCart(isFood: isFood);
  }
}

class ValidateAddressUseCase {
  final CartRepository repository;

  ValidateAddressUseCase(this.repository);

  Future<CartResponse> execute(String addressUuid) async {
    return await repository.validateAddress(addressUuid);
  }
}

class RemoveCartItemUseCase {
  final CartRepository repository;

  RemoveCartItemUseCase(this.repository);

  Future<CartResponse> execute(int cartItemId, {required bool isFood}) async {
    return await repository.removeCartItem(cartItemId, isFood: isFood);
  }
}

// --- Coupon Use Cases ---

class GetAvailableCouponsUseCase {
  final CartRepository repository;

  GetAvailableCouponsUseCase(this.repository);

  Future<CouponListResponse> execute({bool isFood = false}) async {
    return await repository.getAvailableCoupons(isFood: isFood);
  }
}

class ApplyCouponUseCase {
  final CartRepository repository;

  ApplyCouponUseCase(this.repository);

  Future<ApplyCouponResponse> execute(String couponCode, {bool isFood = false}) async {
    return await repository.applyCoupon(couponCode, isFood: isFood);
  }
}

class RemoveCouponUseCase {
  final CartRepository repository;

  RemoveCouponUseCase(this.repository);

  Future<ApplyCouponResponse> execute({bool isFood = false}) async {
    return await repository.removeCoupon(isFood: isFood);
  }
}

class ValidateCouponUseCase {
  final CartRepository repository;

  ValidateCouponUseCase(this.repository);

  Future<ValidateCouponResponse> execute(String code, {bool isFood = false}) async {
    return await repository.validateCoupon(code, isFood: isFood);
  }
}
