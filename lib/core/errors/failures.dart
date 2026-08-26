import 'package:equatable/equatable.dart';

/// Defines different types of application failures as immutable classes,
/// extending [Failure] for consistent error handling across the app.

sealed class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

class EmptyFailure extends Failure {
  EmptyFailure(super.message);
}

class CredentialFailure extends Failure {
  CredentialFailure(super.message);
}

class DuplicateEmailFailure extends Failure {
  DuplicateEmailFailure(super.message);
}

class PasswordNotMatchFailure extends Failure {
  PasswordNotMatchFailure(super.message);
}

class InvalidEmailFailure extends Failure {
  InvalidEmailFailure(super.message);
}

class InvalidMobileNumberFailure extends Failure {
  InvalidMobileNumberFailure(super.message);
}

class InvalidPanNumberFailure extends Failure {
  InvalidPanNumberFailure(super.message);
}

class InvalidPasswordFailure extends Failure {
  InvalidPasswordFailure(super.message);
}

class InternetFailure extends Failure {
  InternetFailure(super.message);
}


class ApiFailure extends Failure {ApiFailure(super.message);}

