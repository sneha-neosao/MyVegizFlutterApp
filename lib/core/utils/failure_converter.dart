import '../errors/failures.dart';


/// Maps different types of [Failure] to user-friendly error messages.
/// This function is useful in the UI layer to show readable error messages
/// instead of exposing raw error objects or codes.
String mapFailureToMessage(Failure failure) {

  /// Using runtimeType to identify the type of Failure.
  /// This works well for simple type-based mapping but can be fragile
  /// if subclasses or runtime type changes occur.

  switch (failure.runtimeType) {
    case ServerFailure:
      return "Server Failure";
    case CacheFailure:
      return "Cache Failure";
    case EmptyFailure:
      return "Empty Failure";
    case CredentialFailure:
      return "Wrong mobile number or password";
    case DuplicateEmailFailure:
      return "Email already taken";
    case PasswordNotMatchFailure:
      return "Password not match";
    case InvalidEmailFailure:
      return "Invalid email format";
    case InvalidMobileNumberFailure:
      return "Invalid mobile number format";
    case InvalidPanNumberFailure:
      return "Invalid pan number format";
    case InvalidPasswordFailure:
      return "Invalid password format";
    default:
      return "Unexpected error";
  }
}
