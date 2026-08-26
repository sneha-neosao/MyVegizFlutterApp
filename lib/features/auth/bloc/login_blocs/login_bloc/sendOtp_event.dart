abstract class SendOtpEvent {}

class SendOtpButtonPressed extends SendOtpEvent {
  final String mobile;

  SendOtpButtonPressed(this.mobile);
}