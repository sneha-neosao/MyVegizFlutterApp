class HomeTab {
  final String slug;
  final String tabName;

  HomeTab({required this.slug, required this.tabName});

  factory HomeTab.fromJson(Map<String, dynamic> json) {
    return HomeTab(slug: json['slug'] ?? '', tabName: json['tabName'] ?? '');
  }
}
