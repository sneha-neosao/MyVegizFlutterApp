abstract class SearchEvent {
  const SearchEvent();
}

class SearchQueryChangedEvent extends SearchEvent {
  final String query;
  final double? lat;
  final double? lng;

  const SearchQueryChangedEvent({
    required this.query,
    this.lat,
    this.lng,
  });
}

class SearchLoadMoreEvent extends SearchEvent {
  final double? lat;
  final double? lng;

  const SearchLoadMoreEvent({this.lat, this.lng});
}

class SearchClearEvent extends SearchEvent {
  const SearchClearEvent();
}
