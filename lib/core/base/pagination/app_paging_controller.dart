import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'app_pagination.dart';

/// Offset 기반 무한 스크롤을 위한 컨트롤러
class AppPagingController<T> extends PagingController<int, T> {
  AppPagingController({
    super.firstPageKey = PagingConstants.initialPage,
    super.invisibleItemsThreshold =
        PagingConstants.defaultInvisibleItemsThreshold,
  });

  /// initState에서 호출하여 페이지 요청 리스너 등록
  void trigger({
    PageRequestListener<int>? onLoadMore,
    PagingStatusListener? onStatusChange,
  }) {
    if (onLoadMore != null) addPageRequestListener(onLoadMore);
    if (onStatusChange != null) addStatusListener(onStatusChange);
  }

  /// 페이지네이션 성공 시 호출
  void onSuccess(AppPagination<T> pagination) {
    if (pagination.last) {
      appendLastPage(pagination.data);
    } else {
      appendPage(pagination.data, pagination.nextPageNumber);
    }
  }

  /// 페이지네이션 에러 발생 시 호출
  void onError(Object? exception) {
    if (exception is Error || exception is Exception) {
      error = exception;
    }
  }

  /// 페이지네이션 새로고침
  Future<void> onRefresh() async => refresh();
}
