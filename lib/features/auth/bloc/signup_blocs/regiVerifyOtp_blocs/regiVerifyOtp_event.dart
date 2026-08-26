abstract class RegiVerifyOtpEvent {}

class RegiVerifyOtpPressed extends RegiVerifyOtpEvent {
  final String mobile;
  final String otp;

  RegiVerifyOtpPressed({required this.mobile, required this.otp});
}