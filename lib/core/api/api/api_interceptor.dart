import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import '../../utils/logger.dart';
import './api_url.dart';

/// Dio interceptor that:
///  - Attaches the Bearer token to every request.
///  - Logs requests and errors.
///  - Attempts a token refresh on 401 responses.
class ApiInterceptor extends Interceptor {
  final Dio dio;

  ApiInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      logger.d('🔑 ApiInterceptor: Token attached to ${options.method} ${options.uri}');
    } else {
      logger.w('🔑 ApiInterceptor: No token — sending unauthenticated ${options.method} ${options.uri}');
    }

    options.baseUrl = ApiUrl.baseUrl;
    logger.i('➡️ ApiInterceptor: ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    logger.i(
      '⬅️ ApiInterceptor: ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
    );

    // Handle internal 401 status even if HTTP status is 200
    if (response.data is Map<String, dynamic> && response.data['status'] == 401) {
      logger.w(
        '🔄 ApiInterceptor: Internal 401 detected in response body — attempting token refresh...',
      );
      final refreshed = await _refreshToken();

      if (refreshed) {
        final newToken = await SecureStorage.getAccessToken();
        logger.i('✅ ApiInterceptor: Token refreshed — retrying original request');

        final opts = response.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';

        try {
          final retryResponse = await dio.fetch(opts);
          return handler.resolve(retryResponse);
        } catch (e) {
          logger.e('❌ ApiInterceptor: Retry after refresh failed — $e');
          return handler.next(response);
        }
      } else {
        logger.e('❌ ApiInterceptor: Token refresh failed — clearing session');
        await SecureStorage.clearAll();
      }
    }

    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    logger.e(
      '❌ ApiInterceptor: ERROR ${err.response?.statusCode} — ${err.message} [${err.requestOptions.method} ${err.requestOptions.uri}]',
    );

    if (err.response?.statusCode == 401) {
      logger.w('🔄 ApiInterceptor: 401 detected — attempting token refresh...');
      final refreshed = await _refreshToken();

      if (refreshed) {
        final newToken = await SecureStorage.getAccessToken();
        logger.i('✅ ApiInterceptor: Token refreshed — retrying original request');

        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';

        final response = await dio.fetch(opts);
        return handler.resolve(response);
      } else {
        logger.e('❌ ApiInterceptor: Token refresh failed — clearing session');
        await SecureStorage.clearAll();
      }
    }

    return handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        logger.w('🔄 ApiInterceptor: No refresh token available');
        return false;
      }

      logger.d('🔄 ApiInterceptor: Calling refresh token endpoint');
      final response = await dio.post(
        '${ApiUrl.baseUrl}/auth/refresh',
        data: {'refresh': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String?;
      final newRefreshToken = response.data['refresh_token'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        logger.e('❌ ApiInterceptor: Refresh response missing tokens');
        return false;
      }

      await SecureStorage.saveAccessToken(newAccessToken);
      await SecureStorage.saveRefreshToken(newRefreshToken);

      logger.i('✅ ApiInterceptor: Token refreshed successfully');
      return true;
    } catch (e) {
      logger.e('❌ ApiInterceptor: Token refresh exception — $e');
      return false;
    }
  }
}
