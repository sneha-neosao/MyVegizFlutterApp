import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/features/auth/bloc/login_blocs/verifyOtp_bloc/verifyOtp_event.dart';
import 'package:my_vegiz_flutter/features/auth/bloc/login_blocs/verifyOtp_bloc/verifyOtp_state.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/usecase/verifyOtp_usecase.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final VerifyOtpUseCase useCase;

  VerifyOtpBloc(this.useCase) : super(VerifyOtpInitial()) {
    on<VerifyOtpPressed>((event, emit) async {
      logger.i("🚀 VerifyOtpBloc Triggered");
      logger.d("📱 Mobile: ${event.mobile}");
      logger.d("🔢 OTP: ${event.otp}");

      emit(VerifyOtpLoading());

      final res = await useCase(event.mobile, event.otp);

      res.fold(
            (l) {
          logger.e("❌ VerifyOtp Failed: ${l.message}");
          emit(VerifyOtpFailure(l.message));
        },
            (r) {
          logger.i("✅ VerifyOtp Success: ${r.message}");
          emit(VerifyOtpSuccess(r));
        },
      );
    });
  }
}