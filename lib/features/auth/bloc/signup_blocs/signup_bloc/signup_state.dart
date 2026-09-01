import '../../../data/models/register_model.dart';

abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final RegisterModel model;
  final String? verificationId;
  final int? resendToken;

  RegisterSuccess(
    this.model, {
    this.verificationId,
    this.resendToken,
  });

  String get message => model.message;
}

class RegisterFailure extends RegisterState {
  final String error;

  RegisterFailure(this.error);
}

