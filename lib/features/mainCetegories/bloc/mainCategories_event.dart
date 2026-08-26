abstract class MainCategoriesEvent {}

class FetchMainCategories extends MainCategoriesEvent {
  final int page;
  final int limit;

  FetchMainCategories({this.page = 1, this.limit = 10});
}
