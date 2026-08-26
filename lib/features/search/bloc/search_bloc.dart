import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecases/search_products_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchProductsUseCase searchProductsUseCase;
  int _currentPage = 1;

  SearchBloc({required this.searchProductsUseCase}) : super(const SearchInitial()) {
    on<SearchQueryChangedEvent>(_onQueryChanged);
    on<SearchLoadMoreEvent>(_onLoadMore);
    on<SearchClearEvent>(_onClear);
  }

  Future<void> _onQueryChanged(
    SearchQueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      _currentPage = 1;
      emit(const SearchInitial());
      return;
    }

    _currentPage = 1;
    emit(const SearchLoading());

    final result = await searchProductsUseCase(
      query: query,
      lat: event.lat,
      lng: event.lng,
      page: 1,
      limit: 20,
    );

    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (response) {
        final products = response.products ?? [];
        final pagination = response.pagination;
        final totalPages = pagination?.totalPages ?? 1;
        final hasReachedMax = _currentPage >= totalPages;

        emit(
          SearchLoaded(
            products: products,
            pagination: pagination,
            query: query,
            hasReachedMax: hasReachedMax,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMore(
    SearchLoadMoreEvent event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SearchLoaded || currentState.hasReachedMax || currentState.isPaginating) {
      return;
    }

    emit(currentState.copyWith(isPaginating: true));
    final nextPage = _currentPage + 1;

    final result = await searchProductsUseCase(
      query: currentState.query,
      lat: event.lat,
      lng: event.lng,
      page: nextPage,
      limit: 20,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isPaginating: false)),
      (response) {
        final newProducts = response.products ?? [];
        final pagination = response.pagination;
        _currentPage = nextPage;
        final totalPages = pagination?.totalPages ?? nextPage;
        final hasReachedMax = _currentPage >= totalPages;

        emit(
          currentState.copyWith(
            products: [...currentState.products, ...newProducts],
            pagination: pagination,
            hasReachedMax: hasReachedMax,
            isPaginating: false,
          ),
        );
      },
    );
  }

  void _onClear(SearchClearEvent event, Emitter<SearchState> emit) {
    _currentPage = 1;
    emit(const SearchInitial());
  }
}
