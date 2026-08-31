import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/firebase_auth_service.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/usecase/register_usecase.dart';
import './signup_event.dart';
import './signup_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterUseCase registerUseCase;
  final FirebaseAuthService authService;

  RegisterBloc(this.registerUseCase, this.authService) : super(RegisterInitial()) {
    on<RegisterButtonPressed>((event, emit) async {
      logger.i(
        '📝 RegisterBloc: Register requested — name="${event.name}", email="${event.email}", mobile="${event.mobile}"',
      );
      emit(RegisterLoading());

      // Trigger Firebase Phone Auth for phone verification during registration
      await authService.verifyPhoneNumber(
        phoneNumber: event.mobile,
        resendToken: event.resendToken,
        onVerificationCompleted: (credential) {
          logger.i("⚡ RegisterBloc: onVerificationCompleted");
        },
        onVerificationFailed: (errorMessage, exception) {
          logger.e("❌ RegisterBloc: onVerificationFailed: $errorMessage");
          add(RegisterErrorEvent(errorMessage));
        },
        onCodeSent: (verificationId, resendToken) {
          logger.i("📬 RegisterBloc: onCodeSent: $verificationId (resendToken: $resendToken)");
          add(RegisterCodeSentEvent(
            verificationId: verificationId,
            resendToken: resendToken,
            message: 'OTP sent to ${event.mobile}',
          ));
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          logger.w("⏳ RegisterBloc: onCodeAutoRetrievalTimeout: $verificationId");
        },
      );
    });

    on<RegisterCodeSentEvent>((event, emit) {
      logger.i("✅ RegisterBloc: Emitting RegisterSuccess [verificationId: ${event.verificationId}]");
      emit(RegisterSuccess(
        event.message,
        verificationId: event.verificationId,
        resendToken: event.resendToken,
      ));
    });

    on<RegisterErrorEvent>((event, emit) {
      logger.e("❌ RegisterBloc: Emitting RegisterFailure [${event.error}]");
      emit(RegisterFailure(event.error));
    });
  }
}
