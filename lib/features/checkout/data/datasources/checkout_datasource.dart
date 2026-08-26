import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';

abstract class CheckoutRemoteDataSource {
  Future<Map<String, dynamic>> getAvailableSlots();
  Future<Map<String, dynamic>> getOrderSettings();
  Future<Map<String, dynamic>> placeOrder({
    required String paymentMode,
    required String addressUuid,
    String? slotUuid,
    String? customerNote,
  });
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final ApiHelper _apiHelper;

  CheckoutRemoteDataSourceImpl(this._apiHelper);

  @override
  Future<Map<String, dynamic>> getAvailableSlots() async {
    logger.i("🌐 API CALL → Get Available Slots");
    return await _apiHelper.execute(
      method: Method.get,
      url: ApiUrl.slotsAvailable,
    );
  }

  @override
  Future<Map<String, dynamic>> getOrderSettings() async {
    logger.i("🌐 API CALL → Get Order Settings");
    return await _apiHelper.execute(
      method: Method.get,
      url: ApiUrl.orderSettingsList,
    );
  }

  @override
  Future<Map<String, dynamic>> placeOrder({
    required String paymentMode,
    required String addressUuid,
    String? slotUuid,
    String? customerNote,
  }) async {
    logger.i("🌐 API CALL → Place Order");
    
    final data = {
      "payment_mode": paymentMode,
      "address_uu_id": addressUuid,
      if (slotUuid != null && slotUuid.isNotEmpty) "slot_uu_id": slotUuid,
      if (customerNote != null && customerNote.isNotEmpty)
        "customer_note": customerNote,
    };

    return await _apiHelper.execute(
      method: Method.post,
      url: ApiUrl.placeOrder,
      data: data,
    );
  }
}
