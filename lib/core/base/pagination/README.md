# Pagination 패키지

이 폴더는 무한 스크롤을 위한 페이지네이션 기능을 제공

## 구성 요소

### 1. AppPagination<T>
기본 offset 기반 페이지네이션을 위한 데이터 모델임.

```dart
const pagination = AppPagination<YourDataType>(
  data: items,
  pageNumber: 0,
  totalElements: 100,
  pageSize: 20,
);
```

### 2. AppCursorPagination<T>
Cursor 기반 페이지네이션을 위한 데이터 모델임.

```dart
const pagination = AppCursorPagination<YourDataType>(
  data: items,
  nextCursor: "next_cursor_value",
  previousCursor: "prev_cursor_value",
  pageSize: 20,
);
```

### 3. AppPagingController<T>
Offset 기반 무한 스크롤을 위한 컨트롤러임.

```dart
final controller = AppPagingController<int, YourDataType>();
```

### 4. CursorPagingController<T>
Cursor 기반 무한 스크롤을 위한 컨트롤러임.

```dart
final controller = CursorPagingController<YourDataType>();
```

### 5. AppPagedChildBuilderDelegate<T>
페이지네이션 UI 빌더임. 로딩, 에러, 빈 상태 등을 처리

## 사용 예시

### Offset 기반 페이지네이션

```dart
class OffsetPaginationExample extends StatefulWidget {
  @override
  State<OffsetPaginationExample> createState() => _OffsetPaginationExampleState();
}

class _OffsetPaginationExampleState extends State<OffsetPaginationExample> {
  final AppPagingController<int, YourDataType> _pagingController = 
      AppPagingController<int, YourDataType>();

  @override
  void initState() {
    super.initState();
    _pagingController.trigger(
      onLoadMore: (pageKey) => _fetchPage(pageKey),
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final response = await yourApiService.getData(
        page: pageKey,
        pageSize: 20,
      );
      
      final pagination = AppPagination<YourDataType>(
        data: response.data,
        pageNumber: pageKey,
        totalElements: response.totalElements,
        pageSize: 20,
      );
      
      _pagingController.onSuccess(pagination);
    } catch (error) {
      _pagingController.onError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, YourDataType>(
      pagingController: _pagingController,
      builderDelegate: AppPagedChildBuilderDelegate<YourDataType>(
        itemBuilder: (context, item, index) => ListTile(
          title: Text(item.title),
        ),
      ),
    );
  }
}
```

### Cursor 기반 페이지네이션

```dart
class CursorPaginationExample extends StatefulWidget {
  @override
  State<CursorPaginationExample> createState() => _CursorPaginationExampleState();
}

class _CursorPaginationExampleState extends State<CursorPaginationExample> {
  final CursorPagingController<YourDataType> _pagingController = 
      CursorPagingController<YourDataType>();

  @override
  void initState() {
    super.initState();
    _pagingController.triggerCursor(
      onLoadMore: (pageKey) => _fetchPage(pageKey),
    );
  }

  Future<void> _fetchPage(String? pageKey) async {
    try {
      final response = await yourApiService.getData(
        cursor: pageKey,
        pageSize: 20,
      );
      
      final pagination = AppCursorPagination<YourDataType>(
        data: response.data,
        nextCursor: response.nextCursor,
        previousCursor: response.previousCursor,
        pageSize: 20,
      );
      
      _pagingController.onCursorSuccess(pagination);
    } catch (error) {
      _pagingController.onError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<String?, YourDataType>(
      pagingController: _pagingController,
      builderDelegate: AppPagedChildBuilderDelegate<YourDataType>(
        itemBuilder: (context, item, index) => ListTile(
          title: Text(item.title),
        ),
      ),
    );
  }
}
```

## 권장사항

- **실시간 데이터가 많은 경우**: Cursor 기반 페이지네이션 사용
- **정적 데이터가 많은 경우**: Offset 기반 페이지네이션 사용
- **성능이 중요한 경우**: Cursor 기반 페이지네이션 사용 