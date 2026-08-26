abstract class WishlistEvent {}

class FetchWishlist extends WishlistEvent {}

class ToggleWishlistEvent extends WishlistEvent {
  final int productId;

  ToggleWishlistEvent(this.productId);
}

class ClearWishlistEvent extends WishlistEvent {}

