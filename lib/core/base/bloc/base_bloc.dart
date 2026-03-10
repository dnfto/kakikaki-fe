import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/mixin/mixin.dart';
import 'package:kakikaki/core/network/network_exception.dart';
import 'common/common_cubit.dart';

/// BloC 베이스 설정
///
/// * 안전한 함수 실행을 위한 `runBlocCatching` 지원
/// * 페이지 로딩 지원
/// * 자동 로딩 상태 관리 지원
/// * 선택적 자동 로딩 상태 관리 지원
abstract class BaseBloc<Event, State> extends BaseBlocDelegate<Event, State>
    with EventTransformerMixin {
  BaseBloc(super.initialState, {super.autoClose});

  /// 자동 로딩 상태 관리를 위한 이벤트 핸들러 등록
  ///
  /// 각 이벤트 처리 전에 로딩 상태를 시작하고, 완료 후 성공 상태로 변경
  /// 에러 발생 시 자동으로 에러 상태로 변경
  @override
  void on<EventType extends Event>(
    EventHandler<EventType, State> handler, {
    EventTransformer<EventType>? transformer,
  }) {
    super.on<EventType>(
      (event, emit) async {
        try {
          // 이벤트 처리 전 로딩 상태 시작
          commonCubit.loadingEmitted();

          // 원본 핸들러 실행
          await handler(event, emit);

          // 성공 시 성공 상태로 변경
          commonCubit.successEmitted();
        } catch (error) {
          await ErrorReporter.report(
            error,
            context: '${runtimeType.toString()}.on<$EventType>',
          );
          // 에러 발생 시 에러 상태로 변경
          if (error is Exception) {
            commonCubit.exceptionEmitted(error);
          } else {
            commonCubit.exceptionEmitted(Exception(error.toString()));
          }
          rethrow;
        }
      },
      transformer: transformer,
    );
  }

  /// 자동 로딩 상태 관리 없이 이벤트 핸들러를 등록하는 메서드
  ///
  /// 로딩 상태를 수동으로 관리하거나 로딩이 필요 없는 이벤트에 사용한다.
  void onWithoutAutoLoading<EventType extends Event>(
    EventHandler<EventType, State> handler, {
    EventTransformer<EventType>? transformer,
  }) {
    super.on<EventType>(handler, transformer: transformer);
  }
}

abstract class BaseBlocDelegate<E, S> extends Bloc<E, S>
    with LogMixin, ToastMixin {
  BaseBlocDelegate(super.initialState, {this.autoClose = true});

  final bool autoClose;

  // CommonCubit: 페이지 상태(로딩, 성공, 에러)를 관리하는 큐빗
  CommonCubit? _commonCubit; // 필요할 때만 생성하기 위한 지연 초기화
  CommonCubit get commonCubit => _commonCubit ??= CommonCubit();

  /// [BasePageState]가 메모리에서 제거될 때 BLoC을 자동으로 닫도록 설정
  // autoClose가 true로 설정되면 페이지가 소멸될 때 BLoC도 자동으로 정리된다.

  /// [Bloc]에 새로운 [event]를 알리고, 이를 통해 모든 관련 [EventHandler] 인스턴스가 실행되도록 한다.
  // 이벤트를 추가하기 전에 BLoC이 이미 닫혔는지 확인하고,
  // 닫힌 상태에서 이벤트를 추가하면 에러가 발생하므로 이를 방지한다.

  @override
  void add(E event) {
    if (!isClosed) {
      super.add(event);
    } else {
      logE('$runtimeType BloC이 이미 닫혀 새로운 이벤트($event)를 추가할 수 없다.');
    }
  }

  void addException(Exception? exception) =>
      commonCubit.exceptionEmitted(exception);

  void showLoading() => commonCubit.loadingEmitted();

  void hideLoading({bool isSuccess = false}) =>
      isSuccess ? commonCubit.successEmitted() : commonCubit.initialEmitted();

  Future<void> runBlocCatching<T>({
    required Future<T> Function() action,
    FutureOr<void> Function()? doOnEventStart,
    FutureOr<void> Function(T value)? doOnSuccess,
    FutureOr<void> Function(Exception exception)? doOnError,
    FutureOr<void> Function()? doOnEventCompleted,
    bool handleLoading = true,
    bool handleError = true,
    bool handleToast = false,
    ToastGravity? handleToastGravity,
    Toast? handleToastLength,
    double? handleToastFontSize,
    Color? handleToastTextColor,
    Color? handleToastBackgroundColor,
  }) async {
    try {
      await doOnEventStart?.call();

      if (handleLoading) showLoading();

      final T value = await action.call();

      if (handleLoading) hideLoading(isSuccess: true);

      await doOnSuccess?.call(value);
    } on DioException catch (dioError) {
      final networkException = NetworkException.getException(dioError);
      await ErrorReporter.report(
        dioError,
        stackTrace: dioError.stackTrace,
        context: '${runtimeType.toString()}.runBlocCatching.DioException',
      );
      if (handleLoading) hideLoading();
      await doOnError?.call(networkException);

      if (handleToast) {
        addToastException(
          networkException,
          gravity: handleToastGravity,
          toastLength: handleToastLength,
          fontSize: handleToastFontSize,
          textColor: handleToastTextColor,
          backgroundColor: handleToastBackgroundColor,
        );
      }

      if (handleError) addException(networkException);
    } on Exception catch (e) {
      await ErrorReporter.report(
        e,
        context: '${runtimeType.toString()}.runBlocCatching.Exception',
      );
      if (handleLoading) hideLoading();

      await doOnError?.call(e);

      if (handleToast) {
        addToastException(
          e,
          gravity: handleToastGravity,
          toastLength: handleToastLength,
          fontSize: handleToastFontSize,
          textColor: handleToastTextColor,
          backgroundColor: handleToastBackgroundColor,
        );
      }

      if (handleError) addException(e);
    } on Error catch (e) {
      await ErrorReporter.report(
        e,
        stackTrace: e.stackTrace,
        context: '${runtimeType.toString()}.runBlocCatching.Error',
      );
      if (handleLoading) hideLoading();

      if (handleToast) {
        addToastMessage(
          Error.safeToString(e),
          gravity: handleToastGravity,
          toastLength: handleToastLength,
          fontSize: handleToastFontSize,
          textColor: handleToastTextColor,
          backgroundColor: handleToastBackgroundColor,
        );
      }

      logE(Error.safeToString(e), errorObject: e, stackTrace: e.stackTrace);
    } finally {
      await doOnEventCompleted?.call();
    }
  }
}
