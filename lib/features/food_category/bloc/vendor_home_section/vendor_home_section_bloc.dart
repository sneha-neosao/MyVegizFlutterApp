import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../data/domain/usecase/get_vendor_home_sections_usecase.dart';
import '../../data/domain/usecase/get_vendor_home_section_filters_usecase.dart';
import 'vendor_home_section_event.dart';
import 'vendor_home_section_state.dart';

class VendorHomeSectionBloc extends Bloc<VendorHomeSectionEvent, VendorHomeSectionState> {
  final GetVendorHomeSectionsUseCase getVendorHomeSectionsUseCase;
  final GetVendorHomeSectionFiltersUseCase getVendorHomeSectionFiltersUseCase;

  VendorHomeSectionBloc({
    required this.getVendorHomeSectionsUseCase,
    required this.getVendorHomeSectionFiltersUseCase,
  }) : super(VendorHomeSectionState.initial()) {
    on<FetchVendorHomeSectionsEvent>(_onFetchVendorHomeSections);
    on<FetchVendorHomeSectionFiltersEvent>(_onFetchVendorHomeSectionFilters);
  }

  void _onFetchVendorHomeSections(
    FetchVendorHomeSectionsEvent event,
    Emitter<VendorHomeSectionState> emit,
  ) async {
    emit(state.copyWith(isHomeSectionsLoading: true, homeSectionsError: null));

    final result = await getVendorHomeSectionsUseCase(
      lat: event.lat,
      lng: event.lng,
      sortBy: event.sortBy,
      foodType: event.foodType,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isHomeSectionsLoading: false,
            homeSectionsError: failure.message,
          ),
        );
      },
      (response) {
        emit(
          state.copyWith(
            isHomeSectionsLoading: false,
            homeSections: response.data ?? [],
          ),
        );
      },
    );
  }

  void _onFetchVendorHomeSectionFilters(
    FetchVendorHomeSectionFiltersEvent event,
    Emitter<VendorHomeSectionState> emit,
  ) async {
    emit(state.copyWith(isFiltersLoading: true, filtersError: null));

    final result = await getVendorHomeSectionFiltersUseCase();

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isFiltersLoading: false,
            filtersError: failure.message,
          ),
        );
      },
      (response) {
        emit(
          state.copyWith(
            isFiltersLoading: false,
            filters: response.data,
          ),
        );
      },
    );
  }
}
