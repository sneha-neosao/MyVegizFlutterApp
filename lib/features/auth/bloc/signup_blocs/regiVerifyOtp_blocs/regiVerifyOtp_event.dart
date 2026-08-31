abstract class RegiVerifyOtpEvent {}

class RegiVerifyOtpPressed extends RegiVerifyOtpEvent {
  final String mobile;
  final String otp;
  final String? verificationId;

  RegiVerifyOtpPressed({
    required this.mobile,
    required this.otp,
    this.verificationId,
  });
}