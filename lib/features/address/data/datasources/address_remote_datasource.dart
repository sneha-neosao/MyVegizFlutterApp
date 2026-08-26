import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/address_model.dart';
import '../../../../core/utils/logger.dart';

abstract class AddressRemoteDataSource {
  Future<AddressListResponse> getAddressList();
  Future<AddressModel> addAddress(AddressModel address);
  Future<AddressModel> updateAddress(String uuId, AddressModel address);
  Future<String> deleteAddress(String uuId);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final ApiHelper apiHelper;

  AddressRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<AddressListResponse> getAddressList() async {
    try {
      logger.i("🌐 API CALL → Address List");
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.addressList,
      );

      final data = response['data'];
      if (data == null) {
        logger.w("⚠️ API WARNING: Address List returned null data");
        return AddressListResponse(total: 0, addresses: []);
      }

      return AddressListResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      logger.e("Error fetching addresses: $e");
      rethrow;
    }
  }

  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    try {
      logger.i("🌐 API CALL → Add Address");
      final response = await apiHelper.execute(
        method: Method.post,
        url: ApiUrl.addAddress,
        data: address.toJson(),
      );

      final data = response['data'];
      final message = response['message'];
      if (data == null) {
        throw Exception("Server returned null data for added address");
      }

      return AddressModel.fromJson(data as Map<String, dynamic>, message: message);
    } catch (e) {
      logger.e("Error adding address: $e");
      rethrow;
    }
  }

  @override
  Future<AddressModel> updateAddress(String uuId, AddressModel address) async {
    try {
      logger.i("🌐 API CALL → Update Address: $uuId");
      final response = await apiHelper.execute(
        method: Method.put,
        url: ApiUrl.updateAddress(uuId),
        data: address.toJson(),
      );

      final data = response['data'];
      final message = response['message'];
      if (data == null) {
        throw Exception("Server returned null data for updated address");
      }

      return AddressModel.fromJson(data as Map<String, dynamic>, message: message);
    } catch (e) {
      logger.e("Error updating address: $e");
      rethrow;
    }
  }

  @override
  Future<String> deleteAddress(String uuId) async {
    try {
      logger.i("🌐 API CALL → Delete Address: $uuId");
      final response = await apiHelper.execute(
        method: Method.delete,
        url: ApiUrl.deleteAddress(uuId),
      );

      return response['message'] ?? 'Address deleted successfully';
    } catch (e) {
      logger.e("Error deleting address: $e");
      rethrow;
    }
  }
}
