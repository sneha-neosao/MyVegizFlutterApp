import 'package:equatable/equatable.dart';
import '../../data/models/vendor_home_section_model.dart';

class VendorHomeSectionState extends Equatable {
  final bool isHomeSectionsLoading;
  final List<VendorHomeSection> homeSections;
  final String? homeSectionsError;
  final VendorHomeSectionFiltersData? filters;
  final bool isFiltersLoading;
  final String? filtersError;

  const VendorHomeSectionState({
    required this.isHomeSectionsLoading,
    required this.homeSections,
    this.homeSectionsError,
    this.filters,
    required this.isFiltersLoading,
    this.filtersError,
  });

  factory VendorHomeSectionState.initial() {
    return const VendorHomeSectionState(
      isHomeSectionsLoading: false,
      homeSections: [],
      homeSectionsError: null,
      filters: null,
      isFiltersLoading: false,
      filtersError: null,
    );
  }

  VendorHomeSectionState copyWith({
    bool? isHomeSectionsLoading,
    List<VendorHomeSection>? homeSections,
    String? homeSectionsError,
    VendorHomeSectionFiltersData? filters,
    bool? isFiltersLoading,
    String? filtersError,
  }) {
    return VendorHomeSectionState(
      isHomeSectionsLoading: isHomeSectionsLoading ?? this.isHomeSectionsLoading,
      homeSections: homeSections ?? this.homeSections,
      homeSectionsError: homeSectionsError ?? this.homeSectionsError,
      filters: filters ?? this.filters,
      isFiltersLoading: isFiltersLoading ?? this.isFiltersLoading,
      filtersError: filtersError ?? this.filtersError,
    );
  }

  @override
  List<Object?> get props => [
        isHomeSectionsLoading,
        homeSections,
        homeSectionsError,
        filters,
        isFiltersLoading,
        filtersError,
      ];
}
