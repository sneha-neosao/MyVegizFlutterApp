import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecase/get_cms_page_usecase.dart';
import 'cms_page_event.dart';
import 'cms_page_state.dart';

class CmsPageBloc extends Bloc<CmsPageEvent, CmsPageState> {
  final GetCmsPageUseCase getCmsPageUseCase;

  CmsPageBloc({required this.getCmsPageUseCase}) : super(const CmsPageInitial()) {
    on<FetchCmsPageEvent>(_onFetchCmsPage);
  }

  void _onFetchCmsPage(
    FetchCmsPageEvent event,
    Emitter<CmsPageState> emit,
  ) async {
    logger.i("📄 CmsPageBloc: Fetching CMS Page: ${event.pageKey}");
    emit(const CmsPageLoading());

    final result = await getCmsPageUseCase(event.pageKey);

    result.fold(
      (failure) {
        logger.e("📄 CmsPageBloc: Fetch Failed -> ${failure.message}");
        emit(CmsPageError(failure.message));
      },
      (response) {
        final page = response.data;
        if (page == null) {
          logger.i("📄 CmsPageBloc: Fetch Success, but data is null");
          emit(const CmsPageEmpty());
        } else {
          logger.i("📄 CmsPageBloc: Fetch Success");
          emit(CmsPageLoaded(page));
        }
      },
    );
  }
}
