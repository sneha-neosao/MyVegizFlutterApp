import 'package:firebase_auth/firebase_auth.dart';

abstract class SendOtpState {}

class SendOtpInitial extends SendOtpState {}

class SendOtpLoading extends SendOtpState {}

class SendOtpSuccess extends SendOtpState {
  final String message;
  final String? verificationId;
  final int? resendToken;

  SendOtpSuccess(this.message, {this.verificationId, this.resendToken});
}

class SendOtpAutoVerified extends SendOtpState {
  final UserCredential userCredential;

  SendOtpAutoVerified(this.userCredential);
}

class SendOtpFailure extends SendOtpState {
  final String error;

  SendOtpFailure(this.error);
}

class SendOtpTimeoutState extends SendOtpState {
  final String verificationId;

  SendOtpTimeoutState(this.verificationId);
}