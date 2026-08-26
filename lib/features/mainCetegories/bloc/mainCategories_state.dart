import '../data/models/mainCategory_model.dart';

abstract class MainCategoriesState {}

class MainCategoriesInitial extends MainCategoriesState {}

class MainCategoriesLoading extends MainCategoriesState {}

class MainCategoriesLoaded extends MainCategoriesState {
  final MainCategoryModel data;

  MainCategoriesLoaded(this.data);
}

class MainCategoriesError extends MainCategoriesState {
  final String message;

  MainCategoriesError(this.message);
}
