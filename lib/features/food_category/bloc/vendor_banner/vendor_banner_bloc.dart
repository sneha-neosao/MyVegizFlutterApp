import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../data/domain/usecase/get_vendor_banners_usecase.dart';
import 'vendor_banner_event.dart';
import 'vendor_banner_state.dart';

class VendorBannerBloc extends Bloc<VendorBannerEvent, VendorBannerState> {
  final GetVendorBannersUseCase getVendorBannersUseCase;

  VendorBannerBloc({required this.getVendorBannersUseCase})
    : super(VendorBannerState.initial()) {
    on<FetchVendorBannersEvent>(_onFetchVendorBanners);
  }

  void _onFetchVendorBanners(
    FetchVendorBannersEvent event,
    Emitter<VendorBannerState> emit,
  ) async {
    emit(state.copyWith(isBannersLoading: true, bannersError: null));

    final result = await getVendorBannersUseCase(lat: event.lat, lng: event.lng);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isBannersLoading: false,
            bannersError: failure.message,
          ),
        );
      },
      (response) {
        emit(
          state.copyWith(isBannersLoading: false, banners: response.data ?? []),
        );
      },
    );
  }
}
