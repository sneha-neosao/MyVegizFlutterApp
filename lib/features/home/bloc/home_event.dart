abstract class HomeEvent {}

class LoadHomeEvent extends HomeEvent {
  final String mainCategorySlug;
  LoadHomeEvent({required this.mainCategorySlug});
}