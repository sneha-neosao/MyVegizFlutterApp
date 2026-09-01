import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/firebase_auth_service.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/usecase/sendOtp_usecase.dart';
import './sendOtp_event.dart';
import './sendOtp_state.dart';

class SendOtpBloc extends Bloc<SendOtpEvent, SendOtpState> {
  final SendOtpUseCase sendOtpUseCase;
  final FirebaseAuthService authService;

  SendOtpBloc(this.sendOtpUseCase, this.authService) : super(SendOtpInitial()) {
    on<SendOtpButtonPressed>((event, emit) async {
      logger.i("🚀 SendOtpBloc: Initiating Firebase Phone Auth for ${event.mobile}");
      emit(SendOtpLoading());

      // Trigger Firebase verifyPhoneNumber with all official callbacks
      await authService.verifyPhoneNumber(
        phoneNumber: event.mobile,
        resendToken: event.resendToken,
        onVerificationCompleted: (credential) {
          logger.i("⚡ SendOtpBloc: onVerificationCompleted triggered");
          if (!isClosed) add(SendOtpAutoVerifiedEvent(credential));
        },
        onVerificationFailed: (errorMessage, exception) {
          logger.e("❌ SendOtpBloc: onVerificationFailed: $errorMessage");
          if (!isClosed) add(SendOtpErrorEvent(errorMessage));
        },
        onCodeSent: (verificationId, resendToken) {
          logger.i("📬 SendOtpBloc: onCodeSent: $verificationId (resendToken: $resendToken)");
          if (!isClosed) {
            add(SendOtpCodeSentEvent(
              verificationId: verificationId,
              resendToken: resendToken,
            ));
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          logger.w("⏳ SendOtpBloc: onCodeAutoRetrievalTimeout: $verificationId");
          if (!isClosed) add(SendOtpTimeoutEvent(verificationId));
        },
      );
    });

    on<SendOtpCodeSentEvent>((event, emit) {
      logger.i("✅ SendOtpBloc: Emitting SendOtpSuccess [verificationId: ${event.verificationId}]");
      emit(SendOtpSuccess(
        event.message,
        verificationId: event.verificationId,
        resendToken: event.resendToken,
      ));
    });

    on<SendOtpAutoVerifiedEvent>((event, emit) async {
      logger.i("⚡ SendOtpBloc: Signing in with auto-verified credential");
      try {
        final userCredential = await authService.signInWithCredential(event.credential);
        emit(SendOtpAutoVerified(userCredential));
      } catch (e) {
        logger.e("❌ SendOtpBloc: Auto-signin error: $e");
        emit(SendOtpFailure(e.toString()));
      }
    });

    on<SendOtpErrorEvent>((event, emit) {
      logger.e("❌ SendOtpBloc: Emitting SendOtpFailure [${event.error}]");
      emit(SendOtpFailure(event.error));
    });

    on<SendOtpTimeoutEvent>((event, emit) {
      logger.d("⏳ SendOtpBloc: Auto retrieval timeout reached for ${event.verificationId}");
      emit(SendOtpTimeoutState(event.verificationId));
    });
  }
}