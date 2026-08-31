abstract class RegisterEvent {}

class RegisterButtonPressed extends RegisterEvent {
  final String name;
  final String email;
  final String mobile;
  final int? resendToken;

  RegisterButtonPressed({
    required this.name,
    required this.email,
    required this.mobile,
    this.resendToken,
  });
}

class RegisterCodeSentEvent extends RegisterEvent {
  final String verificationId;
  final int? resendToken;
  final String message;

  RegisterCodeSentEvent({
    required this.verificationId,
    this.resendToken,
    this.message = 'OTP sent successfully',
  });
}

class RegisterErrorEvent extends RegisterEvent {
  final String error;

  RegisterErrorEvent(this.error);
}