import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../../../../../core/services/firebase_auth_service.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/usecase/checkUserExist_usecase.dart';
import './verifyOtp_event.dart';
import './verifyOtp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final CheckUserExistUseCase checkUserExistUseCase;
  final FirebaseAuthService authService;

  VerifyOtpBloc(this.checkUserExistUseCase, this.authService) : super(VerifyOtpInitial()) {
    on<VerifyOtpPressed>((event, emit) async {
      logger.i("🚀 VerifyOtpBloc: Triggered for mobile: ${event.mobile}, OTP: ${event.otp}");
      emit(VerifyOtpLoading());

      // 1. If verificationId is provided, verify OTP with Firebase Auth first
      if (event.verificationId != null && event.verificationId!.isNotEmpty) {
        try {
          logger.i("🔐 VerifyOtpBloc: Verifying with Firebase Auth [vId: ${event.verificationId}]");
          final userCredential = await authService.signInWithOtp(
            verificationId: event.verificationId!,
            smsCode: event.otp,
          );
          logger.i("✅ VerifyOtpBloc: Firebase verification successful! UID: ${userCredential.user?.uid}");

          final firebaseIdToken = await userCredential.user?.getIdToken();
          if (firebaseIdToken != null) {
            await SecureStorage.saveAccessToken(firebaseIdToken);
          }
        } on FirebaseAuthException catch (e) {
          logger.e("❌ VerifyOtpBloc: Firebase Auth Error [${e.code}] — ${e.message}");
          emit(VerifyOtpFailure(e.message ?? 'Invalid verification code'));
          return;
        } catch (e) {
          logger.e("❌ VerifyOtpBloc: Unexpected Firebase Error — $e");
          emit(VerifyOtpFailure(e.toString()));
          return;
        }
      }

      // 2. On Firebase OTP success, call checkUserExist API with the mobile number
      logger.i("🌐 VerifyOtpBloc: Calling checkUserExist API for mobile: ${event.mobile}");
      final res = await checkUserExistUseCase(event.mobile);

      res.fold(
        (failure) {
          logger.e("❌ VerifyOtpBloc: Check user exist failed: ${failure.message}");
          emit(VerifyOtpFailure(failure.message));
        },
        (success) {
          logger.i("✅ VerifyOtpBloc: Check user exist success: ${success.message}");
          emit(VerifyOtpSuccess(success));
        },
      );
    });
  }
}