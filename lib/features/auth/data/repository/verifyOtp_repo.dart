import 'package:fpdart/fpdart.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/verifyOtp_datasource.dart';
import '../models/verifyOtp_model.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/profile_image_notifier.dart';

abstract class VerifyOtpRepository {
  Future<Either<Failure, VerifyOtpModel>> verifyOtp(String mobile, String otp);
}

class VerifyOtpRepositoryImpl implements VerifyOtpRepository {
  final VerifyOtpRemoteDataSource remote;

  VerifyOtpRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, VerifyOtpModel>> verifyOtp(
    String mobile,
    String otp,
  ) async {
    try {
      logger.i("📦 Repository Called");

      final res = await remote.verifyOtp(mobile: mobile, otp: otp);

      logger.i("📥 API Success Response");
      logger.d(res.toJson().toString());

      if (res.status == 200 || res.status == 201) {
        if (res.data != null) {
          await SecureStorage.saveAccessToken(res.data!.accessToken);
          await SecureStorage.saveRefreshToken(res.data!.refreshToken);
          await SecureStorage.saveCustomerId(res.data!.customer.id);
          await SecureStorage.saveCustomerName(res.data!.customer.name);
          await SecureStorage.saveCustomerContact(res.data!.customer.contact);
          await SecureStorage.saveCustomerEmail(res.data!.customer.email);
          await SecureStorage.saveCustomerUuid(res.data!.customer.uuId);
          if (res.data!.customer.profileImage != null &&
              res.data!.customer.profileImage!.isNotEmpty) {
            await SecureStorage.saveCustomerProfileImage(
              res.data!.customer.profileImage!,
            );
            profileImageNotifier.value = res.data!.customer.profileImage!;
          }
        }
        return Right(res);
      } else {
        return Left(ServerFailure(res.message));
      }
    } catch (e) {
      logger.e("❌ Repository Error: $e");
      if (e is ApiException) {
        return Left(ServerFailure(e.message));
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
