abstract class VerifyOtpEvent {}

class VerifyOtpPressed extends VerifyOtpEvent {
  final String mobile;
  final String otp;
  final String? verificationId;

  VerifyOtpPressed(this.mobile, this.otp, {this.verificationId});
}