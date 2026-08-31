import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/firebase_auth_service.dart';
import '../../../../../core/utils/logger.dart';
import 'package:my_vegiz_flutter/features/auth/bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_event.dart';
import 'package:my_vegiz_flutter/features/auth/bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_state.dart';
import '../../../domain/usecase/regiVerifyOtp_usecase.dart';

class RegiVerifyOtpBloc extends Bloc<RegiVerifyOtpEvent, RegiVerifyOtpState> {
  final RegiVerifyOtpUseCase useCase;
  final FirebaseAuthService authService;

  RegiVerifyOtpBloc(this.useCase, this.authService) : super(RegiVerifyOtpInitial()) {
    on<RegiVerifyOtpPressed>((event, emit) async {
      logger.i("🚀 RegiVerifyOtpBloc: Triggered for ${event.mobile}, OTP: ${event.otp}");
      emit(RegiVerifyOtpLoading());

      // 1. Verify with Firebase if verificationId is present
      if (event.verificationId != null && event.verificationId!.isNotEmpty) {
        try {
          logger.i("🔐 RegiVerifyOtpBloc: Verifying with Firebase Auth [vId: ${event.verificationId}]");
          final userCredential = await authService.signInWithOtp(
            verificationId: event.verificationId!,
            smsCode: event.otp,
          );
          logger.i("✅ RegiVerifyOtpBloc: Firebase verification successful for UID: ${userCredential.user?.uid}");
        } on FirebaseAuthException catch (e) {
          logger.e("❌ RegiVerifyOtpBloc: Firebase Auth Error [${e.code}] — ${e.message}");
          emit(RegiVerifyOtpError(e.message ?? 'Invalid verification code'));
          return;
        } catch (e) {
          logger.e("❌ RegiVerifyOtpBloc: Unexpected Firebase Error — $e");
          emit(RegiVerifyOtpError(e.toString()));
          return;
        }
      }

      // 2. Call backend register verify API
      logger.i("🌐 RegiVerifyOtpBloc: Syncing with Backend Register Verify API");
      final result = await useCase(
        mobile: event.mobile,
        otp: event.otp,
      );

      result.fold(
        (failure) {
          logger.e("❌ RegiVerifyOtpBloc: Backend verification failed: ${failure.message}");
          emit(RegiVerifyOtpError(failure.message));
        },
        (success) {
          logger.i("✅ RegiVerifyOtpBloc: Registration verification success");
          emit(RegiVerifyOtpSuccess(success));
        },
      );
    });
  }
}