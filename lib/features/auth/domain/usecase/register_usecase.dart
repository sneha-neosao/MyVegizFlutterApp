import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/register_model.dart';
import '../../data/repository/register_repo.dart';


class RegisterUseCase {

  final RegisterRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, RegisterModel>> call({
    required String name,
    required String email,
    required String mobile,
  }) {
    return repository.register(
      name: name,
      email: email,
      mobile: mobile,
    );
  }
}