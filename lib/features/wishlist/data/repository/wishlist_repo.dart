import 'package:my_vegiz_flutter/core/errors/failures.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../datasources/wishlist_datasource.dart';
import '../models/wishlist_model.dart';
import '../../../../core/utils/logger.dart';

class WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;

  WishlistRepository({required this.remoteDataSource});

  Future<Either<Failure, WishlistToggleResponse>> toggleWishlist(
    int productId,
  ) async {
    try {
      final response = await remoteDataSource.toggleWishlist(productId);
      return Right(response);
    } catch (e) {
      logger.e("WishlistRepository toggleWishlist error: $e");
      if (e is ApiException) {
        return Left(ServerFailure(e.message));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<WishlistItemModel>>> getWishlist() async {
    try {
      final response = await remoteDataSource.getWishlist();
      return Right(response.data);
    } catch (e) {
      logger.e("WishlistRepository getWishlist error: $e");
      if (e is ApiException) {
        return Left(ServerFailure(e.message));
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
