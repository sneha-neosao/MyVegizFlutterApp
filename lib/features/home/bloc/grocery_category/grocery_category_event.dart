import 'package:equatable/equatable.dart';

abstract class GroceryCategoryEvent extends Equatable {
  const GroceryCategoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchGroceryCategoriesEvent extends GroceryCategoryEvent {
  final String mainCategorySlug;
  final int page;
  final int limit;

  const FetchGroceryCategoriesEvent({
    this.mainCategorySlug = 'grocery-vegetables',
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [mainCategorySlug, page, limit];
}
