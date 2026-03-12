import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/app/widget/dialogue/common_dialogue.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:kakikaki/core/mixin/log_mixin.dart';
import 'package:kakikaki/core/storage/local_storage.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';

class TokenInterceptor extends Interceptor with LogMixin {
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];
  Dio? _retryDio;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. 리트라이 횟수 초기화 (무한 루프 방지용)
    options.extra['retryCount'] ??= 0;

    if (options.headers['requiresAuthToken'] == true) {
      options.extra['requiresAuthToken'] = true;
      options.headers.remove('requiresAuthToken');

      final String? token = await getIt<LocalStorage>()
          .getEncrypted(AuthConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] =
            token.startsWith('Bearer ') ? token : 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;

    // 401이 아니거나, 이미 리트라이를 한 번 수행했다면 중단
    if (err.response?.statusCode != 401 || options.extra['retryCount'] > 0) {
      return handler.next(err);
    }

    if (options.extra['requiresAuthToken'] != true) {
      return handler.next(err);
    }

    logI('401 발생 - 세션 갱신 시도: ${options.path}');

    if (_isRefreshing) {
      return _addToPendingQueue(options, handler);
    }

    _isRefreshing = true;
    options.extra['retryCount'] += 1; // 리트라이 횟수 증가

    try {
      final newToken = await _refreshTokenViaSupabase();
      if (newToken != null) {
        _isRefreshing = false;

        // 큐에 쌓인 요청 처리
        _retryPendingRequests(newToken);

        // 현재 요청 재시도
        final response = await _retryRequestWithToken(options, newToken);
        return handler.resolve(response);
      }
    } catch (e) {
      logE('토큰 리프레시 과정 중 예외 발생: $e');
    } finally {
      // 실패 시 처리
      if (_isRefreshing) {
        _isRefreshing = false;
        _rejectPendingRequests(err); // 쌓여있던 요청들도 원래 에러로 거절
        await _handleLogoutOrPassThrough(options);
      }
    }

    return handler.next(err); // 최종 실패 시 원래 에러 전달
  }

  Future<String?> _refreshTokenViaSupabase() async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) return null;

    try {
      // Supabase 내부적으로 토큰 만료를 판단하여 리프레시 수행
      final response = await client.auth.refreshSession();
      final session = response.session;
      if (session == null) return null;

      final storage = getIt<LocalStorage>();
      await storage.saveEncrypted(
          AuthConstants.accessTokenKey, session.accessToken);
      await storage.saveEncrypted(
          AuthConstants.refreshTokenKey, session.refreshToken ?? '');

      getIt<GlobalBloc>().add(GlobalChangeToken(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      ));

      return session.accessToken;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleLogoutOrPassThrough(RequestOptions options) async {
    // 로그인/회원가입 중이면 무시
    if (options.path.contains(AuthConstants.tokenApiPathPattern)) return;

    final globalBloc = getIt<GlobalBloc>();
    globalBloc.add(const GlobalSignOut());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        final l10n = lookupAppLocalizations(globalBloc.state.locale);
        CommonDialogue.showOneChoiceDialogue(
          context: context,
          title: l10n.auth_login_expired,
          content: l10n.auth_login_expired_content,
          onElevatedButtonPressed: () {
            // go_router를 통해 로그인 화면으로 이동
            navigate(context, path: InitialRoute().location);
          },
        );
      }
    });
  }

  // 리트라이 시에는 원래 Dio 설정을 복사한 인스턴스 사용 권장
  Dio _getRetryDio(RequestOptions originalOptions) {
    _retryDio ??= Dio();
    _retryDio!.options.connectTimeout = originalOptions.connectTimeout;
    _retryDio!.options.receiveTimeout = originalOptions.receiveTimeout;
    return _retryDio!;
  }

  Future<Response> _retryRequestWithToken(
      RequestOptions options, String newToken) async {
    final headers = Map<String, dynamic>.from(options.headers);
    headers['Authorization'] = 'Bearer $newToken';

    return _getRetryDio(options).request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: headers,
        extra: options.extra, // retryCount가 포함된 extra 전달
      ),
    );
  }

  Future<void> _addToPendingQueue(
      RequestOptions options, ErrorInterceptorHandler handler) {
    final completer = Completer<Response>();
    _pendingRequests.add(_PendingRequest(
        options: options, handler: handler, completer: completer));
    return completer.future;
  }

  void _retryPendingRequests(String newToken) {
    for (final pending in _pendingRequests) {
      _retryRequest(pending, newToken);
    }
    _pendingRequests.clear();
  }

  void _rejectPendingRequests(DioException err) {
    for (final pending in _pendingRequests) {
      pending.handler.next(err); // 원래 에러를 그대로 전달
    }
    _pendingRequests.clear();
  }

  Future<void> _retryRequest(_PendingRequest pending, String newToken) async {
    try {
      pending.options.extra['retryCount'] += 1;
      final response = await _retryRequestWithToken(pending.options, newToken);
      pending.handler.resolve(response);
      pending.completer.complete(response);
    } catch (e) {
      if (e is DioException) {
        pending.handler.next(e);
      } else {
        pending.completer.completeError(e);
      }
    }
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
  final Completer<Response> completer;

  _PendingRequest(
      {required this.options, required this.handler, required this.completer});
}
