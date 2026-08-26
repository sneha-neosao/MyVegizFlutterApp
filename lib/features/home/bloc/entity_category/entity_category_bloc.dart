import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecase/get_entity_categories_usecase.dart';
import 'entity_category_event.dart';
import 'entity_category_state.dart';

class EntityCategoryBloc extends Bloc<EntityCategoryEvent, EntityCategoryState> {
  final GetEntityCategoriesUseCase getEntityCategoriesUseCase;

  EntityCategoryBloc({required this.getEntityCategoriesUseCase})
      : super(const EntityCategoryInitial()) {
    on<FetchEntityCategoriesEvent>(_onFetchEntityCategories);
  }

  void _onFetchEntityCategories(
    FetchEntityCategoriesEvent event,
    Emitter<EntityCategoryState> emit,
  ) async {
    // logger.i("🍔 EntityCategoryBloc: Fetching Entity Categories");
    emit(const EntityCategoryLoading());

    final result = await getEntityCategoriesUseCase();

    result.fold(
      (failure) {
        // logger.e("🍔 EntityCategoryBloc: Fetch Entity Categories Failed -> ${failure.message}");
        emit(EntityCategoryError(failure.message));
      },
      (response) {
        final categories = response.data ?? [];
        if (categories.isEmpty) {
          // logger.i("🍔 EntityCategoryBloc: Fetch Success, but list is empty");
          emit(const EntityCategoryEmpty());
        } else {
          // logger.i("🍔 EntityCategoryBloc: Fetch Success with ${categories.length} items");
          emit(EntityCategoryLoaded(categories));
        }
      },
    );
  }
}
