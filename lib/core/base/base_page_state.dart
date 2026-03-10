import 'package:flutter/services.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:interactive_bottom_sheet/interactive_bottom_sheet.dart';
import 'package:kakikaki/core/mixin/mixin.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bloc/base_bloc.dart';
import 'bloc/common/common_cubit.dart';

//==============================================================================
// 0. Delegate (구현부)
// Flutter의 SliverPersistentHeaderDelegate와 같은 '델리게이트 패턴'을 따름
// 모든 핵심 로직을 담는 기본 Delegate와, Scaffold 기능을 확장한 Delegate로 구성
// 인터페이스와 구현을 분리하기 위해 핵심 로직은 여기에 작성!!
//==============================================================================
abstract class BasePageStateDelegate<T extends StatefulWidget,
    B extends BaseBloc<dynamic, S>, S> extends State<T> {
  late final B bloc = _initializeBloc();

  // BLoC 초기화 로직 - 하위 클래스에서 오버라이드 가능
  B _initializeBloc() {
    final providedBloc = getProvidedBloc();
    if (providedBloc != null) return providedBloc;

    // 위젯 트리에서 찾는 대신 바로 GetIt에서 가져오기
    return GetIt.I.get<B>();
  }

  // 하위 클래스에서 위젯으로부터 BLoC을 가져올 때 오버라이드
  @protected
  B? getProvidedBloc() => null;

  CommonState get commonState => bloc.commonCubit.state;

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider: B 타입의 BLoC과 CommonCubit을 제공하여 상태를 관리
    // autoClose가 true이면 BLoC 인스턴스를 새로 생성하고, false면 기존 BLoC 인스턴스를 재사용
    return MultiBlocProvider(
      providers: [
        if (bloc.autoClose)
          BlocProvider<B>(create: (_) => bloc)
        else
          BlocProvider<B>.value(value: bloc),
        BlocProvider<CommonCubit>(create: (_) => bloc.commonCubit),
      ],
      // listener: 상태 변화 시 특정 로직을 실행
      // builder: 상태에 따라 UI를 빌드
      child: BlocConsumer<B, S>(
        bloc: bloc,
        listenWhen: handleBlocListenWhen,
        listener: handleBlocStateListener,
        buildWhen: handleBlocBuildWhen, // 리빌드 조건을 자식 클래스에서 제어 가능
        builder: (context, mainState) {
          // CommonCubit의 상태 변화도 감지하도록 BlocListener 추가
          return BlocListener<CommonCubit, CommonState>(
            bloc: bloc.commonCubit,
            listener: (context, commonState) {
              // CommonCubit 상태 변화 시에도 handleBlocStateListener 호출

              handleBlocStateListener(context, mainState);
            },
            child: BlocBuilder<CommonCubit, CommonState>(
              bloc: bloc.commonCubit,
              buildWhen: handleListenWhen,
              builder: (context, commonState) {
                return buildScaffold(context, mainState, commonState);
              },
            ),
          );
        },
      ),
    );
  }

  // @protected: 동일한 패키지 내이거나 서브클래스에서만 접근 가능
  // 기본값은 항상 실행되도록 하여 하위 호환성을 유지
  /// 이전 상태와 현재 상태를 받아 [bool] 값을 반환
  @protected
  bool handleListenWhen(CommonState previous, CommonState current) =>
      current != previous;

  @protected
  bool handleBlocListenWhen(S previous, S current) => previous != current;

  // 메인 BLoC의 리빌드 조건을 제어하기 위한 메서드
  @protected
  bool handleBlocBuildWhen(S previous, S current) => previous != current;

  @protected
  void handleBlocStateListener(BuildContext context, S state) {
    // 에러 상태 발생 시 처리 (하위 클래스에서 오버라이드 가능)
    if (commonState.isError) {
      handleErrorState(context, commonState.exception);
    }
  }

  /// 에러 상태 발생 시 호출되는 메서드 (하위 클래스에서 오버라이드 가능)
  @protected
  void handleErrorState(BuildContext context, Exception? exception) {
    // 기본 구현: 아무것도 하지 않음 (토스트는 BaseBloc에서 처리)
  }

  /// 이 메서드는 기본적으로 Stack과 buildPage를 호출해 UI 구조를 만든다.
  /// BaseScaffoldPageStateDelegate에서 이 메서드를 오버라이드하여 Scaffold를 추가한다.
  @protected
  Widget buildScaffold(
      BuildContext context, S mainState, CommonState commonState) {
    // 에러 상태일 때는 에러 위젯 표시, 로딩 중일 때는 로딩 인디케이터 표시
    if (commonState.isError && showDefaultError) {
      return _buildErrorWidget(context, commonState.exception);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        buildPage(context, mainState), // <-- buildPage에 mainState 전달
        Visibility(
          visible: commonState.isLoading,
          child: const DefaultCircularProgressIndicator(),
        ),
      ],
    );
  }

  /// 기본 에러 표시 여부 (하위 클래스에서 오버라이드 가능)
  @protected
  bool get showDefaultError => true;

  /// 화면이 메모리에 살아있을 때만 안전하게 상태를 업데이트
  /// 비동기 작업(API 호출 등) 이후에 사용하면 크래시를 방지
  @protected
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// 에러 위젯 빌드
  Widget _buildErrorWidget(BuildContext context, Exception? exception) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.palette.error,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorMessage(context, exception),
              textAlign: TextAlign.center,
              style: context.h5_600Style.copyWith(
                color: context.palette.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              CommonTextButton(
                isExpandedWidth: false,
                onPressed: () {
                  bloc.commonCubit.initialEmitted(); // 에러 상태 초기화
                  onRetry?.call();
                },
                text: '다시 시도',
              ),
          ],
        ),
      ),
    );
  }

  /// 에러 메시지 추출
  /// 에러 메시지 추출 (유저 친화적으로 변환)
  String _getErrorMessage(BuildContext context, Exception? exception) {
    final l10n = context.l10n;

    if (exception == null) {
      return l10n.error_generic;
    }

    // 1. Supabase 관련 에러 (디버깅용 로그는 남기고, 유저에겐 부드럽게)
    if (exception is AuthApiException) {
      Log.e('Supabase Auth Error: ${exception.message}');
      return l10n.error_login_processing_failed;
    }

    // 2. 플랫폼 관련 에러 (카카오톡 취소, 구글 서비스 등)
    if (exception is PlatformException) {
      Log.e('Platform Error: ${exception.message}');
      return l10n.error_platform_integration_failed;
    }

    // 3. 우리가 직접 던진 Exception (예: throw Exception('서버 초기화가...'))
    final msg = exception.toString();
    if (msg.startsWith('Exception: ')) {
      // 개발자가 의도한 한글 메시지라면 그대로 보여줌
      return msg.replaceFirst('Exception: ', '').trim();
    }

    // 4. 그 외 알 수 없는 에러
    return l10n.error_temporary_generic;
  }

  /// 재시도 콜백 (하위 클래스에서 오버라이드 가능)
  @protected
  VoidCallback? get onRetry => null;

  // 하위 클래스에서 페이지의 주요 UI를 구현하는 메서드로, 공통된 로직을 제외한 개별 UI는 이 메서드를 통해 정의
  /// Build widget of page - 페이지의 구체적인 UI는 최신 상태(S)를 직접 전달받아 그린다.
  Widget buildPage(BuildContext context, S state);

  /// Pull to refresh 기능을 위한 콜백 메서드
  /// 하위 클래스에서 오버라이드하여 구현
  @protected
  Future<void> onRefresh() async {
    // 기본 구현: 아무것도 하지 않음
  }

  /// Pull to refresh가 활성화되어 있는지 확인
  @protected
  bool get enablePullToRefresh => false;

  /// 프로필 설정 재진입 감지: 프로필 설정을 끝내지 않고 앱을 종료했다가 다시 시작한 경우
  /// 토큰이 있고, nextRequiredStep이 현재 경로와 일치하면 재진입으로 판단하여 토스트 메시지를 표시
}

