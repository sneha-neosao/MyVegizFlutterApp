import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecase/register_usecase.dart';
import './signup_event.dart';
import './signup_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterUseCase registerUseCase;

  RegisterBloc(this.registerUseCase) : super(RegisterInitial()) {
    on<RegisterButtonPressed>((event, emit) async {
      logger.i(
        '📝 RegisterBloc: Register button pressed — name="${event.name}", email="${event.email}", mobile="${event.mobile}"',
      );
      emit(RegisterLoading());

      final result = await registerUseCase(
        name: event.name,
        email: event.email,
        mobile: event.mobile,
      );

      result.fold(
        (failure) {
          logger.e('❌ RegisterBloc: Registration failed — ${failure.message}');
          emit(RegisterFailure(failure.message));
        },
        (success) {
          logger.i(
            '✅ RegisterBloc: Registration successful — ${success.message}',
          );
          emit(RegisterSuccess(success.message));
        },
      );
    });
  }
}
