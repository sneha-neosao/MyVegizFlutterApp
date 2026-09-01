import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/checkUserExist_model.dart';
import '../../data/repository/checkUserExist_repo.dart';

class CheckUserExistUseCase {
  final CheckUserExistRepository repository;

  CheckUserExistUseCase(this.repository);

  Future<Either<Failure, CheckUserExistModel>> call(String mobile) {
    return repository.checkUserExist(mobile);
  }
}
