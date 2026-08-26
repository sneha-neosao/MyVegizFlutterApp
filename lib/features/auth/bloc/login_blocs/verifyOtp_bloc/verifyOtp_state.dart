import 'package:my_vegiz_flutter/features/auth/data/models/verifyOtp_model.dart';

abstract class VerifyOtpState {}

class VerifyOtpInitial extends VerifyOtpState {}

class VerifyOtpLoading extends VerifyOtpState {}

class VerifyOtpSuccess extends VerifyOtpState {
  final VerifyOtpModel data;

  VerifyOtpSuccess(this.data);
}

class VerifyOtpFailure extends VerifyOtpState {
  final String error;

  VerifyOtpFailure(this.error);
}