import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/features/auth/bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_event.dart';
import 'package:my_vegiz_flutter/features/auth/bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_state.dart';

import '../../../domain/usecase/regiVerifyOtp_usecase.dart';

class RegiVerifyOtpBloc
    extends Bloc<RegiVerifyOtpEvent, RegiVerifyOtpState> {
  final RegiVerifyOtpUseCase useCase;

  RegiVerifyOtpBloc(this.useCase)
      : super(RegiVerifyOtpInitial()) {
    on<RegiVerifyOtpPressed>((event, emit) async {
      emit(RegiVerifyOtpLoading());

      final result = await useCase(
        mobile: event.mobile,
        otp: event.otp,
      );

      result.fold(
            (failure) => emit(RegiVerifyOtpError(failure.message)),
            (success) => emit(RegiVerifyOtpSuccess(success)),
      );
    });
  }
}