abstract class BaseScaffoldPageStateDelegate<T extends StatefulWidget,
    B extends BaseBloc<dynamic, S>, S> extends BasePageStateDelegate<T, B, S> {
  final double? horizontalMargin;
  final double? verticalMargin;

  final PreferredSizeWidget? appBar;
  final bool isAppBar;
  final String? appBarTitle;
  final String? appBarSubtitle;
  final List<Widget>? appBarActions;
  final PreferredSizeWidget? appBarBottom;
  final VoidCallback? appBarLeadingAction;
  final bool automaticallyImplyLeading;
  final Color? appBarBackgroundColor;

  final bool isBottomNavigationBar;
  final Widget? bottomNavigationBar;

  final Widget? header;
  final Widget? footer;
  final bool isSafeArea;
  final Widget? bottomSheet;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @protected
  Widget? get floatingActionButtonGetter => floatingActionButton;

  final bool isResizeToAvoidBottomInset;
  final Color? backgroundColor;
  final EdgeInsets? margin;
  final bool showDefaultLoading;

  @override
  final bool showDefaultError;

  @override
  final bool enablePullToRefresh;

  BaseScaffoldPageStateDelegate({
    this.horizontalMargin,
    this.verticalMargin,
    this.appBar,
    this.isAppBar = true,
    this.appBarTitle,
    this.appBarSubtitle,
    this.appBarActions,
    this.appBarBottom,
    this.appBarLeadingAction,
    this.automaticallyImplyLeading = true,
    this.appBarBackgroundColor,
    this.isBottomNavigationBar = true,
    this.bottomNavigationBar,
    this.isResizeToAvoidBottomInset = true,
    this.header,
    this.footer,
    this.isSafeArea = true,
    this.bottomSheet,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.margin,
    this.showDefaultLoading = true,
    this.showDefaultError = false,
    this.enablePullToRefresh = false,
  });

  @override
  Widget buildScaffold(
      BuildContext context, S mainState, CommonState commonState) {
    // 에러 상태일 때는 에러 위젯 표시
    if (commonState.isError && showDefaultError) {
      return CommonScaffold(
        backgroundColor: backgroundColor ?? Palette.white,
        resizeToAvoidBottomInset: isResizeToAvoidBottomInset,
        appBar: isAppBar ? _buildAppBar(context) : null,
        body: isSafeArea
            ? SafeArea(child: _buildErrorWidget(context, commonState.exception))
            : _buildErrorWidget(context, commonState.exception),
        bottomNavigationBar: isBottomNavigationBar
            ? bottomNavigationBar ?? const CommonBottomNavBar()
            : null,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        hideKeyboardWhenTouchOutside: true,
      );
    }

    return AbsorbPointer(
      absorbing: commonState.isLoading && showDefaultLoading,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CommonScaffold(
            backgroundColor: backgroundColor ?? Palette.white,
            resizeToAvoidBottomInset: isResizeToAvoidBottomInset,
            appBar: isAppBar ? _buildAppBar(context) : null,
            body: isSafeArea
                ? SafeArea(child: _buildBodyContent(context, mainState))
                : _buildBodyContent(context, mainState),
            bottomNavigationBar: isBottomNavigationBar
                ? bottomNavigationBar ?? const CommonBottomNavBar()
                : null,
            floatingActionButton: buildFloatingActionButton(context),
            floatingActionButtonLocation: floatingActionButtonLocation,
            hideKeyboardWhenTouchOutside: true,
          ),
          // bottomSheet는 별도로 오버레이로 표시
          if (bottomSheet != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSheet(),
            ),
          if (showDefaultLoading && commonState.isLoading)
            const DefaultCircularProgressIndicator(),
        ],
      ),
    );
  }

  /// AppBar 빌드
  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (appBar != null) {
      return appBar;
    }

    return DefaultCommonAppbar(
      title: appBarTitle ?? "",
      subtitle: appBarSubtitle,
      actions: appBarActions,
      rightActions: rightAppBarActions,
      bottom: appBarBottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: appBarBackgroundColor,
      leadingWidth: appBarLeadingWidth,
      titleSpacing: appBarTitleSpacing,
      leading: showAppBarLeading
          ? IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () {
                final action = appBarLeadingActionGetter;
                if (action != null) {
                  action();
                } else {
                  Navigator.maybePop(context);
                }
              },
            )
          : null,
    );
  }

  @protected
  List<Widget>? get rightAppBarActions => null;

  @protected
  bool get showAppBarLeading =>
      automaticallyImplyLeading && Navigator.canPop(context);

  @protected
  double? get appBarLeadingWidth => null;

  @protected
  double? get appBarTitleSpacing => null;

  @protected
  VoidCallback? get appBarLeadingActionGetter => appBarLeadingAction;

  @protected
  Widget? buildFloatingActionButton(BuildContext context) {
    return floatingActionButtonGetter;
  }

  Widget _buildBodyContent(BuildContext context, S mainState) {
    final bool hasPadding =
        (horizontalMargin ?? context.responsiveHorizontalMargin) != 0 ||
            (verticalMargin ?? context.responsiveVerticalMargin) != 0;
    final bool hasHeaderOrFooter = header != null || footer != null;

    if (enablePullToRefresh && !hasPadding && !hasHeaderOrFooter) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: buildPage(context, mainState),
      );
    }

    Widget bodyContent = Container(
      margin: margin ?? EdgeInsets.zero,
      padding: EdgeInsets.symmetric(
          horizontal: horizontalMargin ?? context.responsiveHorizontalMargin,
          vertical: verticalMargin ?? context.responsiveVerticalMargin),
      child: hasHeaderOrFooter
          ? Column(
              children: [
                if (header != null) header!,
                Expanded(flex: 9, child: buildPage(context, mainState)),
                if (footer != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: footer!,
                  ),
              ],
            )
          : buildPage(context, mainState),
    );

    if (enablePullToRefresh) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: hasHeaderOrFooter
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: bodyContent,
              )
            : bodyContent,
      );
    }

    return bodyContent;
  }

  Widget _buildBottomSheet() {
    return InteractiveBottomSheet(
      options: const InteractiveBottomSheetOptions(
        maxSize: 0.7,
        minimumSize: 0.3,
        initialSize: 0.3,
        snapList: [0.3, 0.7],
        backgroundColor: Palette.white,
      ),
      draggableAreaOptions: const DraggableAreaOptions(
        topBorderRadius: 20,
        height: 30,
        backgroundColor: Palette.white,
        indicatorColor: Palette.gray30,
        indicatorWidth: 57,
        indicatorHeight: 4,
        indicatorRadius: 40,
      ),
      child: bottomSheet,
    );
  }
}

