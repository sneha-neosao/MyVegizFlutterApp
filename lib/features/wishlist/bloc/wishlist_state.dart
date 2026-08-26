abstract class WishlistState {}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<dynamic> items; // Will be List<WishlistItemModel>
  final Set<int> wishlistedProductIds;

  WishlistLoaded({required this.items, required this.wishlistedProductIds});
}

class WishlistError extends WishlistState {
  final String message;

  WishlistError(this.message);
}

class WishlistActionSuccess extends WishlistState {
  final String message;
  final bool isSaved;
  final int productId;

  WishlistActionSuccess({required this.message, required this.isSaved, required this.productId});
}

class WishlistActionError extends WishlistState {
  final String message;

  WishlistActionError(this.message);
}
