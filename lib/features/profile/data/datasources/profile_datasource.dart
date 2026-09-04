import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  /// GET /web/profile/list
  Future<ProfileResponse> getProfile();

  /// PUT /web/profile/update — multipart (name, email, contact, profile_image)
  Future<ProfileModel> updateProfile({
    required String name,
    required String email,
    required String contact,
    File? profileImage,
  });

  /// DELETE /web/profile/delete
  Future<String> deleteAccount();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiHelper apiHelper;

  ProfileRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<ProfileResponse> getProfile() async {
    try {
      logger.i('🌐 API CALL → Get Profile (URL: ${ApiUrl.getProfile})');
      final response = await apiHelper.execute(
        method: Method.get,
        url: ApiUrl.getProfile,
      );
      logger.i('📡 API RESPONSE Get Profile status: ${response['status']}');
      return ProfileResponse.fromJson(response);
    } catch (e) {
      logger.e('❌ API ERROR → Get Profile: $e');
      rethrow;
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    required String name,
    required String email,
    required String contact,
    File? profileImage,
  }) async {
    try {
      logger.i('🌐 API CALL → Update Profile');

      // Build multipart form data (required because profile_image is a file)
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'contact': contact,
        if (profileImage != null)
          'profile_image': await MultipartFile.fromFile(
            profileImage.path,
            filename: profileImage.path.split('/').last,
          ),
      });

      final response = await apiHelper.execute(
        method: Method.put,
        url: ApiUrl.updateProfile,
        data: formData,
      );

      final data = response['data'];
      final message = response['message'] as String? ?? 'Profile updated successfully';
      if (data == null) {
        throw Exception('Server returned null data for profile update');
      }

      return ProfileModel.fromJson(data as Map<String, dynamic>, message: message);
    } catch (e) {
      logger.e('Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<String> deleteAccount() async {
    try {
      logger.i('🌐 API CALL → Delete Account');
      final response = await apiHelper.execute(
        method: Method.delete,
        url: ApiUrl.deleteAccount,
      );
      return response['message'] as String? ?? 'Account deleted successfully';
    } catch (e) {
      logger.e('Error deleting account: $e');
      rethrow;
    }
  }
}
