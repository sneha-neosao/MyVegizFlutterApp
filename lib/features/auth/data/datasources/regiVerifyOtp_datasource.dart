import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/regiVerifyOtp_model.dart';
import '../../../../core/utils/logger.dart';

abstract class RegiVerifyOtpDataSource {
  Future<RegiVerifyOtpModel> verifyOtp({
    required String mobile,
    required String otp,
  });
}

class RegiVerifyOtpDataSourceImpl implements RegiVerifyOtpDataSource {
  final ApiHelper apiHelper;

  RegiVerifyOtpDataSourceImpl(this.apiHelper);

  @override
  Future<RegiVerifyOtpModel> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    logger.i("🌐 API CALL → Register Verify OTP");
    logger.d("URL: ${ApiUrl.regiVerifyOtp}");
    logger.d("BODY: mobile=$mobile otp=$otp");

    final response = await apiHelper.execute(
      method: Method.post,
      url: ApiUrl.regiVerifyOtp,
      data: {"mobile": mobile, "otp": otp},
    );

    return RegiVerifyOtpModel.fromJson(response);
  }
}
