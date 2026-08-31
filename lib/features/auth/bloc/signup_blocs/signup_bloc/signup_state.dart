abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final String message;
  final String? verificationId;
  final int? resendToken;

  RegisterSuccess(this.message, {this.verificationId, this.resendToken});
}

class RegisterFailure extends RegisterState {
  final String error;

  RegisterFailure(this.error);
}
