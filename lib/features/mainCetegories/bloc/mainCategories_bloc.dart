import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../domain/usecase/mainCategories_usecase.dart';
import './mainCategories_event.dart';
import './mainCategories_state.dart';

class MainCategoriesBloc
    extends Bloc<MainCategoriesEvent, MainCategoriesState> {
  final MainCategoriesUseCase useCase;

  MainCategoriesBloc(this.useCase) : super(MainCategoriesInitial()) {
    on<FetchMainCategories>((event, emit) async {
      // logger.i("🚀 MainCategoriesBloc Triggered");

      emit(MainCategoriesLoading());

      final res = await useCase(page: event.page, limit: event.limit);

      res.fold(
        (failure) {
          // logger.e("❌ MainCategories Failed: ${failure.message}");
          emit(MainCategoriesError(failure.message));
        },
        (data) {
          // logger.i("✅ MainCategories Success");
          emit(MainCategoriesLoaded(data));
        },
      );
    });
  }
}
