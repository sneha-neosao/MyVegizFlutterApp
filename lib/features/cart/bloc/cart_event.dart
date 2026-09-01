abstract class CartEvent {}

class AddToCartEvent extends CartEvent {
  final int productVariantId;
  final int quantity;
  final double lat;
  final double lng;
  final List<int>? addonIds;
  final List<Map<String, dynamic>>? addonData;

  AddToCartEvent({
    required this.productVariantId,
    required this.quantity,
    required this.lat,
    required this.lng,
    this.addonIds,
    this.addonData,
  });
}

class GetCartListEvent extends CartEvent {
  final double lat;
  final double lng;

  GetCartListEvent({required this.lat, required this.lng});
}

class UpdateCartEvent extends CartEvent {
  final int cartItemId;
  final int quantity;
  final double lat;
  final double lng;

  UpdateCartEvent({
    required this.cartItemId,
    required this.quantity,
    required this.lat,
    required this.lng,
  });
}

class ClearCartEvent extends CartEvent {
  final bool isSilent;
  ClearCartEvent({this.isSilent = false});
}

class ClearCartAndAddToCartEvent extends CartEvent {
  final AddToCartEvent pendingEvent;
  ClearCartAndAddToCartEvent(this.pendingEvent);
}

class ValidateAddressEvent extends CartEvent {
  final String addressUuid;
  ValidateAddressEvent(this.addressUuid);
}

class RemoveCartItemEvent extends CartEvent {
  final int cartItemId;
  RemoveCartItemEvent(this.cartItemId);
}

class LoadCartFromLocal extends CartEvent {}

// --- Coupon Events ---

class FetchAvailableCouponsEvent extends CartEvent {}

class ApplyCouponEvent extends CartEvent {
  final String couponCode;
  ApplyCouponEvent(this.couponCode);
}

class RemoveCouponEvent extends CartEvent {}

class ValidateCouponEvent extends CartEvent {
  final String couponCode;
  ValidateCouponEvent(this.couponCode);
}
