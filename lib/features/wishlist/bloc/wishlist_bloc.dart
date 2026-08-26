import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/wishlist_model.dart';
import '../data/repository/wishlist_repo.dart';
import './wishlist_event.dart';
import './wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final WishlistRepository repository;
  
  // Keep track of wishlisted IDs globally so we can update UI easily
  Set<int> wishlistedProductIds = {};
  List<WishlistItemModel> currentItems = [];

  WishlistBloc({required this.repository}) : super(WishlistInitial()) {
    on<FetchWishlist>(_onFetchWishlist);
    on<ToggleWishlistEvent>(_onToggleWishlist);
    on<ClearWishlistEvent>((event, emit) {
      wishlistedProductIds.clear();
      currentItems.clear();
      emit(WishlistInitial());
    });
  }

  Future<void> _onFetchWishlist(FetchWishlist event, Emitter<WishlistState> emit) async {
    emit(WishlistLoading());
    final result = await repository.getWishlist();
    
    result.fold(
      (failure) => emit(WishlistError(failure.message)),
      (items) {
        currentItems = List.from(items);
        wishlistedProductIds = items.map((e) => e.productId).toSet();
        emit(WishlistLoaded(
          items: currentItems, 
          wishlistedProductIds: Set.from(wishlistedProductIds)
        ));
      },
    );
  }

  Future<void> _onToggleWishlist(ToggleWishlistEvent event, Emitter<WishlistState> emit) async {
    // ⚡️ Optimistic Update: Update the local set immediately for instant UI feedback
    final wasSaved = wishlistedProductIds.contains(event.productId);
    
    // Toggle locally first (Optimistic UI)
    if (wasSaved) {
      wishlistedProductIds.remove(event.productId);
      currentItems.removeWhere((item) => item.productId == event.productId);
    } else {
      wishlistedProductIds.add(event.productId);
      // We don't have the full WishlistItemModel yet for an ADD, 
      // so we'll fetch it after the API call or just show the heart filled.
    }

    // Notify listeners of the change immediately
    emit(WishlistLoaded(
      items: List.from(currentItems), 
      wishlistedProductIds: Set.from(wishlistedProductIds)
    ));

    final result = await repository.toggleWishlist(event.productId);
    
    result.fold(
      (failure) {
        // 🚨 Rollback on failure
        if (wasSaved) {
          wishlistedProductIds.add(event.productId);
        } else {
          wishlistedProductIds.remove(event.productId);
        }
        emit(WishlistActionError(failure.message));
        emit(WishlistLoaded(
          items: List.from(currentItems), 
          wishlistedProductIds: Set.from(wishlistedProductIds)
        ));
      },
      (response) {
        // Sync with actual response status
        if (response.isSaved) {
          wishlistedProductIds.add(event.productId);
        } else {
          wishlistedProductIds.remove(event.productId);
          currentItems.removeWhere((item) => item.productId == event.productId);
        }

        emit(WishlistActionSuccess(
          message: response.message, 
          isSaved: response.isSaved, 
          productId: event.productId
        ));
        
        emit(WishlistLoaded(
          items: List.from(currentItems), 
          wishlistedProductIds: Set.from(wishlistedProductIds)
        ));

        // 🔥 If we added an item, we might want to re-fetch the full list 
        // to get the correct model data for the new item in the Wishlist page.
        if (response.isSaved) {
          add(FetchWishlist());
        }
      },
    );
  }
}
