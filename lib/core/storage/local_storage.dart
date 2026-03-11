import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/error/error_reporter.dart';

/// 키 밸류 형태의 로컬 데이터베이스
///
/// 두 가지 저장소를 제공:
/// 1. FlutterSecureStorage: 암호화된 저장소 (토큰 등 민감한 정보용)
/// 2. Hive: 일반 저장소 (사용자 설정 등 비민감 정보용)
@Singleton(order: -1)
class LocalStorage {
  const LocalStorage._();

  @factoryMethod
  static Future<LocalStorage> create() async {
    // Hive 초기화(initialize)
    _hiveStorage ??= await Hive.openBox('LocalStorage');

    // FlutterSecureStorage 초기화(initialize)
    _secureStorage ??= const FlutterSecureStorage();

    return const LocalStorage._();
  }

  /* ------------------ SECURE STORAGE (암호화 저장소) ----------------------- */
  /// 토큰 등 민감한 정보는 FlutterSecureStorage에만 저장해야 함
  /// GlobalState에는 저장하지 않음 (보안)

  static FlutterSecureStorage? _secureStorage;

  /// FlutterSecureStorage에서 주어진 키에 대한 값을 읽어온다.
  /// 이 값은 암호화되어 저장되며, 복호화된 값을 반환한다.
  ///
  /// [key]: 읽을 키
  /// Returns: 저장된 값 또는 null (키가 없거나 오류 발생 시)
  Future<String?> getEncrypted(String key) async {
    if (_secureStorage == null) {
      debugPrint('LocalStorage: FlutterSecureStorage가 초기화되지 않았습니다.');
      return null;
    }

    try {
      return await _secureStorage!.read(key: key);
    } on PlatformException catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.getEncrypted.platform',
      );
      debugPrint('LocalStorage.getEncrypted 오류: $e');
      return null;
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.getEncrypted',
      );
      debugPrint('LocalStorage.getEncrypted 예상치 못한 오류: $e');
      return null;
    }
  }

  /// 주어진 키와 값을 FlutterSecureStorage에 저장한다(write).
  /// 토큰 등 민감한 정보는 반드시 이 메서드를 사용해야 함.
  ///
  /// [key]: 저장할 키
  /// [value]: 저장할 값
  /// Returns: 저장 성공 여부
  Future<bool> saveEncrypted(String key, String value) async {
    if (_secureStorage == null) {
      debugPrint('LocalStorage: FlutterSecureStorage가 초기화되지 않았습니다.');
      return false;
    }

    if (key.isEmpty) {
      debugPrint('LocalStorage.saveEncrypted: 키가 비어있습니다.');
      return false;
    }

    try {
      await _secureStorage!.write(key: key, value: value);
      return true;
    } on PlatformException catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.saveEncrypted.platform',
      );
      debugPrint('LocalStorage.saveEncrypted 오류: $e');
      return false;
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.saveEncrypted',
      );
      debugPrint('LocalStorage.saveEncrypted 예상치 못한 오류: $e');
      return false;
    }
  }

  /// FlutterSecureStorage에서 주어진 키의 데이터를 삭제한다.
  ///
  /// [key]: 삭제할 키
  Future<void> deleteEncrypted(String key) async {
    if (_secureStorage == null) {
      debugPrint('LocalStorage: FlutterSecureStorage가 초기화되지 않았습니다.');
      return;
    }

    if (key.isEmpty) {
      debugPrint('LocalStorage.deleteEncrypted: 키가 비어있습니다.');
      return;
    }

    try {
      await _secureStorage!.delete(key: key);
    } on PlatformException catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.deleteEncrypted.platform',
      );
      debugPrint('LocalStorage.deleteEncrypted 오류: $e');
      // 삭제 실패는 무시
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.deleteEncrypted',
      );
      debugPrint('LocalStorage.deleteEncrypted 예상치 못한 오류: $e');
    }
  }

  /// FlutterSecureStorage에 저장된 모든 데이터를 삭제한다.
  Future<void> clearEncrypted() async {
    if (_secureStorage == null) {
      debugPrint('LocalStorage: FlutterSecureStorage가 초기화되지 않았습니다.');
      return;
    }

    try {
      await _secureStorage!.deleteAll();
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.clearEncrypted',
      );
      debugPrint('LocalStorage.clearEncrypted 오류: $e');
    }
  }

  /* ------------------ HIVE STORAGE (일반 저장소) ----------------------- */
  /// 비민감한 정보만 저장 (사용자 설정, 온보딩 상태 등)

  static Box? _hiveStorage;

  /// fortuna random algorithm을 활용해 Hive 데이터베이스 암호화에 사용될 수 있는 안전한 키를 생성한다.
  String generateSecureKey() => base64UrlEncode(Hive.generateSecureKey());

  /// listenable 메서드: 특정 키 또는 전체 Hive 박스의 변경사항을 감지하는 [ValueListenable] 객체를 반환한다.
  /// 이를 통해 데이터 변경사항을 UI에 실시간으로 반영할 수 있다.
  ///
  /// [keys]: 감지할 키 리스트 (null이면 전체 박스 감지)
  /// Returns: 변경사항을 감지할 수 있는 ValueListenable 객체
  /// Throws: Hive 박스가 초기화되지 않은 경우
  ValueListenable<Box<dynamic>> listenable({List<dynamic>? keys}) {
    if (_hiveStorage == null) {
      throw StateError('LocalStorage: Hive 박스가 초기화되지 않았습니다.');
    }
    return _hiveStorage!.listenable(keys: keys);
  }

  /// 주어진 [key]에 해당하는 값을 Hive 박스에서 가져온다. 키가 존재하지 않을 경우 기본값을 반환한다.
  ///
  /// [key]: 읽을 키
  /// [defaultValue]: 키가 없을 때 반환할 기본값
  /// Returns: 저장된 값 또는 기본값 또는 null
  T? getItem<T>(Object key, {T? defaultValue}) {
    if (_hiveStorage == null) {
      debugPrint('LocalStorage: Hive 박스가 초기화되지 않았습니다.');
      return defaultValue;
    }

    try {
      return _hiveStorage!.get(key, defaultValue: defaultValue);
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.getItem',
      );
      debugPrint('LocalStorage.getItem 오류: $e');
      // 오류 발생 시 해당 키 삭제 시도
      try {
        _hiveStorage?.delete(key);
      } catch (deleteError, deleteStackTrace) {
        ErrorReporter.ignoreExpected(
          deleteError,
          stackTrace: deleteStackTrace,
          context: 'LocalStorage.getItem.deleteCorruptedKey',
        );
        // 삭제 실패는 무시
      }
      return defaultValue;
    }
  }

  /// 주어진 키와 값을 Hive 박스에 저장한다. 값이 null일 경우 해당 키를 삭제한다.
  ///
  /// [key]: 저장할 키
  /// [value]: 저장할 값 (null이면 키 삭제)
  Future<void> saveItem<T>(Object key, T? value) async {
    if (_hiveStorage == null) {
      debugPrint('LocalStorage: Hive 박스가 초기화되지 않았습니다.');
      return;
    }

    try {
      if (value != null) {
        await _hiveStorage!.put(key, value);
      } else {
        await _hiveStorage!.delete(key);
      }
    } catch (e, stackTrace) {
      ErrorReporter.reportSync(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.saveItem',
      );
      debugPrint('LocalStorage.saveItem 오류: $e');
      rethrow;
    }
  }

  /// Hive 박스에 저장된 모든 데이터를 삭제한다.
  Future<void> clear() async {
    if (_hiveStorage == null) {
      debugPrint('LocalStorage: Hive 박스가 초기화되지 않았습니다.');
      return;
    }

    try {
      await _hiveStorage!.clear();
    } catch (e, stackTrace) {
      ErrorReporter.reportSync(
        e,
        stackTrace: stackTrace,
        context: 'LocalStorage.clear',
      );
      debugPrint('LocalStorage.clear 오류: $e');
      rethrow;
    }
  }
}
