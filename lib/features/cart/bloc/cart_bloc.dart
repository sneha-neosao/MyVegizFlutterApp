import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/data/models/cart_model.dart';
import '../../../core/utils/logger.dart';
import '../domain/usecase/cart_usecases.dart';
import './cart_event.dart';
import './cart_state.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/location_service.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final bool isFood;
  final AddToCartUseCase addToCartUseCase;
  final GetCartListUseCase getCartListUseCase;
  final UpdateCartUseCase updateCartUseCase;
  final ClearCartUseCase clearCartUseCase;
  final ValidateAddressUseCase validateAddressUseCase;
  final RemoveCartItemUseCase removeCartItemUseCase;
  
  // Coupon Use Cases
  final GetAvailableCouponsUseCase getAvailableCouponsUseCase;
  final ApplyCouponUseCase applyCouponUseCase;
  final RemoveCouponUseCase removeCouponUseCase;
  final ValidateCouponUseCase validateCouponUseCase;
  
  CartData? _cachedCart;

  CartBloc({
    this.isFood = false,
    required this.addToCartUseCase,
    required this.getCartListUseCase,
    required this.updateCartUseCase,
    required this.clearCartUseCase,
    required this.validateAddressUseCase,
    required this.removeCartItemUseCase,
    required this.getAvailableCouponsUseCase,
    required this.applyCouponUseCase,
    required this.removeCouponUseCase,
    required this.validateCouponUseCase,
  }) : super(CartInitial()) {
    on<AddToCartEvent>(_onAddToCart);
    on<GetCartListEvent>(_onGetCartList);
    on<UpdateCartEvent>(_onUpdateCart);
    on<ClearCartEvent>(_onClearCart);
    on<ValidateAddressEvent>(_onValidateAddress);
    on<RemoveCartItemEvent>(_onRemoveCartItem);
    on<LoadCartFromLocal>(_onLoadLocalCart);
    on<FetchAvailableCouponsEvent>(_onFetchAvailableCoupons);
    on<ApplyCouponEvent>(_onApplyCoupon);
    on<RemoveCouponEvent>(_onRemoveCoupon);
    on<ValidateCouponEvent>(_onValidateCoupon);

    logger.i('🛒 CartBloc: Initialised — loading cart from local storage');
    add(LoadCartFromLocal());
  }

  // ── Load from local ─────────────────────────────────────────────────────

  Future<void> _onLoadLocalCart(
    LoadCartFromLocal event,
    Emitter<CartState> emit,
  ) async {
    logger.i('📂 CartBloc: Loading local cart data from SecureStorage');
    final localData = await SecureStorage.getCartData(isFood: isFood);
    if (localData != null && localData.isNotEmpty) {
      try {
        final cartResponse = CartResponse.fromJson(jsonDecode(localData));
        if (cartResponse.data != null) {
          final itemCount = cartResponse.data!.items?.length ?? 0;
          logger.i(
            '📂 CartBloc: Local cart loaded — $itemCount item(s), grandTotal=₹${cartResponse.data!.grandTotal}',
          );
          _cachedCart = cartResponse.data!;
          emit(CartLoaded(cartResponse.data!));
        } else {
          logger.d('📂 CartBloc: Local cart data has no data field — staying in CartInitial');
        }
      } catch (e) {
        logger.e('📂 CartBloc: Failed to parse local cart — $e');
      }
    } else {
      logger.d('📂 CartBloc: No local cart data found');
    }
  }

  CartData? _mergeCartData(CartData? current, CartData? incoming, {int? removedVariantId}) {
    if (incoming == null) return current;
    if (current == null) return incoming;

    // Start with a copy of current items
    final List<CartItem> updatedItems = List<CartItem>.from(current.items ?? []);

    // Get the incoming items (either from `items` list or the singular `item`)
    final List<CartItem> incomingItems = incoming.items ?? 
        (incoming.item != null ? [incoming.item!] : []);

    for (final incItem in incomingItems) {
      final index = updatedItems.indexWhere((item) => item.productVariantId == incItem.productVariantId);
      if (index >= 0) {
        if (incItem.quantity > 0) {
          updatedItems[index] = incItem;
        } else {
          updatedItems.removeAt(index);
        }
      } else if (incItem.quantity > 0) {
        updatedItems.add(incItem);
      }
    }

    if (removedVariantId != null) {
      updatedItems.removeWhere((item) => item.productVariantId == removedVariantId);
    }

    return CartData(
      cartId: incoming.cartId ?? current.cartId,
      productVariantId: incoming.productVariantId ?? current.productVariantId,
      cartItemId: incoming.cartItemId ?? current.cartItemId,
      quantity: incoming.quantity ?? current.quantity,
      price: incoming.price ?? current.price,
      totalPrice: incoming.totalPrice ?? current.totalPrice,
      totalAmount: incoming.totalAmount ?? current.totalAmount,
      productsTotal: incoming.productsTotal ?? current.productsTotal,
      grandTotal: incoming.grandTotal ?? current.grandTotal,
      totalItems: incoming.totalItems ?? current.totalItems,
      deliveryInfo: incoming.deliveryInfo ?? current.deliveryInfo,
      item: incoming.item ?? current.item,
      items: updatedItems,
      couponCode: incoming.couponCode ?? current.couponCode,
      couponType: incoming.couponType ?? current.couponType,
      discountAmount: incoming.discountAmount ?? current.discountAmount,
      discountedTotal: incoming.discountedTotal ?? current.discountedTotal,
      walletPointsUsed: incoming.walletPointsUsed ?? current.walletPointsUsed,
      walletDiscountAmount: incoming.walletDiscountAmount ?? current.walletDiscountAmount,
      appliedWalletPoints: incoming.appliedWalletPoints ?? current.appliedWalletPoints,
      mrpTotal: incoming.mrpTotal ?? current.mrpTotal,
      productDiscount: incoming.productDiscount ?? current.productDiscount,
      taxAmount: incoming.taxAmount ?? current.taxAmount,
      packingCharge: incoming.packingCharge ?? current.packingCharge,
    );
  }

  // ── Add to Cart ─────────────────────────────────────────────────────────

  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i(
      '🛒 CartBloc: AddToCart — variantId=${event.productVariantId}, qty=${event.quantity}, lat=${event.lat}, lng=${event.lng}',
    );
    emit(CartLoading(cartData: _cachedCart));
    try {
      final response = await addToCartUseCase.execute(
        productVariantId: event.productVariantId,
        quantity: event.quantity,
        lat: event.lat,
        lng: event.lng,
        isFood: isFood,
        addonIds: event.addonIds,
        addonData: event.addonData,
      );
      logger.d(
        '🛒 CartBloc: AddToCart response — status=${response.status}, msg="${response.message}"',
      );
      if (response.status == 200) {
        logger.i('✅ CartBloc: Item added to cart successfully');
        _cachedCart = _mergeCartData(_cachedCart, response.data);
        emit(CartActionSuccess(response.message, cartData: _cachedCart));
        add(GetCartListEvent(lat: event.lat, lng: event.lng));
      } else {
        logger.w('⚠️ CartBloc: AddToCart failed — ${response.message}');
        emit(CartError(response.message));
      }
    } catch (e) {
      logger.e('❌ CartBloc: AddToCart exception — $e');
      emit(CartError(e.toString()));
    }
  }

  // ── Get Cart List ───────────────────────────────────────────────────────

  Future<void> _onGetCartList(
    GetCartListEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i(
      '🛒 CartBloc: GetCartList — lat=${event.lat}, lng=${event.lng}',
    );

    // Fallback to local storage while fetching
    if (state is CartInitial) {
      final localData = await SecureStorage.getCartData(isFood: isFood);
      if (localData != null && localData.isNotEmpty) {
        try {
          final cartResponse = CartResponse.fromJson(jsonDecode(localData));
          if (cartResponse.data != null) {
            logger.d('📂 CartBloc: Showing cached cart while fetching fresh data');
            _cachedCart = cartResponse.data!;
            emit(CartLoaded(cartResponse.data!));
          }
        } catch (e) {
          logger.w('📂 CartBloc: Could not parse cached cart — $e');
        }
      }
    }

    emit(CartLoading(cartData: _cachedCart));
    try {
      final response = await getCartListUseCase.execute(
        lat: event.lat,
        lng: event.lng,
        isFood: isFood,
      );
      logger.d(
        '🛒 CartBloc: GetCartList response — status=${response.status}, msg="${response.message}"',
      );
      if (response.status == 200 && response.data != null) {
        final itemCount = response.data!.items?.length ?? 0;
        logger.i(
          '✅ CartBloc: Cart list loaded — $itemCount item(s), grandTotal=₹${response.data!.grandTotal}',
        );
        _cachedCart = response.data!;
        emit(CartLoaded(response.data!));
      } else {
        logger.w('⚠️ CartBloc: GetCartList failed — ${response.message}');
        emit(CartError(response.message, cartData: _cachedCart));
      }
    } catch (e) {
      logger.e('❌ CartBloc: GetCartList exception — $e');
      emit(CartError(e.toString(), cartData: _cachedCart));
    }
  }

  // ── Update Cart ─────────────────────────────────────────────────────────

  Future<void> _onUpdateCart(
    UpdateCartEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i(
      '🔄 CartBloc: UpdateCart — cartItemId=${event.cartItemId}, qty=${event.quantity}, lat=${event.lat}, lng=${event.lng}',
    );
    try {
      final response = await updateCartUseCase.execute(
        cartItemId: event.cartItemId,
        quantity: event.quantity,
        lat: event.lat,
        lng: event.lng,
        isFood: isFood,
      );
      logger.d(
        '🔄 CartBloc: UpdateCart response — status=${response.status}, msg="${response.message}"',
      );
      if (response.status == 200 && response.data != null) {
        logger.i('✅ CartBloc: Cart item updated successfully');
        _cachedCart = _mergeCartData(_cachedCart, response.data);
        emit(CartActionSuccess(response.message, cartData: _cachedCart));
        add(GetCartListEvent(lat: event.lat, lng: event.lng));
      } else {
        logger.w('⚠️ CartBloc: UpdateCart failed — ${response.message}');
        emit(CartError(response.message, cartData: _cachedCart));
      }
    } catch (e) {
      logger.e('❌ CartBloc: UpdateCart exception — $e');
      emit(CartError(e.toString(), cartData: _cachedCart));
    }
  }

  // ── Clear Cart ──────────────────────────────────────────────────────────

  Future<void> _onClearCart(
    ClearCartEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i('🗑️ CartBloc: ClearCart triggered (silent=${event.isSilent})');
    if (!event.isSilent) {
      emit(CartLoading(cartData: _cachedCart));
    }
    try {
      final response = await clearCartUseCase.execute(isFood: isFood);
      logger.d(
        '🗑️ CartBloc: ClearCart response — status=${response.status}, msg="${response.message}"',
      );
      if (response.status == 200) {
        logger.i('✅ CartBloc: Cart cleared successfully');
        _cachedCart = response.data;
        if (event.isSilent) {
          emit(CartLoaded(response.data ?? CartData(items: [])));
        } else {
          emit(CartActionSuccess(response.message, cartData: response.data));
        }
      } else {
        logger.w('⚠️ CartBloc: ClearCart failed — ${response.message}');
        if (!event.isSilent) {
          emit(CartError(response.message, cartData: _cachedCart));
        }
      }
    } catch (e) {
      logger.e('❌ CartBloc: ClearCart exception — $e');
      if (!event.isSilent) {
        emit(CartError(e.toString(), cartData: _cachedCart));
      }
    }
  }

  // ── Validate Address ────────────────────────────────────────────────────

  Future<void> _onValidateAddress(
    ValidateAddressEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i(
      '📍 CartBloc: ValidateAddress — addressUuid="${event.addressUuid}"',
    );
    emit(CartLoading(cartData: _cachedCart));
    try {
      final response = await validateAddressUseCase.execute(event.addressUuid);
      logger.d(
        '📍 CartBloc: ValidateAddress response — status=${response.status}, msg="${response.message}"',
      );
      if (response.status == 200) {
        logger.i('✅ CartBloc: Address validated successfully');
        _cachedCart = response.data;
        emit(CartActionSuccess(response.message, cartData: response.data));
      } else {
        logger.w('⚠️ CartBloc: ValidateAddress failed — ${response.message}');
        emit(CartError(response.message, cartData: _cachedCart));
      }
    } catch (e) {
      logger.e('❌ CartBloc: ValidateAddress exception — $e');
      emit(CartError(e.toString(), cartData: _cachedCart));
    }
  }

  // ── Remove Cart Item ────────────────────────────────────────────────────

  Future<void> _onRemoveCartItem(
    RemoveCartItemEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i('🗑️ CartBloc: RemoveCartItem — cartItemId=${event.cartItemId}');
    try {
      int? removedVariantId;
      if (_cachedCart != null && _cachedCart!.items != null) {
        final match = _cachedCart!.items!.firstWhere(
          (item) => item.id == event.cartItemId,
          orElse: () => CartItem(
            id: 0,
            productVariantId: 0,
            quantity: 0,
            price: 0,
            totalPrice: 0,
            variantUuId: '',
            sellingPrice: 0,
            actualPrice: 0,
            subUomName: '',
            subUomShortName: '',
            conversionFactor: 0,
            uomName: '',
            uomShortName: '',
          ),
        );
        if (match.productVariantId > 0) {
          removedVariantId = match.productVariantId;
        }
      }

      final response = await removeCartItemUseCase.execute(event.cartItemId, isFood: isFood);
      logger.d(
        '🗑️ CartBloc: RemoveCartItem response — status=${response.status}, msg="${response.message}"',
      );
      if (response.status == 200) {
        logger.i('✅ CartBloc: Cart item removed successfully');
        _cachedCart = _mergeCartData(_cachedCart, response.data, removedVariantId: removedVariantId);
        emit(CartActionSuccess(response.message, cartData: _cachedCart));
        final loc = locationService.locationNotifier.value;
        add(GetCartListEvent(lat: loc?.lat ?? 0.0, lng: loc?.lng ?? 0.0));
      } else {
        logger.w('⚠️ CartBloc: RemoveCartItem failed — ${response.message}');
        emit(CartError(response.message, cartData: _cachedCart));
      }
    } catch (e) {
      logger.e('❌ CartBloc: RemoveCartItem exception — $e');
      emit(CartError(e.toString(), cartData: _cachedCart));
    }
  }

  // ── Coupon Methods ────────────────────────────────────────────────────────

  Future<void> _onFetchAvailableCoupons(
    FetchAvailableCouponsEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.d('===== FOOD ORDER BLOC ===== FetchAvailableCouponsEvent triggered (isFood: $isFood)');
    emit(CartLoading(cartData: _cachedCart));
    try {
      final response = await getAvailableCouponsUseCase.execute(isFood: isFood);
      if (response.status == 200 && response.data != null) {
        logger.d('===== FOOD ORDER BLOC ===== CouponsLoaded state emitted: count=${response.data!.length}');
        emit(CouponsLoaded(response.data!));
      } else {
        logger.e('===== FOOD ORDER BLOC ===== Coupons fetch error: ${response.message}');
        emit(CartError(response.message, cartData: _cachedCart));
      }
    } catch (e) {
      logger.e('===== FOOD ORDER BLOC ===== Coupons fetch exception: $e');
      emit(CartError(e.toString(), cartData: _cachedCart));
    }
  }

  Future<void> _onApplyCoupon(
    ApplyCouponEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i('🏷️ CartBloc: ApplyCoupon — couponCode=${event.couponCode}');
    emit(CartLoading(cartData: _cachedCart));
    try {
      final response = await applyCouponUseCase.execute(event.couponCode, isFood: isFood);
      if (response.status == 200) {
        logger.i('✅ CartBloc: Coupon applied successfully');
        emit(CouponActionSuccess(response.message, data: response.data));
      } else {
        logger.w('⚠️ CartBloc: ApplyCoupon failed — ${response.message}');
        emit(CartError(response.message, cartData: _cachedCart));
      }
    } catch (e) {
      logger.e('❌ CartBloc: ApplyCoupon exception — $e');
      emit(CartError(e.toString(), cartData: _cachedCart));
    }
  }

  Future<void> _onRemoveCoupon(
    RemoveCouponEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i('🗑️ CartBloc: RemoveCoupon');
    emit(CartLoading(cartData: _cachedCart));
    try {
      final response = await removeCouponUseCase.execute(isFood: isFood);
      if (response.status == 200) {
        logger.i('✅ CartBloc: Coupon removed successfully');
        emit(CouponActionSuccess(response.message, data: response.data));
      } else {
        logger.w('⚠️ CartBloc: RemoveCoupon failed — ${response.message}');
        emit(CartError(response.message, cartData: _cachedCart));
      }
    } catch (e) {
      logger.e('❌ CartBloc: RemoveCoupon exception — $e');
      emit(CartError(e.toString(), cartData: _cachedCart));
    }
  }

  Future<void> _onValidateCoupon(
    ValidateCouponEvent event,
    Emitter<CartState> emit,
  ) async {
    logger.i('🔍 CartBloc: ValidateCoupon — code=${event.couponCode}');
    emit(CartLoading(cartData: _cachedCart));
    try {
      final response = await validateCouponUseCase.execute(event.couponCode, isFood: isFood);
      if (response.status == 200 && response.data != null) {
        logger.i('✅ CartBloc: Coupon validated successfully');
        emit(CouponValidationSuccess(response.data!));
      } else {
        logger.w('⚠️ CartBloc: ValidateCoupon failed');
        emit(CartError("Failed to validate coupon", cartData: _cachedCart));
      }
    } catch (e) {
      logger.e('❌ CartBloc: ValidateCoupon exception — $e');
      emit(CartError(e.toString(), cartData: _cachedCart));
    }
  }
}
