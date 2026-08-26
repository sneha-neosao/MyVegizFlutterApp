abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final String message;

  RegisterSuccess(this.message);
}

class RegisterFailure extends RegisterState {
  final String error;

  RegisterFailure(this.error);
}


// import '../../../../remote/models/register_model.dart';
//
// abstract class RegisterState {}
//
// class RegisterInitial extends RegisterState {}
//
// class RegisterLoading extends RegisterState {}
//
// class RegisterSuccess extends RegisterState {
//   final RegisterModel model;
//
//   RegisterSuccess(this.model);
// }
//
// class RegisterError extends RegisterState {
//   final String message;
//
//   RegisterError(this.message);
// }
