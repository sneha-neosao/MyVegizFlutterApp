abstract class SendOtpState {}

class SendOtpInitial extends SendOtpState {}

class SendOtpLoading extends SendOtpState {}

class SendOtpSuccess extends SendOtpState {
  final String message;

  SendOtpSuccess(this.message);
}

class SendOtpFailure extends SendOtpState {
  final String error;

  SendOtpFailure(this.error);
}