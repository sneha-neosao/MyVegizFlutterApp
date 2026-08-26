import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/food_order_model.dart';
import '../../data/repository/food_order_repo.dart';

class GetFoodOrdersListUseCase {
  final FoodOrderRepository repository;

  GetFoodOrdersListUseCase(this.repository);

  Future<Either<Failure, FoodOrderListResponse>> execute() async {
    return await repository.getFoodOrdersList();
  }
}

class GetFoodOrderDetailsUseCase {
  final FoodOrderRepository repository;

  GetFoodOrderDetailsUseCase(this.repository);

  Future<Either<Failure, FoodOrderDetailsModel>> execute(String uuId) async {
    return await repository.getFoodOrderDetails(uuId);
  }
}

class PlaceFoodOrderUseCase {
  final FoodOrderRepository repository;

  PlaceFoodOrderUseCase(this.repository);

  Future<Either<Failure, FoodOrderDetailsModel>> execute({
    required int vendorId,
    required String customerUuid,
    required String addressUuid,
    String? couponCode,
    int? applyWalletPoints,
    required String paymentMode,
    String? customerNote,
    required List<Map<String, dynamic>> items,
  }) async {
    return await repository.placeFoodOrder(
      vendorId: vendorId,
      customerUuid: customerUuid,
      addressUuid: addressUuid,
      couponCode: couponCode,
      applyWalletPoints: applyWalletPoints,
      paymentMode: paymentMode,
      customerNote: customerNote,
      items: items,
    );
  }
}

class CancelFoodOrderUseCase {
  final FoodOrderRepository repository;

  CancelFoodOrderUseCase(this.repository);

  Future<Either<Failure, FoodCancelOrderResponseModel>> execute(String uuId, String note) async {
    return await repository.cancelFoodOrder(uuId, note);
  }
}

class GetAvailableFoodCouponsUseCase {
  final FoodOrderRepository repository;

  GetAvailableFoodCouponsUseCase(this.repository);

  Future<Either<Failure, List<dynamic>>> execute(String vendorUuid) async {
    return await repository.getAvailableFoodCoupons(vendorUuid);
  }
}
