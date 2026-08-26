import '../../grocery_subCtegory/data/models/homePage_model.dart';
import '../../mainCetegories/data/models/mainCategory_model.dart';

abstract class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<ProductModel> products;
  final Pagination? pagination;
  final String query;
  final bool hasReachedMax;
  final bool isPaginating;

  const SearchLoaded({
    required this.products,
    this.pagination,
    required this.query,
    this.hasReachedMax = false,
    this.isPaginating = false,
  });

  SearchLoaded copyWith({
    List<ProductModel>? products,
    Pagination? pagination,
    String? query,
    bool? hasReachedMax,
    bool? isPaginating,
  }) {
    return SearchLoaded(
      products: products ?? this.products,
      pagination: pagination ?? this.pagination,
      query: query ?? this.query,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isPaginating: isPaginating ?? this.isPaginating,
    );
  }
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);
}
