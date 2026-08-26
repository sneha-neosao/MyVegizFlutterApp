import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import '../../data/models/homePage_model.dart';
import '../../usecases/homePage_usecase.dart';
import './homePage_event.dart';
import './homePage_state.dart';

class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  final HomePageUseCase homePageUseCase;

  HomePageModel? _cachedModel;

  HomePageBloc(this.homePageUseCase) : super(HomePageInitial()) {
    on<FetchHomePageData>(_onFetchHomePageData);
  }

  void _onFetchHomePageData(
    FetchHomePageData event,
    Emitter<HomePageState> emit,
  ) async {
    // logger.i("🏠 HomePageBloc: Fetching data for ${event.mainCategorySlug} (Tab: ${event.homeTabSlug ?? 'All'}) Query: ${event.q ?? ''}");
    
    if (_cachedModel == null && state is! HomePageLoaded) {
      emit(HomePageLoading());
    }

    final result = await homePageUseCase(
      mainCategorySlug: event.mainCategorySlug,
      homeTabSlug: event.homeTabSlug,
      lat: event.lat,
      lng: event.lng,
      q: event.q,
    );

    result.fold(
      (failure) {
        logger.e("🏠 HomePageBloc ERROR: ${failure.message}");
        emit(HomePageError(failure.message));
      },
      (newData) {
        // logger.d("🏠 HomePageBloc: Received data successfully");
        final hasQuery = event.q != null && event.q!.isNotEmpty;
        
        if (hasQuery) {
          emit(HomePageLoaded(newData));
        } else {
          // 🧠 FIRST TIME (without slug)
          if (event.homeTabSlug == null || event.homeTabSlug!.isEmpty) {
            _cachedModel = newData;
          } else {
            // 🧠 MERGE LOGIC
            final List<HomeTabModel> oldTabs = List.from(_cachedModel?.data?.homeTabs ?? []);
            final newTabs = newData.data?.homeTabs ?? [];

            if (newTabs.isNotEmpty) {
              final updatedTab = newTabs.first;

              bool found = false;
              for (int i = 0; i < oldTabs.length; i++) {
                if (oldTabs[i].slug == updatedTab.slug) {
                  oldTabs[i] = updatedTab; // 🔥 replace with full data
                  found = true;
                  break;
                }
              }
              if (!found) {
                oldTabs.add(updatedTab);
              }
            }

            _cachedModel = HomePageModel(
              status: newData.status,
              message: newData.message,
              data: HomePageData(
                mainCategory: newData.data?.mainCategory ?? _cachedModel?.data?.mainCategory,
                homeTabs: oldTabs,
              ),
            );
          }

          emit(HomePageLoaded(_cachedModel!));
        }
      },
    );
  }
}
