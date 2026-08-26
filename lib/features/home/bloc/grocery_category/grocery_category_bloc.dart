import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecase/get_grocery_categories_usecase.dart';
import 'grocery_category_event.dart';
import 'grocery_category_state.dart';

class GroceryCategoryBloc extends Bloc<GroceryCategoryEvent, GroceryCategoryState> {
  final GetGroceryCategoriesUseCase getGroceryCategoriesUseCase;

  GroceryCategoryBloc({required this.getGroceryCategoriesUseCase})
      : super(const GroceryCategoryInitial()) {
    on<FetchGroceryCategoriesEvent>(_onFetchGroceryCategories);
  }

  void _onFetchGroceryCategories(
    FetchGroceryCategoriesEvent event,
    Emitter<GroceryCategoryState> emit,
  ) async {
    // logger.i("🥬 GroceryCategoryBloc: Fetching Grocery Categories for ${event.mainCategorySlug}");
    emit(const GroceryCategoryLoading());

    final result = await getGroceryCategoriesUseCase(
      page: event.page,
      limit: event.limit,
      mainCategorySlug: event.mainCategorySlug,
    );

    result.fold(
      (failure) {
        // logger.e("🥬 GroceryCategoryBloc: Fetch Failed -> ${failure.message}");
        emit(GroceryCategoryError(failure.message));
      },
      (response) {
        final categories = response.data ?? [];
        if (categories.isEmpty) {
          // logger.i("🥬 GroceryCategoryBloc: Fetch Success, but list is empty");
          emit(const GroceryCategoryEmpty());
        } else {
          // logger.i("🥬 GroceryCategoryBloc: Fetch Success with ${categories.length} items");
          emit(GroceryCategoryLoaded(categories, event.mainCategorySlug));
        }
      },
    );
  }
}
