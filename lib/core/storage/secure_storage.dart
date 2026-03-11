import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/error/error_reporter.dart';

/// FlutterSecureStorage 래퍼 클래스
///
/// **⚠️ Deprecated**: 이 클래스는 더 이상 사용되지 않습니다.
/// 새로운 코드는 `LocalStorage.getEncrypted()` / `LocalStorage.saveEncrypted()`를 사용하세요.
///
/// 이 클래스는 레거시 코드와의 호환성을 위해 유지되지만, 곧 제거될 예정입니다.
/// 모든 코드가 `LocalStorage`로 마이그레이션되었습니다.
@Deprecated('Use LocalStorage instead')
@singleton
class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// 암호화된 데이터를 저장
  ///
  /// [key]: 저장할 키
  /// [value]: 저장할 값
  Future<void> writeSecureData(String key, String value) async {
    if (key.isEmpty) {
      debugPrint('SecureStorage.writeSecureData: 키가 비어있습니다.');
      return;
    }

    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e, stackTrace) {
      ErrorReporter.reportSync(
        e,
        stackTrace: stackTrace,
        context: 'SecureStorage.writeSecureData.platform',
      );
      debugPrint('SecureStorage.writeSecureData 오류: $e');
      rethrow;
    } catch (e, stackTrace) {
      ErrorReporter.reportSync(
        e,
        stackTrace: stackTrace,
        context: 'SecureStorage.writeSecureData',
      );
      debugPrint('SecureStorage.writeSecureData 예상치 못한 오류: $e');
      rethrow;
    }
  }

  /// 암호화된 데이터를 읽기
  ///
  /// [key]: 읽을 키
  /// Returns: 저장된 값 또는 null
  Future<String?> readSecureData(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'SecureStorage.readSecureData.platform',
      );
      debugPrint('SecureStorage.readSecureData 오류: $e');
      return null;
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'SecureStorage.readSecureData',
      );
      debugPrint('SecureStorage.readSecureData 예상치 못한 오류: $e');
      return null;
    }
  }

  /// 암호화된 데이터 삭제
  ///
  /// [key]: 삭제할 키
  Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'SecureStorage.deleteSecureData.platform',
      );
      debugPrint('SecureStorage.deleteSecureData 오류: $e');
      // 삭제 실패는 무시
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'SecureStorage.deleteSecureData',
      );
      debugPrint('SecureStorage.deleteSecureData 예상치 못한 오류: $e');
    }
  }

  /// 모든 암호화된 데이터 삭제
  Future<void> deleteAllSecureData() async {
    try {
      await _storage.deleteAll();
    } catch (e, stackTrace) {
      ErrorReporter.reportSync(
        e,
        stackTrace: stackTrace,
        context: 'SecureStorage.deleteAllSecureData',
      );
      debugPrint('SecureStorage.deleteAllSecureData 오류: $e');
      rethrow;
    }
  }
}
