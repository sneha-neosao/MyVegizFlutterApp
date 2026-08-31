import 'package:fpdart/fpdart.dart';

import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/regiVerifyOtp_datasource.dart';
import '../models/regiVerifyOtp_model.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/profile_image_notifier.dart';


abstract class RegiVerifyOtpRepository {
  Future<Either<Failure, RegiVerifyOtpModel>> verifyOtp({
    required String mobile,
    required String otp,
  });
}

class RegiVerifyOtpRepositoryImpl implements RegiVerifyOtpRepository {
  final RegiVerifyOtpDataSource dataSource;

  RegiVerifyOtpRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, RegiVerifyOtpModel>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final result =
      await dataSource.verifyOtp(mobile: mobile, otp: otp);

      if (result.status == 200 || result.status == 201) {
        if (result.data != null) {
          await SecureStorage.saveAccessToken(result.data!.accessToken);
          await SecureStorage.saveRefreshToken(result.data!.refreshToken);
          await SecureStorage.saveCustomerId(result.data!.customer.id);
          await SecureStorage.saveCustomerName(result.data!.customer.name);
          await SecureStorage.saveCustomerContact(result.data!.customer.contact);
          await SecureStorage.saveCustomerEmail(result.data!.customer.email);
          await SecureStorage.saveCustomerUuid(result.data!.customer.uuId);
          if (result.data!.customer.profileImage != null &&
              result.data!.customer.profileImage!.isNotEmpty) {
            await SecureStorage.saveCustomerProfileImage(
              result.data!.customer.profileImage!,
            );
            profileImageNotifier.value = result.data!.customer.profileImage!;
          }
        }
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