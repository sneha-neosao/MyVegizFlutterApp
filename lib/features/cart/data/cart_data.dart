import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/utils/logger.dart';

/// Represents a single product in the local (static) cart.
class CartItem {
  final String image;
  final String title;
  final double price;
  int quantity;

  CartItem({
    required this.image,
    required this.title,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'image': image,
        'title': title,
        'price': price,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      image: json['image'] as String? ?? '',
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as int?) ?? 1,
    );
  }

  @override
  String toString() => 'CartItem(title: $title, qty: $quantity, price: $price)';
}

// ── Global cart (in-memory store) ──────────────────────────────────────────

final List<CartItem> globalCart = [];
bool isFoodCart = false; // Added to track if the current cart is from Food category

void toggleFoodCartMode(bool value) {
  isFoodCart = value;
}

const _storage = FlutterSecureStorage();
const _cartKey = 'secure_cart_data';

// ── Persistence ─────────────────────────────────────────────────────────────

Future<void> saveCartToStorage() async {
  try {
    final String jsonString = jsonEncode(
      globalCart.map((e) => e.toJson()).toList(),
    );
    await _storage.write(key: _cartKey, value: jsonString);
    logger.i(
      '💾 CartData: Saved ${globalCart.length} item(s) to secure storage',
    );
  } catch (e) {
    logger.e('💾 CartData: Failed to save cart to storage — $e');
  }
}

Future<void> loadCartFromStorage() async {
  logger.i('📂 CartData: Loading cart from secure storage...');
  try {
    final String? jsonString = await _storage.read(key: _cartKey);
    if (jsonString == null || jsonString.isEmpty) {
      logger.d('📂 CartData: No cart data found in storage — starting fresh');
      return;
    }
    final List<dynamic> decoded = jsonDecode(jsonString);
    globalCart.clear();
    for (final item in decoded) {
      globalCart.add(CartItem.fromJson(item as Map<String, dynamic>));
    }
    logger.i(
      '📂 CartData: Loaded ${globalCart.length} item(s) from storage',
    );
    for (final item in globalCart) {
      logger.d('   • $item');
    }
  } catch (e) {
    logger.e('📂 CartData: Failed to load cart from storage — $e');
  }
}

// ── Cart Operations ──────────────────────────────────────────────────────────

Future<void> addToCart(CartItem newItem) async {
  // Check if item already exists (match by title)
  for (final item in globalCart) {
    if (item.title == newItem.title) {
      item.quantity += newItem.quantity;
      logger.i(
        '🛒 CartData: Updated quantity of "${item.title}" to ${item.quantity}',
      );
      await saveCartToStorage();
      return;
    }
  }
  globalCart.add(newItem);
  logger.i(
    '🛒 CartData: Added new item "${newItem.title}" (qty: ${newItem.quantity}, price: ₹${newItem.price})',
  );
  await saveCartToStorage();
}

Future<void> removeFromCart(CartItem item) async {
  final removed = globalCart.remove(item);
  if (removed) {
    logger.i(
      '🗑️ CartData: Removed "${item.title}" from cart — ${globalCart.length} item(s) remaining',
    );
  } else {
    logger.w('🗑️ CartData: Tried to remove "${item.title}" but it was not found in cart');
  }
  await saveCartToStorage();
}
