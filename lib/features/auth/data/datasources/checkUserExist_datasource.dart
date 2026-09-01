import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../../../../core/utils/logger.dart';
import '../models/checkUserExist_model.dart';

class CheckUserExistRemoteDataSource {
  final ApiHelper apiHelper;

  CheckUserExistRemoteDataSource(this.apiHelper);

  Future<CheckUserExistModel> checkUserExist(String mobile) async {
    final formattedMobile = mobile.startsWith("+91")
        ? mobile.substring(3)
        : mobile.replaceAll(RegExp(r'\s+'), '');

    logger.i("🌐 API CALL → Check User Exist");
    logger.d("URL: ${ApiUrl.checkUserExist}");
    logger.d("BODY: {mobile: $formattedMobile}");

    final response = await apiHelper.execute(
      method: Method.post,
      url: ApiUrl.checkUserExist,
      data: {"mobile": formattedMobile},
    );

    logger.i("📡 API RESPONSE → Check User Exist");

    return CheckUserExistModel.fromJson(response);
  }
}
