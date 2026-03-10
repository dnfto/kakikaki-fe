import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'app_pagination.dart';

/// Cursor 기반 무한 스크롤을 위한 컨트롤러
class CursorPagingController<T> extends PagingController<String?, T> {
  CursorPagingController({
    super.firstPageKey,
    super.invisibleItemsThreshold =
        PagingConstants.defaultInvisibleItemsThreshold,
  });

  // 재귀 깊이 추적 (무한 루프 방지)
  int _recursionDepth = 0;
  static const int _maxRecursionDepth = 5;

  /// Cursor 기반 페이지네이션 성공 처리
  void onCursorSuccess(AppCursorPagination<T> pagination) {
    // 중복 데이터 필터링
    final existingIds =
        itemList?.map((item) => _getItemId(item)).toSet() ?? <String>{};
    final filteredData = pagination.data.where((item) {
      final itemId = _getItemId(item);
      final isDuplicate = existingIds.contains(itemId);
      if (isDuplicate) {
        Log.d('[CursorPagingController] 중복 데이터 제거: $itemId');
      }
      return !isDuplicate;
    }).toList();

    // 필터링 후 데이터가 비어있고, 다음 페이지가 있으며, 재귀 한도에 도달하지 않은 경우
    if (filteredData.isEmpty &&
        pagination.hasMoreData &&
        _recursionDepth < _maxRecursionDepth) {
      Log.d('[CursorPagingController] 필터링 후 데이터가 비어있어 자동으로 다음 페이지 요청');
      _recursionDepth++;
      // 다음 페이지를 자동으로 요청
      appendPage([], pagination.nextCursor);
      return;
    }

    // 재귀 깊이 초기화
    _recursionDepth = 0;

    if (pagination.hasMoreData) {
      appendPage(filteredData, pagination.nextCursor);
    } else {
      appendLastPage(filteredData);
    }
  }

  /// 아이템의 고유 ID를 추출하는 헬퍼 메서드
  String _getItemId(T item) {
    try {
      final dynamic dynamicItem = item;
      if (dynamicItem?.id != null) {
        return dynamicItem.id.toString();
      }
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'CursorPagingController.getItemId fallback',
      );
      // id 속성이 없는 경우 fallback
    }
    // fallback: 아이템의 해시코드 사용
    return item.hashCode.toString();
  }

  /// initState에서 호출하여 페이지 요청 리스너 등록
  void triggerCursor({
    PageRequestListener<String?>? onLoadMore,
    PagingStatusListener? onStatusChange,
  }) {
    if (onLoadMore != null) {
      addPageRequestListener(onLoadMore);
    }
    if (onStatusChange != null) {
      addStatusListener(onStatusChange);
    }
  }

  /// 페이지네이션 새로고침
  Future<void> onRefresh() async {
    _recursionDepth = 0; // 재귀 깊이 초기화
    refresh();
  }
}
