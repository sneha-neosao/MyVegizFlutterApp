import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/register_datasource.dart';
import '../models/register_model.dart';
import '../../../../core/api/api/api_exception.dart';

abstract class RegisterRepository {
  Future<Either<Failure, RegisterModel>> register({
    required String name,
    required String email,
    required String mobile,
  });
}

class RegisterRepositoryImpl implements RegisterRepository {
  final RegisterRemoteDataSource remoteDataSource;

  RegisterRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, RegisterModel>> register({
    required String name,
    required String email,
    required String mobile,
  }) async {
    try {
      final result = await remoteDataSource.register(
        name: name,
        email: email,
        mobile: mobile,
      );

      if (result.status == 200 || result.status == 201) {
        return Right(result);
      } else {
        return Left(ServerFailure(result.message));
      }
    } catch (e) {
      if (e is ApiException) {
        return Left(ServerFailure(e.message));
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}

// import 'package:fpdart/fpdart.dart';
// import '../../core/api/api/api_exception.dart';
// import '../../core/errors/failures.dart';
// import '../models/register_model.dart';
// import '../datasources/register_datasource.dart';
//
//
// abstract class RegisterRepository {
//   Future<Either<Failure, RegisterModel>> register({
//     required String name,
//     required String email,
//     required String mobile,
//   });
// }
//
// class RegisterRepositoryImpl implements RegisterRepository {
//   final RegisterRemoteDataSource remote;
//
//   RegisterRepositoryImpl(this.remote);
//
//   @override
//   Future<Either<Failure, RegisterModel>> register({
//     required String name,
//     required String email,
//     required String mobile,
//   }) async {
//     try {
//       final result = await remote.register(
//         name: name,
//         email: email,
//         mobile: mobile,
//       );
//       return Right(result);
//     } on ApiException catch (e) {
//       return Left(ServerFailure(e.message));
//     }
//   }
// }