abstract class BasePageState<
        T extends StatefulWidget,
        B extends BaseBloc<dynamic, S>,
        S> extends BasePageStateDelegate<T, B, S>
    with LogMixin, ThemeMixin, ToastMixin {}

abstract class SimpleBasePageState<T extends StatefulWidget, B extends BaseBloc>
    extends BasePageState<T, B, dynamic> {}

abstract class BaseScaffoldPageState<
        T extends StatefulWidget,
        B extends BaseBloc<dynamic, S>,
        S> extends BaseScaffoldPageStateDelegate<T, B, S>
    with LogMixin, ThemeMixin, ToastMixin {
  BaseScaffoldPageState({
    super.appBar,
    super.isAppBar,
    super.appBarTitle,
    super.appBarSubtitle,
    super.horizontalMargin,
    super.verticalMargin,
    super.appBarActions,
    super.appBarBottom,
    super.automaticallyImplyLeading,
    super.appBarLeadingAction,
    super.appBarBackgroundColor,
    super.isBottomNavigationBar,
    super.bottomNavigationBar,
    super.isResizeToAvoidBottomInset,
    super.header,
    super.footer,
    super.isSafeArea,
    super.bottomSheet,
    super.floatingActionButton,
    super.floatingActionButtonLocation,
    super.backgroundColor,
    super.margin,
    super.showDefaultLoading,
    super.showDefaultError,
    super.enablePullToRefresh,
  });
}

abstract class SimpleBaseScaffoldPageState<T extends StatefulWidget,
    B extends BaseBloc> extends BaseScaffoldPageState<T, B, dynamic> {
  SimpleBaseScaffoldPageState({
    super.isAppBar,
    super.appBarTitle,
    super.horizontalMargin,
    super.verticalMargin,
    super.isBottomNavigationBar,
    super.isResizeToAvoidBottomInset,
    super.header,
    super.footer,
    super.isSafeArea,
    super.bottomSheet,
    super.backgroundColor,
    super.margin,
    super.showDefaultLoading,
    super.enablePullToRefresh,
    super.automaticallyImplyLeading,
  });
}
