import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kakikaki/core/network/api_service.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';

// Interceptor 클래스를 상속받아 커스텀 인터셉터 구현
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String httpMethod = options.method;

    _printHeader(title: httpMethod, text: options.uri.toString());

    if (options.headers.isNotEmpty) {
      _printBody(
          'Headers:\n${options.headers.entries.map((e) => '\t${e.key}: ${e.value}').join('\n')}');
    }

    if (options.queryParameters.isNotEmpty) {
      _printBody(
          'QueryParameters:\n${options.queryParameters.entries.map((e) => '\t${e.key}: ${e.value}').join('\n')}');
    }

    if (options.data is Json) {
      _printBody('Body:\n\t${_getBody(options.data)}');
    }

    _printFooter(title: httpMethod);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    final RequestOptions options = response.requestOptions;
    final String httpMethod = options.method;

    _printHeader(
      title: '$httpMethod ❱➤ ${response.statusCode} ${response.statusMessage}',
      text: options.uri.toString(),
      type: 1,
    );

    if (response.data is Json || response.data is Iterable) {
      _printBody('Response:', type: 1);
      _printBody('\t${_getBody(response.data)}', type: 1);
    }
    _printFooter(title: httpMethod, type: 1);

    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final RequestOptions options = err.requestOptions;
    final String httpMethod = options.method;

    _printHeader(
      title:
          '$httpMethod ❱➤ ${err.response?.statusCode} ${err.response?.statusMessage}',
      text: options.uri.toString(),
      type: 2,
    );

    if (err.response?.data is Json || err.response?.data is Iterable) {
      _printBody('Response:', type: 2);
      _logPrint(Log.prettyJson(err.response?.data), type: 2);
    }

    _printFooter(title: httpMethod, type: 2);

    try {
      _logPrint(cURLRepresentation(err.requestOptions), type: 3);
    } catch (error, stackTrace) {
      ErrorReporter.ignoreExpected(
        error,
        stackTrace: stackTrace,
        context: 'LoggingInterceptor.curlRepresentation',
      );
      _logPrint('Unable to create a cURL representation: $error', type: 3);
    }

    return super.onError(err, handler);
  }

  void _logPrint(String message, {int type = 0}) {
    final String color;
    switch (type) {
      case 0:
        color = '\x1B[33m';
        break; // Yellow
      case 1:
        color = '\x1B[32m';
        break; // Green
      case 2:
        color = '\x1B[31m';
        break; // Red
      default:
        color = '';
        break; // Default
    }
    final resetColor = '\x1B[0m';
    Log.log('$color$message$resetColor', name: 'Dio');
  }

  void _printHeader({String? title, String? text, int type = 0}) {
    _logPrint('╔╣ $title', type: type);
    _logPrint('║ $text', type: type);
  }

  void _printBody(String? content, {int type = 0}) {
    _logPrint('║ $content', type: type);
  }

  void _printFooter({String? title, int type = 0}) {
    _logPrint('╚═ END $title', type: type);
  }

  String _getBody(dynamic data, {int maxLength = 200}) {
    final body = jsonEncode(data);
    return body.length > maxLength
        ? '${body.substring(0, maxLength)}... (truncated)'
        : body;
  }

  String cURLRepresentation(RequestOptions request) {
    final List<String> components = [
      "curl --request ${request.method.toUpperCase()} '${request.uri}'",
      ...request.headers.entries
          .where((e) => !e.key.contains('content-length'))
          .map((e) => "--header '${e.key}: ${e.value}'"),
    ];

    if (request.contentType?.contains(Headers.formUrlEncodedContentType) ??
        false) {
      components.addAll((request.data as Json)
          .entries
          .map((e) => "--data-urlencode '${e.key}=${e.value}'"));
    } else if (request.contentType
            ?.contains(Headers.multipartFormDataContentType) ??
        false) {
      final FormData formData = request.data as FormData;
      components.addAll(
          formData.fields.map((e) => "--form '${e.key}=\"${e.value}\"'"));
      components.addAll(formData.files
          .map((e) => "--form '${e.key}=\"@mock-path/${e.value.filename}\"'"));
    } else if (request.data != null) {
      components.add("--data '${_getBody(request.data)}'");
    }

    return components.join(' \\\n');
  }
}
