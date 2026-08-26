import 'dart:async';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/features/address/data/models/places_model.dart';
import 'package:my_vegiz_flutter/features/address/domain/usecase/places_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class PlacesEvent {}

/// Fired on every text change in the search field (debounced in the BLoC).
class SearchPlacesEvent extends PlacesEvent {
  final String query;
  SearchPlacesEvent(this.query);
}

/// Fired when the user taps a suggestion.
class SelectPlaceEvent extends PlacesEvent {
  final String placeId;
  SelectPlaceEvent(this.placeId);
}

/// Fired to dismiss suggestions (empty query, back, clear button).
class ClearSuggestionsEvent extends PlacesEvent {}

// ── States ────────────────────────────────────────────────────────────────────

abstract class PlacesState {}

class PlacesInitial extends PlacesState {}

class PlacesLoading extends PlacesState {}

class PlacesSuggested extends PlacesState {
  final List<PlacesSuggestion> suggestions;
  PlacesSuggested(this.suggestions);
}

class PlaceSelected extends PlacesState {
  final PlaceDetails details;
  PlaceSelected(this.details);
}

class PlacesError extends PlacesState {
  final String message;
  PlacesError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class PlacesBloc extends Bloc<PlacesEvent, PlacesState> {
  final SearchPlacesUseCase searchPlacesUseCase;
  final GetPlaceDetailsUseCase getPlaceDetailsUseCase;

  /// Debounce timer — prevents an API call on every single keystroke.
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 350);

  PlacesBloc({
    required this.searchPlacesUseCase,
    required this.getPlaceDetailsUseCase,
  }) : super(PlacesInitial()) {
    on<SearchPlacesEvent>(_onSearch);
    on<SelectPlaceEvent>(_onSelect);
    on<ClearSuggestionsEvent>(_onClear);
  }

  Future<void> _onSearch(
    SearchPlacesEvent event,
    Emitter<PlacesState> emit,
  ) async {
    _debounce?.cancel();

    final query = event.query.trim();
    if (query.isEmpty) {
      emit(PlacesInitial());
      return;
    }

    // Emit loading immediately so the UI can show a subtle spinner.
    emit(PlacesLoading());

    // Wait for the debounce window before hitting the API.
    final completer = Completer<void>();
    _debounce = Timer(_debounceDuration, () => completer.complete());
    await completer.future;

    if (isClosed) return;

    logger.i('🗺️ PlacesBloc: Searching for "$query"');

    final result = await searchPlacesUseCase(query);
    result.fold(
      (failure) {
        logger.e('🗺️ PlacesBloc SearchError: ${failure.message}');
        emit(PlacesError(failure.message));
      },
      (suggestions) {
        logger.i('🗺️ PlacesBloc: ${suggestions.length} suggestions returned');
        emit(PlacesSuggested(suggestions));
      },
    );
  }

  Future<void> _onSelect(
    SelectPlaceEvent event,
    Emitter<PlacesState> emit,
  ) async {
    _debounce?.cancel();
    emit(PlacesLoading());

    logger.i('🗺️ PlacesBloc: Fetching details for placeId ${event.placeId}');

    final result = await getPlaceDetailsUseCase(event.placeId);
    result.fold(
      (failure) {
        logger.e('🗺️ PlacesBloc SelectError: ${failure.message}');
        emit(PlacesError(failure.message));
      },
      (details) {
        logger.i(
          '🗺️ PlacesBloc: Place selected — ${details.formattedAddress}',
        );
        emit(PlaceSelected(details));
      },
    );
  }

  void _onClear(ClearSuggestionsEvent event, Emitter<PlacesState> emit) {
    _debounce?.cancel();
    emit(PlacesInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
