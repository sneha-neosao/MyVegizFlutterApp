import '../../../data/models/regiVerifyOtp_model.dart';

abstract class RegiVerifyOtpState {}

class RegiVerifyOtpInitial extends RegiVerifyOtpState {}

class RegiVerifyOtpLoading extends RegiVerifyOtpState {}

class RegiVerifyOtpSuccess extends RegiVerifyOtpState {
  final RegiVerifyOtpModel model;

  RegiVerifyOtpSuccess(this.model);
}

class RegiVerifyOtpError extends RegiVerifyOtpState {
  final String message;

  RegiVerifyOtpError(this.message);
}


// abstract class RegiVerifyOtpState {}
//
// class RegiVerifyOtpInitial extends RegiVerifyOtpState {}
//
// class RegiVerifyOtpLoading extends RegiVerifyOtpState {}
//
// class RegiVerifyOtpSuccess extends RegiVerifyOtpState {
//   final RegiVerifyOtpModel data;
//
//   RegiVerifyOtpSuccess(this.data);
// }
//
// class RegiVerifyOtpError extends RegiVerifyOtpState {
//   final String message;
//
//   RegiVerifyOtpError(this.message);
// }
