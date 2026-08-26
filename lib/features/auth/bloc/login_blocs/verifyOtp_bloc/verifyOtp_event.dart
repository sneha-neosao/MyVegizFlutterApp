abstract class VerifyOtpEvent {}

class VerifyOtpPressed extends VerifyOtpEvent {
  final String mobile;
  final String otp;

  VerifyOtpPressed(this.mobile, this.otp);
}