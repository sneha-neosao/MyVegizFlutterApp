import 'package:fpdart/fpdart.dart';
import 'package:my_vegiz_flutter/core/errors/failures.dart';

import '../datasources/checkout_datasource.dart';
import '../models/checkout_model.dart';
import '../../../../core/utils/logger.dart';

abstract class CheckoutRepository {
  Future<Either<Failure, List<SlotModel>>> getAvailableSlots();
  Future<Either<Failure, OrderSettingsModel>> getOrderSettings();
  Future<Either<Failure, PlaceOrderResponseModel>> placeOrder({
    required String paymentMode,
    required String addressUuid,
    String? slotUuid,
    String? customerNote,
  });
}

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutRemoteDataSource _remoteDataSource;

  CheckoutRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<SlotModel>>> getAvailableSlots() async {
    try {
      final response = await _remoteDataSource.getAvailableSlots();
      if (response['status'] == 200 || response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final List<SlotModel> slots = data
            .map((e) => SlotModel.fromJson(e))
            .toList();
        return Right(slots);
      } else {
        return Left(
          ServerFailure(response['message'] ?? 'Failed to fetch slots'),
        );
      }
    } catch (e) {
      logger.e('Error fetching slots: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderSettingsModel>> getOrderSettings() async {
    try {
      final response = await _remoteDataSource.getOrderSettings();
      if (response['status'] == 200 || response['status'] == true) {
        final data = response['data'];
        return Right(OrderSettingsModel.fromJson(data));
      } else {
        return Left(
          ServerFailure(response['message'] ?? 'Failed to fetch settings'),
        );
      }
    } catch (e) {
      logger.e('Error fetching settings: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaceOrderResponseModel>> placeOrder({
    required String paymentMode,
    required String addressUuid,
    String? slotUuid,
    String? customerNote,
  }) async {
    try {
      final response = await _remoteDataSource.placeOrder(
        paymentMode: paymentMode,
        addressUuid: addressUuid,
        slotUuid: slotUuid,
        customerNote: customerNote,
      );
      if (response['status'] == 200 || response['status'] == true) {
        final data = response['data'];
        return Right(PlaceOrderResponseModel.fromJson(data));
      } else {
        return Left(
          ServerFailure(response['message'] ?? 'Failed to place order'),
        );
      }
    } catch (e) {
      logger.e('Error placing order: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
