import 'dart:io';

import 'package:dio/dio.dart';
import './api_exception.dart';
import '../../storage/secure_storage.dart';
import '../../utils/logger.dart';

/// A helper class to handle all HTTP API requests using [Dio].
class ApiHelper {
  final Dio _dio;

  const ApiHelper(this._dio);

  Future<dynamic> execute({
    required Method method,
    required String url,
    dynamic data,
    dynamic options,
  }) async {
    final newToken = await SecureStorage.getAccessToken();
    final hasToken = newToken != null;

    logger.i('URL: $url');

    final authOptions = hasToken
        ? Options(headers: {'Authorization': 'Bearer $newToken'})
        : Options();

    try {
      Response response;

      switch (method) {
        case Method.get:
          response = await _dio.get(
            url,
            queryParameters: data is Map<String, dynamic> ? data : null,
            options: options ?? authOptions,
          );
          break;
        case Method.post:
          response = await _dio.post(
            url,
            data: data,
            options: options ?? authOptions,
          );
          break;
        case Method.put:
          response = await _dio.put(
            url,
            data: data,
            options: options ?? authOptions,
          );
          break;
        case Method.patch:
          response = await _dio.patch(
            url,
            data: data,
            options: options ?? authOptions,
          );
          break;
        case Method.delete:
          response = await _dio.delete(
            url,
            data: data,
            options: options ?? authOptions,
          );
          break;
      }

      logger.i('Response: ${response.data}');
      return _returnResponse(response);
    } on SocketException catch (e) {
      logger.e('🔌 ApiHelper: No internet connection — $e');
      throw FetchDataException('No Internet connection');
    } on DioException catch (e) {
      logger.e(
        '❌ ApiHelper: DioException on ${method.name.toUpperCase()} $url — ${e.message} (status: ${e.response?.statusCode})',
      );
      if (e.response != null) {
        logger.d('   Error response body: ${e.response?.data}');
        return _returnResponse(e.response!);
      }
      throw ApiException(e.message ?? 'Network error');
    } catch (e) {
      if (e is ApiException) rethrow;
      logger.e('❌ ApiHelper: Unexpected exception — $e');
      rethrow;
    }
  }

  dynamic _returnResponse(Response response) {
    String getMsg(dynamic data) {
      if (data is Map) {
        if (data['detail'] != null) {
          final detail = data['detail'];
          if (detail is String && detail.isNotEmpty) return detail;
          if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map && first['msg'] != null) {
              return first['msg'].toString();
            }
            return first.toString();
          }
          return detail.toString();
        }
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          return data['message'].toString();
        }
        if (data['error'] != null && data['error'].toString().isNotEmpty) {
          return data['error'].toString();
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
      return 'An error occurred';
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        // Handle cases where the server returns 200/201 but the body contains an error status
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('status')) {
          final int internalStatus = int.tryParse(data['status'].toString()) ?? 200;
          if (internalStatus == 401) {
            logger.w('🔐 ApiHelper: Internal 401 Unauthorized — ${getMsg(data)}');
            throw UnauthorizedException(getMsg(data));
          } else if (internalStatus == 400) {
            logger.w('⚠️ ApiHelper: Internal 400 Bad Request — ${getMsg(data)}');
            throw BadRequestException(getMsg(data));
          } else if (internalStatus == 403) {
            logger.w('🚫 ApiHelper: Internal 403 Forbidden — ${getMsg(data)}');
            throw ForbiddenException(getMsg(data));
          } else if (internalStatus == 404) {
            logger.w('🔍 ApiHelper: Internal 404 Not Found — ${getMsg(data)}');
            throw NotFoundException(getMsg(data));
          } else if (internalStatus == 422) {
            logger.w('⚠️ ApiHelper: Internal 422 Unprocessable — ${getMsg(data)}');
            throw UnprocessableContentException(getMsg(data));
          } else if (internalStatus >= 500) {
            logger.e('💥 ApiHelper: Internal $internalStatus Server Error — ${getMsg(data)}');
            throw InternalServerException(getMsg(data));
          }
        }
        return response.data;
      case 400:
        logger.w('⚠️ ApiHelper: 400 Bad Request — ${getMsg(response.data)}');
        throw BadRequestException(getMsg(response.data));
      case 401:
        logger.w('🔐 ApiHelper: 401 Unauthorized — ${getMsg(response.data)}');
        throw UnauthorizedException(getMsg(response.data));
      case 403:
        logger.w('🚫 ApiHelper: 403 Forbidden — ${getMsg(response.data)}');
        throw ForbiddenException(getMsg(response.data));
      case 404:
        logger.w('🔍 ApiHelper: 404 Not Found — ${getMsg(response.data)}');
        throw NotFoundException(getMsg(response.data));
      case 422:
        logger.w(
          '⚠️ ApiHelper: 422 Unprocessable Content — ${getMsg(response.data)}',
        );
        throw UnprocessableContentException(getMsg(response.data));
      case 500:
        logger.e('💥 ApiHelper: 500 Internal Server Error — ${getMsg(response.data)}');
        throw InternalServerException(getMsg(response.data));
      default:
        logger.e(
          '❓ ApiHelper: Unexpected status code ${response.statusCode}',
        );
        throw FetchDataException(
          'Server error with StatusCode : ${response.statusCode}',
        );
    }
  }
}

enum Method { get, post, put, patch, delete }
