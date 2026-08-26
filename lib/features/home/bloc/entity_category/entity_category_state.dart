import 'package:equatable/equatable.dart';
import '../../data/models/entity_category_model.dart';

abstract class EntityCategoryState extends Equatable {
  const EntityCategoryState();

  @override
  List<Object?> get props => [];
}

class EntityCategoryInitial extends EntityCategoryState {
  const EntityCategoryInitial();
}

class EntityCategoryLoading extends EntityCategoryState {
  const EntityCategoryLoading();
}

class EntityCategoryLoaded extends EntityCategoryState {
  final List<EntityCategoryModel> categories;

  const EntityCategoryLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class EntityCategoryEmpty extends EntityCategoryState {
  const EntityCategoryEmpty();
}

class EntityCategoryError extends EntityCategoryState {
  final String message;

  const EntityCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
