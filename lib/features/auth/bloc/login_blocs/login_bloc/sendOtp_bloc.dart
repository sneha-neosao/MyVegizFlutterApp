import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/logger.dart';
import '../../../domain/usecase/sendOtp_usecase.dart';
import './sendOtp_event.dart';
import './sendOtp_state.dart';

class SendOtpBloc extends Bloc<SendOtpEvent, SendOtpState> {
  final SendOtpUseCase sendOtpUseCase;

  SendOtpBloc(this.sendOtpUseCase) : super(SendOtpInitial()) {
    on<SendOtpButtonPressed>((event, emit) async {
      logger.i("🚀 SendOtpBloc Triggered");
      logger.d("📱 Mobile: ${event.mobile}");

      emit(SendOtpLoading());

      final res = await sendOtpUseCase(event.mobile);

      res.fold(
            (l) {
          logger.e("❌ SendOtp Failed: ${l.message}");
          emit(SendOtpFailure(l.message));
        },
            (r) {
          logger.i("✅ SendOtp Success: ${r.message}");
          emit(SendOtpSuccess(r.message));
        },
      );
    });
  }
}