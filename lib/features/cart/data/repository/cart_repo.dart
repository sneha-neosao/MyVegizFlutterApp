import 'dart:convert';
import '../models/cart_model.dart';
import '../models/coupon_model.dart';
import '../datasources/cart_datasource.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/food_cart_db.dart';
import '../../../../core/utils/logger.dart';
import '../cart_data.dart' hide CartItem;

abstract class CartRepository {
  Future<CartResponse> addToCart({
    required int productVariantId,
    required int quantity,
    required double lat,
    required double lng,
    required bool isFood,
    List<int>? addonIds,
    List<Map<String, dynamic>>? addonData,
  });

  Future<CartResponse> getCartList({
    required double lat,
    required double lng,
    required bool isFood,
  });

  Future<CartResponse> updateCart({
    required int cartItemId,
    required int quantity,
    required double lat,
    required double lng,
    required bool isFood,
  });

  Future<CartResponse> clearCart({required bool isFood});

  Future<CartResponse> validateAddress(String addressUuid);

  Future<CartResponse> removeCartItem(int cartItemId, {required bool isFood});

  // Coupon methods
  Future<CouponListResponse> getAvailableCoupons({bool isFood = false});
  Future<ApplyCouponResponse> applyCoupon(String couponCode, {bool isFood = false});
  Future<ApplyCouponResponse> removeCoupon({bool isFood = false});
  Future<ValidateCouponResponse> validateCoupon(String code, {bool isFood = false});
}

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remoteDataSource;

  CartRepositoryImpl(this._remoteDataSource);

  @override
  Future<CartResponse> addToCart({
    required int productVariantId,
    required int quantity,
    required double lat,
    required double lng,
    required bool isFood,
    List<int>? addonIds,
    List<Map<String, dynamic>>? addonData,
  }) async {
    toggleFoodCartMode(isFood);
    if (isFood) {
      logger.i('📦 CartRepository: addToCart (Food Mode) — item=$productVariantId, qty=$quantity');
      try {
        final apiResponse = await _remoteDataSource.fetchVendorItemDetails(
          productVariantId,
          lat: lat,
          lng: lng,
        );
        final data = apiResponse['data'] as Map<String, dynamic>?;
        if (data != null) {
          final int vendorId = (data['vendor']?['id'] as num?)?.toInt() ?? 30;
          final String name = data['item_name'] as String? ?? 'Dish';
          double price = (data['sale_price'] as num?)?.toDouble() ?? 0.0;

          // Add addon prices to the local base price for immediate UI feedback
          if (addonData != null) {
            for (var addon in addonData) {
              price += (addon['price'] as num?)?.toDouble() ?? 0.0;
            }
          }

          final String? image = (data['images'] as List?)?.isNotEmpty == true
              ? data['images']![0]['item_image'] as String?
              : null;
          final String? description = data['description'] as String?;
          final String? cuisineType = data['cuisine_type'] as String?;

          await FoodCartDb.instance.insertOrUpdateItem(
            vendorId: vendorId,
            vendorItemId: productVariantId,
            quantity: quantity,
            name: name,
            price: price,
            image: image,
            description: description,
            cuisineType: cuisineType,
            addonIds: addonIds != null ? jsonEncode(addonIds) : null,
            addonData: addonData != null ? jsonEncode(addonData) : null,
          );
        }
      } catch (e) {
        logger.e('❌ CartRepository: Failed to add food item to local db — $e');
      }
      return await getCartList(lat: lat, lng: lng, isFood: true);
    }

    logger.i(
      '📦 CartRepository: addToCart(variantId=$productVariantId, qty=$quantity)',
    );
    final response = await _remoteDataSource.addToCart(
      productVariantId: productVariantId,
      quantity: quantity,
      lat: lat,
      lng: lng,
      isFood: isFood,
      addonIds: addonIds,
      addonData: addonData,
    );
    final cartResponse = CartResponse.fromJson(response);
    if (cartResponse.status == 200 && cartResponse.data != null) {
      logger.i('💾 CartRepository: Caching addToCart response to SecureStorage');
      await SecureStorage.saveCartData(jsonEncode(cartResponse.toJson()), isFood: false);
    } else {
      logger.w(
        '⚠️ CartRepository: addToCart returned status=${cartResponse.status} — not caching',
      );
    }
    return cartResponse;
  }

  @override
  Future<CartResponse> getCartList({
    required double lat,
    required double lng,
    required bool isFood,
  }) async {
    if (isFood) {
      logger.i('📋 CartRepository: getCartList (Food Mode)');
      try {
        final localItems = await FoodCartDb.instance.getCartItems();
        if (localItems.isNotEmpty) {
          toggleFoodCartMode(true);
        }
        if (localItems.isEmpty) {
          logger.d('📋 CartRepository: Food cart is empty');
          final emptyResponse = CartResponse(
            status: 200,
            message: "Cart is empty",
            data: CartData(
              items: [],
              totalItems: 0,
              grandTotal: 0.0,
              productsTotal: 0.0,
            ),
          );
          await SecureStorage.saveCartData(jsonEncode(emptyResponse.toJson()), isFood: true);
          return emptyResponse;
        }

        final customerName = await SecureStorage.getCustomerName() ?? "Guest";
        final customerId = await SecureStorage.getCustomerId() ?? "1";
        final customerUuid = await SecureStorage.getCustomerUuid() ?? "16b33cd8-a38a-4462-a575-c8b1938ab438";
        final addressUuid = await SecureStorage.getSelectedAddressUuid();
        final vendorId = localItems.first['vendor_id'] as int;

        final payloadItems = localItems.map((item) {
          final Map<String, dynamic> itemMap = {
            "vendor_item_id": item['vendor_item_id'] as int,
            "quantity": item['quantity'] as int,
            "qty": item['quantity'] as int,
          };

          if (item['addon_ids'] != null && (item['addon_ids'] as String).isNotEmpty) {
            itemMap["addon_id"] = jsonDecode(item['addon_ids'] as String);
          }
          if (item['addon_data'] != null && (item['addon_data'] as String).isNotEmpty) {
            itemMap["addon_data"] = jsonDecode(item['addon_data'] as String);
          }

          return itemMap;
        }).toList();

        final hasAddress = addressUuid != null && addressUuid.isNotEmpty;

        final couponCode = await SecureStorage.getSelectedCouponCode();
        final walletPoints = await SecureStorage.getAppliedWalletPoints();

        final apiResponse = await _remoteDataSource.calculateFoodCartTotals(
          vendorId: vendorId,
          customerName: customerName,
          customerId: customerId,
          customerUuid: customerUuid,
          addressUuid: hasAddress ? addressUuid : null,
          lat: hasAddress ? null : lat,
          lng: hasAddress ? null : lng,
          couponCode: (couponCode != null && couponCode.isNotEmpty) ? couponCode : null,
          applyWalletPoints: walletPoints > 0 ? walletPoints : null,
          items: payloadItems,
        );

        final List<CartItem> parsedItems = localItems.map((item) {
          final double price = (item['price'] as num).toDouble();
          final int quantity = item['quantity'] as int;
          return CartItem(
            id: item['id'] as int, // Use the actual DB primary key
            productVariantId: item['vendor_item_id'] as int,
            quantity: quantity,
            price: price,
            totalPrice: price * quantity,
            variantUuId: item['vendor_item_id'].toString(),
            sellingPrice: price,
            actualPrice: price,
            subUomName: "qty",
            subUomShortName: "qty",
            conversionFactor: 1.0,
            uomName: "qty",
            uomShortName: "qty",
            product: CartProduct(
              id: item['vendor_item_id'] as int,
              uuId: item['vendor_item_id'].toString(),
              productName: item['name'] as String,
              slug: item['name'].toString().toLowerCase().replaceAll(' ', '-'),
              productImage: item['image'] as String? ?? "",
              images: [],
            ),
          );
        }).toList();

        final dataMap = apiResponse['data'] as Map<String, dynamic>? ?? {};
        final String? vendorUuidFromApi = dataMap['vendor_uu_id'] ?? dataMap['vendor']?['uu_id'];
        if (vendorUuidFromApi != null && vendorUuidFromApi.isNotEmpty) {
          SecureStorage.saveSelectedVendorUuid(vendorUuidFromApi);
          logger.d('===== FOOD ORDER UI ===== Restored Selected Vendor UUID from Cart Totals API: $vendorUuidFromApi');
        }
        final cartData = CartData(
          cartId: vendorId,
          totalItems: parsedItems.length,
          grandTotal: (dataMap['grand_total'] as num?)?.toDouble() ?? 0.0,
          productsTotal: (dataMap['subtotal'] as num?)?.toDouble() ?? 0.0,
          discountAmount: (dataMap['coupon_discount'] as num?)?.toDouble() ?? 0.0,
          discountedTotal: (dataMap['discounted_total'] as num?)?.toDouble() ?? 0.0,
          walletPointsUsed: (dataMap['wallet_points_used'] as num?)?.toInt() ?? 0,
          walletDiscountAmount: (dataMap['wallet_discount_amount'] as num?)?.toDouble() ?? 0.0,
          taxAmount: (dataMap['tax'] as num?)?.toDouble() ?? 0.0,
          packingCharge: (dataMap['packing_charge'] as num?)?.toDouble() ?? 0.0,
          deliveryInfo: DeliveryInfo(
            distanceKm: 0.0,
            freeKm: 0.0,
            perKmCharge: 0.0,
            deliveryCharge: (dataMap['delivery_charge'] as num?)?.toDouble() ?? 0.0,
            isFree: ((dataMap['delivery_charge'] as num?)?.toDouble() ?? 0.0) == 0.0,
          ),
          items: parsedItems,
        );

        final cartResponse = CartResponse(
          status: 200,
          message: apiResponse['message'] as String? ?? "Calculated successfully",
          data: cartData,
        );
        
        await SecureStorage.saveCartData(jsonEncode(cartResponse.toJson()), isFood: true);
        return cartResponse;
      } catch (e) {
        logger.e('❌ CartRepository: getCartList (Food Mode) failed — $e');
        final localData = await SecureStorage.getCartData(isFood: true);
        if (localData != null && localData.isNotEmpty) {
          logger.i('📂 CartRepository: Returning cached cart from local storage');
          return CartResponse.fromJson(jsonDecode(localData));
        }
        rethrow;
      }
    }

    logger.i('📋 CartRepository: getCartList(lat=$lat, lng=$lng)');
    try {
      final response = await _remoteDataSource.getCartList(lat: lat, lng: lng);
      final cartResponse = CartResponse.fromJson(response);
      if (cartResponse.status == 200 && cartResponse.data != null) {
        final itemCount = cartResponse.data!.items?.length ?? 0;
        if (itemCount > 0) {
          toggleFoodCartMode(false);
        }
        logger.i(
          '✅ CartRepository: Cart fetched — $itemCount item(s), grandTotal=₹${cartResponse.data!.grandTotal}',
        );
        await SecureStorage.saveCartData(jsonEncode(cartResponse.toJson()), isFood: false);
      } else {
        logger.w(
          '⚠️ CartRepository: getCartList returned status=${cartResponse.status}',
        );
      }
      return cartResponse;
    } catch (e) {
      logger.e(
        '❌ CartRepository: getCartList failed — $e. Falling back to local storage...',
      );
      final localData = await SecureStorage.getCartData(isFood: false);
      if (localData != null && localData.isNotEmpty) {
        logger.i('📂 CartRepository: Returning cached cart from local storage');
        return CartResponse.fromJson(jsonDecode(localData));
      }
      logger.e('❌ CartRepository: No local cart data available — rethrowing');
      rethrow;
    }
  }

  @override
  Future<CartResponse> updateCart({
    required int cartItemId,
    required int quantity,
    required double lat,
    required double lng,
    required bool isFood,
  }) async {
    toggleFoodCartMode(isFood);
    if (isFood) {
      logger.i('🔄 CartRepository: updateCart (Food Mode) — item=$cartItemId, qty=$quantity');
      await FoodCartDb.instance.updateItemQuantity(cartItemId, quantity);
      return await getCartList(lat: lat, lng: lng, isFood: true);
    }

    logger.i(
      '🔄 CartRepository: updateCart(cartItemId=$cartItemId, qty=$quantity)',
    );
    final response = await _remoteDataSource.updateCart(
      cartItemId: cartItemId,
      quantity: quantity,
      lat: lat,
      lng: lng,
    );
    final cartResponse = CartResponse.fromJson(response);
    if (cartResponse.status == 200 && cartResponse.data != null) {
      logger.i('💾 CartRepository: Caching updateCart response');
      await SecureStorage.saveCartData(jsonEncode(cartResponse.toJson()), isFood: false);
    } else {
      logger.w(
        '⚠️ CartRepository: updateCart returned status=${cartResponse.status}',
      );
    }
    return cartResponse;
  }

  @override
  Future<CartResponse> clearCart({required bool isFood}) async {
    if (isFood) {
      logger.i('🗑️ CartRepository: clearCart (Food Mode)');
      await FoodCartDb.instance.clearCart();
      await SecureStorage.saveCartData('', isFood: true);
      await SecureStorage.saveSelectedCouponCode('');
      await SecureStorage.saveAppliedWalletPoints(0);
      await SecureStorage.saveSelectedVendorUuid('');
      await SecureStorage.saveSelectedVendorName('');
      await SecureStorage.saveSelectedVendorImage('');
      return CartResponse(
        status: 200,
        message: "Cart cleared successfully",
        data: CartData(
          items: [],
          totalItems: 0,
          grandTotal: 0.0,
          productsTotal: 0.0,
        ),
      );
    }

    logger.i('🗑️ CartRepository: clearCart()');
    final response = await _remoteDataSource.clearCart();
    final cartResponse = CartResponse.fromJson(response);
    if (cartResponse.status == 200) {
      logger.i('🗑️ CartRepository: Cart cleared — wiping SecureStorage cache');
      await SecureStorage.saveCartData('', isFood: false);
    } else {
      logger.w(
        '⚠️ CartRepository: clearCart returned status=${cartResponse.status}',
      );
    }
    return cartResponse;
  }

  @override
  Future<CartResponse> validateAddress(String addressUuid) async {
    logger.i('📍 CartRepository: validateAddress(uuid=$addressUuid)');
    final response = await _remoteDataSource.validateAddress(addressUuid);
    final cartResponse = CartResponse.fromJson(response);
    logger.d(
      '📍 CartRepository: validateAddress → status=${cartResponse.status}, msg="${cartResponse.message}"',
    );
    return cartResponse;
  }

  @override
  Future<CartResponse> removeCartItem(int cartItemId, {required bool isFood}) async {
    toggleFoodCartMode(isFood);
    if (isFood) {
      logger.i('🗑️ CartRepository: removeCartItem (Food Mode) — item=$cartItemId');
      await FoodCartDb.instance.removeItem(cartItemId);
      return await getCartList(lat: 0.0, lng: 0.0, isFood: true);
    }

    logger.i('🗑️ CartRepository: removeCartItem(cartItemId=$cartItemId)');
    final response = await _remoteDataSource.removeCartItem(cartItemId);
    final cartResponse = CartResponse.fromJson(response);
    if (cartResponse.status == 200 && cartResponse.data != null) {
      logger.i('💾 CartRepository: Caching removeCartItem response');
      await SecureStorage.saveCartData(jsonEncode(cartResponse.toJson()), isFood: false);
    } else {
      logger.w(
        '⚠️ CartRepository: removeCartItem returned status=${cartResponse.status}',
      );
    }
    return cartResponse;
  }

  // --- Coupon Methods ---
  @override
  Future<CouponListResponse> getAvailableCoupons({bool isFood = false}) async {
    if (isFood) {
      logger.d('===== FOOD ORDER UI ===== getAvailableCoupons (Food Mode) called');
      try {
        final vendorUuid = await SecureStorage.getSelectedVendorUuid();
        logger.d('===== FOOD ORDER UI ===== getAvailableCoupons (Food Mode) selectedVendorUuid: $vendorUuid');
        if (vendorUuid == null || vendorUuid.isEmpty) {
          logger.w('===== FOOD ORDER UI ===== vendorUuid is null or empty, falling back to default vendor UUID');
        }
        final finalVendorUuid = (vendorUuid != null && vendorUuid.isNotEmpty)
            ? vendorUuid
            : "808b9522-a496-463b-8bc6-037850463bed";

        // Calculate current cart total from local DB
        double cartTotal = 0.0;
        final localItems = await FoodCartDb.instance.getCartItems();
        for (final item in localItems) {
          final double price = (item['price'] as num).toDouble();
          final int quantity = item['quantity'] as int;
          cartTotal += price * quantity;
        }
        logger.d('===== FOOD ORDER UI ===== getAvailableCoupons (Food Mode) cartTotal: $cartTotal');

        final rawResponse = await _remoteDataSource.getAvailableFoodCoupons(finalVendorUuid);
        logger.d('===== FOOD ORDER UI ===== getAvailableCoupons (Food Mode) rawResponse: $rawResponse');
        final List<dynamic> couponsData = rawResponse['data'] as List<dynamic>? ?? [];
        logger.d('===== FOOD ORDER UI ===== getAvailableCoupons (Food Mode) couponsData count: ${couponsData.length}');
        final List<CouponModel> mappedCoupons = couponsData.map((cMap) {
          final c = cMap as Map<String, dynamic>;
          final double orderVal = (c['order_value'] as num?)?.toDouble() ?? 0.0;
          final double discVal = (c['disc_value'] as num?)?.toDouble() ?? 0.0;
          final double? capLimit = (c['cap_limit'] as num?)?.toDouble();
          final String couponType = c['coupon_type'] ?? '';

          final bool isApplicable = cartTotal >= orderVal;
          final double minOrderNeeded = cartTotal < orderVal ? orderVal - cartTotal : 0.0;

          double discountPreview = 0.0;
          if (isApplicable) {
            if (couponType == 'percentile') {
              discountPreview = cartTotal * (discVal / 100.0);
              if (capLimit != null && capLimit > 0 && discountPreview > capLimit) {
                discountPreview = capLimit;
              }
            } else {
              discountPreview = discVal;
            }
          }

          final coupon = CouponModel(
            couponCode: c['coupon_code'] ?? '',
            couponType: couponType,
            discValue: discVal,
            capLimit: capLimit,
            orderValue: orderVal,
            couponDescription: c['coupon_description'],
            termscondition: c['termscondition'],
            expiryDate: c['expiry_date'],
            isApplicable: isApplicable,
            minOrderNeeded: minOrderNeeded,
            discountPreview: discountPreview,
          );
          logger.d('===== FOOD ORDER UI ===== Mapped Coupon: ${coupon.couponCode} | isApplicable: ${coupon.isApplicable} | discountPreview: ${coupon.discountPreview}');
          return coupon;
        }).toList();

        return CouponListResponse(status: 200, message: "OK", data: mappedCoupons);
      } catch (e) {
        logger.e("CartRepositoryImpl getAvailableCoupons (Food) error: $e");
        return CouponListResponse(status: 500, message: e.toString());
      }
    }

    logger.i('🏷️ CartRepository: getAvailableCoupons()');
    final response = await _remoteDataSource.getAvailableCoupons();
    return CouponListResponse.fromJson(response);
  }

  @override
  Future<ApplyCouponResponse> applyCoupon(String couponCode, {bool isFood = false}) async {
    if (isFood) {
      logger.i('🏷️ CartRepository: applyCoupon(couponCode=$couponCode) (Food Mode)');
      await SecureStorage.saveSelectedCouponCode(couponCode);
      return ApplyCouponResponse(
        status: 200,
        message: "Coupon applied successfully",
        data: ApplyCouponData(couponCode: couponCode),
      );
    }

    logger.i('🏷️ CartRepository: applyCoupon(couponCode=$couponCode)');
    final response = await _remoteDataSource.applyCoupon(couponCode);
    final couponResponse = ApplyCouponResponse.fromJson(response);
    return couponResponse;
  }

  @override
  Future<ApplyCouponResponse> removeCoupon({bool isFood = false}) async {
    if (isFood) {
      logger.i('🗑️ CartRepository: removeCoupon() (Food Mode)');
      await SecureStorage.saveSelectedCouponCode('');
      return ApplyCouponResponse(
        status: 200,
        message: "Coupon removed successfully",
        data: ApplyCouponData(couponCode: ''),
      );
    }

    logger.i('🗑️ CartRepository: removeCoupon()');
    final response = await _remoteDataSource.removeCoupon();
    return ApplyCouponResponse.fromJson(response);
  }

  @override
  Future<ValidateCouponResponse> validateCoupon(String code, {bool isFood = false}) async {
    if (isFood) {
      logger.i('🔍 CartRepository: validateCoupon(code=$code) (Food Mode)');
      // For local validation, fetch coupons and verify if code is valid
      final couponsResult = await getAvailableCoupons(isFood: true);
      if (couponsResult.status == 200 && couponsResult.data != null) {
        final match = couponsResult.data!.any((c) => c.couponCode.toUpperCase() == code.toUpperCase() && c.isApplicable);
        if (match) {
          return ValidateCouponResponse(
            status: 200,
            data: ApplyCouponData(couponCode: code),
          );
        }
      }
      return ValidateCouponResponse(status: 400);
    }

    logger.i('🔍 CartRepository: validateCoupon(code=$code)');
    final response = await _remoteDataSource.validateCoupon(code);
    return ValidateCouponResponse.fromJson(response);
  }
}
