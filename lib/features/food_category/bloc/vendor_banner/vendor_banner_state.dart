import '../../data/models/vendor_banner_model.dart';

class VendorBannerState {
  final bool isBannersLoading;
  final List<VendorBannerModel> banners;
  final String? bannersError;

  VendorBannerState({
    required this.isBannersLoading,
    required this.banners,
    this.bannersError,
  });

  factory VendorBannerState.initial() {
    return VendorBannerState(
      isBannersLoading: false,
      banners: [],
      bannersError: null,
    );
  }

  VendorBannerState copyWith({
    bool? isBannersLoading,
    List<VendorBannerModel>? banners,
    String? bannersError,
  }) {
    return VendorBannerState(
      isBannersLoading: isBannersLoading ?? this.isBannersLoading,
      banners: banners ?? this.banners,
      bannersError: bannersError ?? this.bannersError,
    );
  }
}
