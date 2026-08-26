abstract class HomePageEvent {}

class FetchHomePageData extends HomePageEvent {
  final String mainCategorySlug;
  final String? homeTabSlug;
  final double lat;
  final double lng;
  final String? q;

  FetchHomePageData({
    required this.mainCategorySlug,
    this.homeTabSlug,
    required this.lat,
    required this.lng,
    this.q,
  });
}
