import 'package:firebase_auth/firebase_auth.dart';

abstract class SendOtpEvent {}

class SendOtpButtonPressed extends SendOtpEvent {
  final String mobile;
  final int? resendToken;

  SendOtpButtonPressed(this.mobile, {this.resendToken});
}

class SendOtpCodeSentEvent extends SendOtpEvent {
  final String verificationId;
  final int? resendToken;
  final String message;

  SendOtpCodeSentEvent({
    required this.verificationId,
    this.resendToken,
    this.message = 'OTP sent successfully',
  });
}

class SendOtpAutoVerifiedEvent extends SendOtpEvent {
  final PhoneAuthCredential credential;

  SendOtpAutoVerifiedEvent(this.credential);
}

class SendOtpErrorEvent extends SendOtpEvent {
  final String error;

  SendOtpErrorEvent(this.error);
}

class SendOtpTimeoutEvent extends SendOtpEvent {
  final String verificationId;

  SendOtpTimeoutEvent(this.verificationId);
}