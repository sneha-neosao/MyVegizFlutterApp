import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/register_model.dart';
import '../../../../core/utils/logger.dart';

abstract class RegisterRemoteDataSource {
  Future<RegisterModel> register({
    required String name,
    required String email,
    required String mobile,
  });
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  final ApiHelper apiHelper;

  RegisterRemoteDataSourceImpl(this.apiHelper);

  @override
  Future<RegisterModel> register({
    required String name,
    required String email,
    required String mobile,
  }) async {
    final formattedMobile = mobile.startsWith("+91")
        ? mobile.substring(3)
        : mobile;

    logger.i("🌐 API CALL → Register");
    logger.d("URL: ${ApiUrl.register}");
    logger.d("BODY: name=$name email=$email mobile=$formattedMobile");

    final response = await apiHelper.execute(
      method: Method.post,
      url: ApiUrl.register,
      data: {"name": name, "email": email, "contact": formattedMobile},
    );

    return RegisterModel.fromJson(response);
  }
}
