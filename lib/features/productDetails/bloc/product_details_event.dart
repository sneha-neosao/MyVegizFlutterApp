abstract class ProductDetailsEvent {}

class FetchProductDetails extends ProductDetailsEvent {
  final String slug;
  final double? lat;
  final double? lng;

  FetchProductDetails(this.slug, {this.lat, this.lng});
}
