import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/verifyOtp_model.dart';

class VerifyOtpRemoteDataSource {
  final ApiHelper apiHelper;

  VerifyOtpRemoteDataSource(this.apiHelper);

  Future<VerifyOtpModel> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    logger.i("🌐 API CALL → Verify OTP");
    logger.d("URL: ${ApiUrl.verifyOtp}");
    logger.d("BODY: {mobile: $mobile, otp: $otp}");

    final response = await apiHelper.execute(
      method: Method.post,
      url: ApiUrl.verifyOtp,
      data: {"mobile": mobile, "otp": otp},
    );

    logger.i("📡 API RESPONSE");

    return VerifyOtpModel.fromJson(response);
  }
}
