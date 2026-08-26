import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/regiVerifyOtp_model.dart';
import '../../data/repository/regiVerifyOtp_repo.dart';


class RegiVerifyOtpUseCase {
  final RegiVerifyOtpRepository repository;

  RegiVerifyOtpUseCase(this.repository);

  Future<Either<Failure, RegiVerifyOtpModel>> call({
    required String mobile,
    required String otp,
  }) {
    return repository.verifyOtp(mobile: mobile, otp: otp);
  }
}