import 'package:fpdart/fpdart.dart';

import '../../../../core/api/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/profile_image_notifier.dart';
import '../datasources/checkUserExist_datasource.dart';
import '../models/checkUserExist_model.dart';

abstract class CheckUserExistRepository {
  Future<Either<Failure, CheckUserExistModel>> checkUserExist(String mobile);
}

class CheckUserExistRepositoryImpl implements CheckUserExistRepository {
  final CheckUserExistRemoteDataSource remoteDataSource;

  CheckUserExistRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, CheckUserExistModel>> checkUserExist(
      String mobile) async {
    try {
      logger.i("📦 CheckUserExist Repository Called for $mobile");
      final result = await remoteDataSource.checkUserExist(mobile);

      logger.i("📥 API Response: status=${result.status}, message=${result.message}");
      if (result.status == 200 || result.status == 201) {
        if (result.data != null) {
          if (result.data!.accessToken != null &&
              result.data!.accessToken!.isNotEmpty) {
            await SecureStorage.saveAccessToken(result.data!.accessToken!);
          }
          if (result.data!.refreshToken != null &&
              result.data!.refreshToken!.isNotEmpty) {
            await SecureStorage.saveRefreshToken(result.data!.refreshToken!);
          }
          if (result.data!.customer != null) {
            final customer = result.data!.customer!;
            await SecureStorage.saveCustomerId(customer.id);
            await SecureStorage.saveCustomerName(customer.name);
            await SecureStorage.saveCustomerContact(customer.contact);
            if (customer.email != null && customer.email!.isNotEmpty) {
              await SecureStorage.saveCustomerEmail(customer.email!);
            }
            await SecureStorage.saveCustomerUuid(customer.uuId);
            if (customer.profileImage != null &&
                customer.profileImage!.isNotEmpty) {
              await SecureStorage.saveCustomerProfileImage(
                customer.profileImage!,
              );
              profileImageNotifier.value = customer.profileImage!;
            }
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
