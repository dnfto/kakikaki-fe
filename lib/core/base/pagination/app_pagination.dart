import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_pagination.freezed.dart';

/// 페이지네이션 기본 상수
class PagingConstants {
  const PagingConstants._();

  static const initialPage = 0;
  static const itemsPerPage = 20;
  static const defaultInvisibleItemsThreshold = 5;
}

/// 페이지네이션을 위한 데이터
@freezed
class AppPagination<T> with _$AppPagination<T> {
  const factory AppPagination({
    required List<T> data,
    required int pageNumber,
    required int totalElements,
    @Default(PagingConstants.itemsPerPage) int pageSize,
  }) = _AppPagination;

  const AppPagination._();

  int get nextPageNumber => pageNumber + 1;
  int get previousPageNumber => pageNumber - 1;

  bool get first => pageNumber == 0;
  bool get last => (pageNumber * pageSize) >= totalElements;
}

/// Cursor 기반 페이지네이션을 위한 전용 클래스
@freezed
class AppCursorPagination<T> with _$AppCursorPagination<T> {
  const factory AppCursorPagination({
    required List<T> data,
    String? nextCursor,
    String? previousCursor,
    @Default(PagingConstants.itemsPerPage) int pageSize,
  }) = _AppCursorPagination;

  const AppCursorPagination._();

  bool get hasNextCursor => nextCursor != null;
  bool get hasPreviousCursor => previousCursor != null;
  bool get hasMoreData => hasNextCursor;
}
