
import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/sendOtp_model.dart';

class SendOtpRemoteDataSource {
  final ApiHelper apiHelper;

  SendOtpRemoteDataSource(this.apiHelper);

  Future<SendOtpModel> sendOtp(String mobile) async {
    final response = await apiHelper.execute(
      method: Method.post,
      url: ApiUrl.sendOtp,
      data: {
        "mobile": mobile,
      },
    );

    return SendOtpModel.fromJson(response);
  }
}