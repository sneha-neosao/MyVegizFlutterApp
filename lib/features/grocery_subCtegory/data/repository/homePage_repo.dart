import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../models/homePage_model.dart';
import '../datasources/homePage_datasource.dart';
import '../../../../core/api/api/api_exception.dart';

abstract class HomePageRepository {
  Future<Either<Failure, HomePageModel>> fetchHomePageData({
    required String mainCategorySlug,
    String? homeTabSlug,
    required double lat,
    required double lng,
    String? q,
  });
}

class HomePageRepositoryImpl implements HomePageRepository {
  final HomePageRemoteDataSource remoteDataSource;

  HomePageRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, HomePageModel>> fetchHomePageData({
    required String mainCategorySlug,
    String? homeTabSlug,
    required double lat,
    required double lng,
    String? q,
  }) async {
    try {
      final data = await remoteDataSource.fetchHomePageData(
        mainCategorySlug: mainCategorySlug,
        homeTabSlug: homeTabSlug,
        lat: lat,
        lng: lng,
        q: q,
      );
      if (data.status == 200 || data.status == 201) {
        return Right(data);
      } else {
        return Left(
          ServerFailure(data.message ?? "Failed to fetch home page data"),
        );
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
