import 'package:equatable/equatable.dart';

abstract class EntityCategoryEvent extends Equatable {
  const EntityCategoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchEntityCategoriesEvent extends EntityCategoryEvent {
  const FetchEntityCategoriesEvent();
}
