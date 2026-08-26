abstract class RegisterEvent {}

class RegisterButtonPressed extends RegisterEvent {
  final String name;
  final String email;
  final String mobile;

  RegisterButtonPressed({
    required this.name,
    required this.email,
    required this.mobile,
  });
}