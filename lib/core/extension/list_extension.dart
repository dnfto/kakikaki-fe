import 'package:flutter/widgets.dart';

extension ListExtension<T> on List<T> {
  /// 존재하지 않으면 추가하고 존재하면 제거
  void addOrRemove(T data) {
    contains(data) ? remove(data) : add(data);
  }

  /// 존재하지 않으면 추가
  void addIfNotContains(T data) {
    if (!contains(data)) {
      add(data);
    }
  }

  // [Guideline 4] for문 + contains(O(N^2)) 최악의 조합을 Set 연산(O(N))으로 최적화!
  /// 존재하지 않으면 모든 아이템 추가
  void addAllIfNotContains(Iterable<T> data) {
    final existingSet = toSet();
    for (final element in data) {
      if (existingSet.add(element)) {
        add(element);
      }
    }
  }

  // [Guideline 4] removeWhere를 사용하여 단 한 번의 루프(O(N))로 삭제!
  /// 존재하면 모든 아이템 제거
  void removeAllIfContains(Iterable<T> data) {
    final elementsToRemove = data.toSet();
    removeWhere((element) => elementsToRemove.contains(element));
  }

  /// 각 요소와 인덱스를 새로운 값으로 매핑
  Iterable<R> mapIndexed<R>(R Function(int index, T element) convert) sync* {
    for (var index = 0; index < length; index++) {
      yield convert(index, this[index]);
    }
  }

  /// 존재하면 해당 요소를 제외하고 반환하고, 존재하지 않으면 요소를 추가하여 반환
  List<T> appendOrExceptElement(T item) {
    return contains(item)
        ? exceptElement(item).toList(growable: false)
        : appendElement(item).toList(growable: false);
  }

  List<T> plus(T element) => appendElement(element).toList(growable: false);
  List<T> minus(T element) => exceptElement(element).toList(growable: false);
  List<T> plusAll(List<T> elements) => append(elements).toList(growable: false);
  List<T> minusAll(List<T> elements) =>
      except(elements).toList(growable: false);
}

extension ListDividerExtension on List<Widget> {
  /// 각 요소 사이에 구분자를 추가하여 반환
  List<Widget> applySeparator(Widget separator) {
    if (isEmpty) return [];
    if (length == 1) return [first];

    // [Guideline 4] expand 대신 직관적이고 빠른 for문으로 조립
    final result = <Widget>[];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if (i != length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}

extension IterableExt<T> on Iterable<T> {
  Iterable<T> appendElement(T element) sync* {
    yield* this;
    yield element;
  }

  Iterable<T> append(Iterable<T> elements) sync* {
    yield* this;
    yield* elements;
  }

  Iterable<T> exceptElement(T element) sync* {
    for (final current in this) {
      if (element != current) yield current;
    }
  }

  Iterable<T> except(Iterable<T> elements) sync* {
    final elementsToExclude = elements.toSet();
    for (final current in this) {
      if (!elementsToExclude.contains(current)) yield current;
    }
  }
}
