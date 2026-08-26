import 'package:equatable/equatable.dart';
import '../../data/models/grocery_category_model.dart';

abstract class GroceryCategoryState extends Equatable {
  const GroceryCategoryState();

  @override
  List<Object?> get props => [];
}

class GroceryCategoryInitial extends GroceryCategoryState {
  const GroceryCategoryInitial();
}

class GroceryCategoryLoading extends GroceryCategoryState {
  const GroceryCategoryLoading();
}

class GroceryCategoryLoaded extends GroceryCategoryState {
  final List<GroceryCategoryModel> categories;
  final String mainCategorySlug;

  const GroceryCategoryLoaded(this.categories, this.mainCategorySlug);

  @override
  List<Object?> get props => [categories, mainCategorySlug];
}

class GroceryCategoryEmpty extends GroceryCategoryState {
  const GroceryCategoryEmpty();
}

class GroceryCategoryError extends GroceryCategoryState {
  final String message;

  const GroceryCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
