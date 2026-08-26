import 'package:fpdart/fpdart.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/verifyOtp_model.dart';
import '../../data/repository/verifyOtp_repo.dart';

class VerifyOtpUseCase {
  final VerifyOtpRepository repo;

  VerifyOtpUseCase(this.repo);

  Future<Either<Failure, VerifyOtpModel>> call(
      String mobile, String otp) {

    logger.i("⚙️ UseCase Called");
    logger.d("📱 Mobile: $mobile | OTP: $otp");

    return repo.verifyOtp(mobile, otp);
  }
}


// import '../../../../remote/models/verifyOtp_model.dart';
// import '../../../../remote/repositories/verifyOtp_repo.dart';
//
// class VerifyOtpUseCase {
//   final VerifyOtpRepository repository;
//
//   VerifyOtpUseCase(this.repository);
//
//   Future<VerifyOtpModel> call(String mobile, String otp) async {
//     return await repository.verifyOtp(mobile, otp);
//   }
// }
