abstract class VendorBannerEvent {}

class FetchVendorBannersEvent extends VendorBannerEvent {
  final double? lat;
  final double? lng;

  FetchVendorBannersEvent({this.lat, this.lng});
}
