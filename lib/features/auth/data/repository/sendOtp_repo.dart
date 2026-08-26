import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api/api_exception.dart';
import '../datasources/sendOtp_datasource.dart';
import '../models/sendOtp_model.dart';

abstract class SendOtpRepository {
  Future<Either<Failure, SendOtpModel>> sendOtp(String mobile);
}

class SendOtpRepositoryImpl implements SendOtpRepository {
  final SendOtpRemoteDataSource remoteDataSource;

  SendOtpRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, SendOtpModel>> sendOtp(String mobile) async {
    try {
      final result = await remoteDataSource.sendOtp(mobile);
      if (result.status == 200 || result.status == 201) {
        return Right(result);
      } else {
        return Left(ServerFailure(result.message));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
