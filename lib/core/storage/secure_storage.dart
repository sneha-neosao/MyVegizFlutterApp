import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  /// 🔐 KEYS
  static const _accessToken = "ACCESS_TOKEN";
  static const _refreshToken = "REFRESH_TOKEN";
  static const _customerId = "CUSTOMER_ID";
  static const _customerName = "CUSTOMER_NAME";
  static const _customerContact = "CUSTOMER_CONTACT";
  static const _customerEmail = "CUSTOMER_EMAIL";
  static const _customerUuid = "CUSTOMER_UUID";
  static const _customerProfileImage = "CUSTOMER_PROFILE_IMAGE";
  static const _cartData = "CART_DATA";
  static const _foodCartData = "FOOD_CART_DATA";
  static const _selectedAddressUuid = "SELECTED_ADDRESS_UUID";
  static const _selectedCouponCode = "SELECTED_COUPON_CODE";
  static const _appliedWalletPoints = "APPLIED_WALLET_POINTS";
  static const _selectedVendorUuid = "SELECTED_VENDOR_UUID";
  static const _selectedVendorName = "SELECTED_VENDOR_NAME";
  static const _selectedVendorImage = "SELECTED_VENDOR_IMAGE";
  static const _recentlySearchedLocations = "RECENTLY_SEARCHED_LOCATIONS";
  static const _activeLocationData = "ACTIVE_LOCATION_DATA";
  static const _hasConfirmedLocation = "HAS_CONFIRMED_LOCATION";
  static const _firebaseToken = "FIREBASE_TOKEN";

  /// 🔥 SAVE METHODS

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessToken, value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshToken, value: token);
  }

  static Future<void> saveCustomerId(int id) async {
    await _storage.write(key: _customerId, value: id.toString());
  }

  static Future<void> saveCustomerName(String name) async {
    await _storage.write(key: _customerName, value: name);
  }

  static Future<void> saveCustomerContact(String contact) async {
    await _storage.write(key: _customerContact, value: contact);
  }

  static Future<void> saveCustomerEmail(String email) async {
    await _storage.write(key: _customerEmail, value: email);
  }

  static Future<void> saveCustomerUuid(String uuid) async {
    await _storage.write(key: _customerUuid, value: uuid);
  }

  static Future<void> saveCustomerProfileImage(String path) async {
    await _storage.write(key: _customerProfileImage, value: path);
  }

  static Future<void> saveCartData(String cartJson, {required bool isFood}) async {
    await _storage.write(key: isFood ? _foodCartData : _cartData, value: cartJson);
  }

  /// 🔥 GET METHODS
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshToken);
  }

  static Future<String?> getCustomerId() async {
    return await _storage.read(key: _customerId);
  }

  static Future<String?> getCustomerName() async {
    return await _storage.read(key: _customerName);
  }

  static Future<String?> getCustomerContact() async {
    return await _storage.read(key: _customerContact);
  }

  static Future<String?> getCustomerEmail() async {
    return await _storage.read(key: _customerEmail);
  }

  static Future<String?> getCustomerUuid() async {
    return await _storage.read(key: _customerUuid);
  }

  static Future<String?> getCustomerProfileImage() async {
    return await _storage.read(key: _customerProfileImage);
  }

  static Future<String?> getCartData({required bool isFood}) async {
    return await _storage.read(key: isFood ? _foodCartData : _cartData);
  }

  static Future<void> saveSelectedAddressUuid(String uuid) async {
    await _storage.write(key: _selectedAddressUuid, value: uuid);
  }

  static Future<String?> getSelectedAddressUuid() async {
    return await _storage.read(key: _selectedAddressUuid);
  }

  static Future<void> saveSelectedCouponCode(String code) async {
    await _storage.write(key: _selectedCouponCode, value: code);
  }

  static Future<String?> getSelectedCouponCode() async {
    return await _storage.read(key: _selectedCouponCode);
  }

  static Future<void> saveAppliedWalletPoints(int pts) async {
    await _storage.write(key: _appliedWalletPoints, value: pts.toString());
  }

  static Future<int> getAppliedWalletPoints() async {
    final val = await _storage.read(key: _appliedWalletPoints);
    return val != null ? (int.tryParse(val) ?? 0) : 0;
  }

  static Future<void> saveSelectedVendorUuid(String uuid) async {
    await _storage.write(key: _selectedVendorUuid, value: uuid);
  }

  static Future<String?> getSelectedVendorUuid() async {
    return await _storage.read(key: _selectedVendorUuid);
  }

  static Future<void> saveSelectedVendorName(String name) async {
    await _storage.write(key: _selectedVendorName, value: name);
  }

  static Future<String?> getSelectedVendorName() async {
    return await _storage.read(key: _selectedVendorName);
  }

  static Future<void> saveSelectedVendorImage(String image) async {
    await _storage.write(key: _selectedVendorImage, value: image);
  }

  static Future<String?> getSelectedVendorImage() async {
    return await _storage.read(key: _selectedVendorImage);
  }

  static Future<void> saveRecentlySearched(String data) async {
    await _storage.write(key: _recentlySearchedLocations, value: data);
  }

  static Future<String?> getRecentlySearched() async {
    return await _storage.read(key: _recentlySearchedLocations);
  }

  static Future<void> saveActiveLocationJson(String json) async {
    await _storage.write(key: _activeLocationData, value: json);
  }

  static Future<String?> getActiveLocationJson() async {
    return await _storage.read(key: _activeLocationData);
  }

  static Future<void> saveLocationConfirmed(bool confirmed) async {
    await _storage.write(key: _hasConfirmedLocation, value: confirmed.toString());
  }

  static Future<bool> isLocationConfirmed() async {
    final val = await _storage.read(key: _hasConfirmedLocation);
    return val == 'true';
  }

  /// 🔥 AUTH CHECK
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// 🔥 CLEAR (logout sathi)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> saveFirebaseToken(String? token) async {
    if (token != null) {
      await _storage.write(key: _firebaseToken, value: token);
    }
  }

  static Future<String?> getFirebaseToken() async {
    return await _storage.read(key: _firebaseToken);
  }
}
