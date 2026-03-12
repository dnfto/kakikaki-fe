import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/network/header_builder.dart';

/// GlobalBloc을 사용하여 헤더를 빌드하는 구현체
///
/// GlobalBloc에서 언어 코드를 가져와 Accept-Language 헤더를 설정합니다.
@Singleton(as: HeaderBuilder)
class GlobalBlocHeaderBuilder implements HeaderBuilder {
  GlobalBlocHeaderBuilder();

  @override
  Map<String, dynamic> buildHeaders({
    required bool requiresAuthToken,
    Map<String, dynamic>? customHeaders,
  }) {
    // 언어 코드 가져오기
    final String languageCode = getIt<GlobalBloc>().state.languageCode;

    final Map<String, dynamic> headers = {
      'accept': 'application/json; charset=utf-8; text/plain; */*',
      'Accept-Language': languageCode,
      'requiresAuthToken': requiresAuthToken,
      ...?customHeaders,
    };

    // null 값의 헤더 제거
    headers.removeWhere((key, value) => value == null);
    return headers;
  }
}

/// 고정된 언어 코드를 사용하는 헤더 빌더 (테스트용)
class FixedLanguageHeaderBuilder implements HeaderBuilder {
  FixedLanguageHeaderBuilder(this.languageCode);

  final String languageCode;

  @override
  Map<String, dynamic> buildHeaders({
    required bool requiresAuthToken,
    Map<String, dynamic>? customHeaders,
  }) {
    final Map<String, dynamic> headers = {
      'accept': 'application/json; charset=utf-8; text/plain; */*',
      'Accept-Language': languageCode,
      'requiresAuthToken': requiresAuthToken,
      ...?customHeaders,
    };

    headers.removeWhere((key, value) => value == null);
    return headers;
  }
}
