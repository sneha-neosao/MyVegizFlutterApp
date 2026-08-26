import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecase/product_details_usecase.dart';
import './product_details_event.dart';
import './product_details_state.dart';

class ProductDetailsBloc extends Bloc<ProductDetailsEvent, ProductDetailsState> {
  final ProductDetailsUseCase getProductDetailsUseCase;

  ProductDetailsBloc(this.getProductDetailsUseCase) : super(ProductDetailsInitial()) {
    on<FetchProductDetails>(_onFetchProductDetails);
  }

  Future<void> _onFetchProductDetails(
      FetchProductDetails event, Emitter<ProductDetailsState> emit) async {
    emit(ProductDetailsLoading());
    try {
      final productDetails = await getProductDetailsUseCase(
        slug: event.slug,
        lat: event.lat,
        lng: event.lng,
      );
      if (productDetails.data != null) {
        emit(ProductDetailsLoaded(productDetails));
      } else {
        emit(ProductDetailsError(productDetails.message ?? 'Product not found'));
      }
    } catch (e) {
      emit(ProductDetailsError(e.toString()));
    }
  }
}
