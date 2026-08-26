import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/sendOtp_model.dart';
import '../../data/repository/sendOtp_repo.dart';


class SendOtpUseCase {
  final SendOtpRepository repository;

  SendOtpUseCase(this.repository);

  Future<Either<Failure, SendOtpModel>> call(String mobile) {
    return repository.sendOtp(mobile);
  }
}