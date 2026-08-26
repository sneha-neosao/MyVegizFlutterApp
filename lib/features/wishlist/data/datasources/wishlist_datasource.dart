import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/wishlist_model.dart';
import '../../../../core/utils/logger.dart';

abstract class WishlistRemoteDataSource {
  Future<WishlistToggleResponse> toggleWishlist(int productId);
  Future<WishlistListResponse> getWishlist();
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final ApiHelper apiHelper;

  WishlistRemoteDataSourceImpl({required this.apiHelper});

  @override
  Future<WishlistToggleResponse> toggleWishlist(int productId) async {
    try {
      final response = await apiHelper.execute(
        method: Method.post,
        url: ApiUrl.toggleWishlist(productId),
      );
      if (response != null && response['data'] != null) {
        return WishlistToggleResponse.fromJson(response['data']);
      } else {
        throw Exception("Failed to toggle wishlist");
      }
    } catch (e) {
      logger.e("WishlistRemoteDataSourceImpl toggleWishlist error: $e");
      rethrow;
    }
  }

  @override
  Future<WishlistListResponse> getWishlist() async {
    try {
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.getWishlist,
      );
      if (response != null) {
        return WishlistListResponse.fromJson(response);
      } else {
        throw Exception("Failed to load wishlist");
      }
    } catch (e) {
      logger.e("WishlistRemoteDataSourceImpl getWishlist error: $e");
      rethrow;
    }
  }
}
