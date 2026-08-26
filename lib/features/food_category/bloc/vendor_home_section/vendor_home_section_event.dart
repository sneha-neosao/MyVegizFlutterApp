import 'package:equatable/equatable.dart';

abstract class VendorHomeSectionEvent extends Equatable {
  const VendorHomeSectionEvent();

  @override
  List<Object?> get props => [];
}

class FetchVendorHomeSectionsEvent extends VendorHomeSectionEvent {
  final double lat;
  final double lng;
  final String? sortBy;
  final String? foodType;

  const FetchVendorHomeSectionsEvent({
    required this.lat,
    required this.lng,
    this.sortBy,
    this.foodType,
  });

  @override
  List<Object?> get props => [lat, lng, sortBy, foodType];
}

class FetchVendorHomeSectionFiltersEvent extends VendorHomeSectionEvent {
  const FetchVendorHomeSectionFiltersEvent();

  @override
  List<Object?> get props => [];
}
