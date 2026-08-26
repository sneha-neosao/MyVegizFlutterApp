import 'cart_bloc.dart';

class FoodCartBloc extends CartBloc {
  FoodCartBloc({
    required super.addToCartUseCase,
    required super.getCartListUseCase,
    required super.updateCartUseCase,
    required super.clearCartUseCase,
    required super.validateAddressUseCase,
    required super.removeCartItemUseCase,
    required super.getAvailableCouponsUseCase,
    required super.applyCouponUseCase,
    required super.removeCouponUseCase,
    required super.validateCouponUseCase,
  }) : super(isFood: true);
}
