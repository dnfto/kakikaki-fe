import 'dart:ui';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/domain/entity/user.dart';
import 'package:kakikaki/app/enums/auth_enums.dart';
import 'package:kakikaki/core/network/base_repository.dart';
import 'package:kakikaki/core/error/error_reporter.dart';

/// GlobalState 저장소 인터페이스
abstract class GlobalStateRepository {
  /// 초기 상태를 로드합니다.
  ///
  /// [isLoggedIn]: 현재 로그인 상태
  /// Returns: 로드된 또는 생성된 초기 상태
  Future<GlobalState> loadInitialState(bool isLoggedIn);

  /// 상태를 저장합니다.
  ///
  /// [state]: 저장할 상태
  Future<void> saveState(GlobalState state);
}

/// GlobalState 저장소 구현체
///
/// Hive를 사용하여 GlobalState를 영구 저장하고,
/// 데이터 마이그레이션을 처리합니다.
@Singleton(as: GlobalStateRepository)
class GlobalStateRepositoryImpl extends BaseRepository
    implements GlobalStateRepository {
  GlobalStateRepositoryImpl() : super('global-state');

  Box<GlobalState>? _appStatebox;

  @override
  Future<GlobalState> loadInitialState(bool isLoggedIn) async {
    _appStatebox ??= await _openBoxSafely();

    final initialState = _appStatebox!.isEmpty
        ? _createInitialState(isLoggedIn)
        : _loadOrCreateState(isLoggedIn, _appStatebox!);

    await _appStatebox!.put(0, initialState);
    return initialState;
  }

  @override
  Future<void> saveState(GlobalState state) async {
    try {
      await _appStatebox?.put(0, state);
    } catch (e, stackTrace) {
      await ErrorReporter.report(
        e,
        stackTrace: stackTrace,
        context: 'GlobalStateRepository.saveState',
      );
      rethrow;
    }
  }

  Future<Box<GlobalState>> _openBoxSafely() async {
    const boxName = 'GlobalBloc';

    try {
      final box = await Hive.openBox<GlobalState>(boxName)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Hive Box 열기 타임아웃 (15초)');
      });

      if (box.isNotEmpty) {
        try {
          final savedData = box.get(0);
          if (savedData is! GlobalState) {
            return await _migrateBox(boxName);
          }
        } catch (e, stackTrace) {
          ErrorReporter.ignoreExpected(
            e,
            stackTrace: stackTrace,
            context: 'GlobalState box validation migrate',
          );
          return await _migrateBox(boxName);
        }
      }

      return box;
    } on HiveError catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'Hive type error migrate',
      );
      return await _migrateBox(boxName);
    } catch (e, stackTrace) {
      await ErrorReporter.report(
        e,
        stackTrace: stackTrace,
        context: 'GlobalState box open recreate',
      );
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (deleteError, deleteStackTrace) {
        ErrorReporter.ignoreExpected(
          deleteError,
          stackTrace: deleteStackTrace,
          context: 'Hive box delete from disk failed',
        );
      }
      return await Hive.openBox<GlobalState>(boxName);
    }
  }

  Future<Box<GlobalState>> _migrateBox(String boxName) async {
    try {
      final dynamicBox = await Hive.openBox(boxName);
      if (dynamicBox.isNotEmpty) {
        final oldData = dynamicBox.get(0);
        final migratedState = _migrateDataIfNeeded(oldData);
        await dynamicBox.close();
        await Hive.deleteBoxFromDisk(boxName);
        final newBox = await Hive.openBox<GlobalState>(boxName);
        await newBox.put(0, migratedState);
        return newBox;
      } else {
        await dynamicBox.close();
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<GlobalState>(boxName);
      }
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'GlobalState migrate fallback recreate',
      );
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (deleteError, deleteStackTrace) {
        ErrorReporter.ignoreExpected(
          deleteError,
          stackTrace: deleteStackTrace,
          context: 'GlobalState migrate delete failed',
        );
      }
      return await Hive.openBox<GlobalState>(boxName);
    }
  }

  GlobalState _migrateDataIfNeeded(dynamic savedData) {
    if (savedData is GlobalState) return savedData;

    if (savedData is Map) {
      try {
        return _migrateFromMap(Map<String, dynamic>.from(savedData));
      } catch (e, stackTrace) {
        ErrorReporter.ignoreExpected(
          e,
          stackTrace: stackTrace,
          context: 'GlobalState map migration failed',
        );
        return _createDefaultState();
      }
    }

    return _createDefaultState();
  }

  GlobalState _migrateFromMap(Map<String, dynamic> map) {
    final hasToken = (map['accessToken'] as String?)?.isNotEmpty ?? false;

    return GlobalState(
      languageCode: map['languageCode'] as String? ?? 'ko',
      themeMode: map['themeMode'] as String? ?? 'system',
      user: map['user'] as User?,
      isLoggedIn: map['isLoggedIn'] as bool? ?? hasToken,
      socialType: map['socialType'] as SocialType?,
    );
  }

  GlobalState _createDefaultState() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final detectedLanguageCode = _detectLanguageFromSystem(systemLocale);
    return GlobalState(
      languageCode: detectedLanguageCode,
      themeMode: 'system',
    );
  }

  GlobalState _createInitialState(bool isLoggedIn) {
    final systemLocale = PlatformDispatcher.instance.locale;
    final languageCode = _detectLanguageFromSystem(systemLocale);
    return GlobalState(
      languageCode: languageCode,
      isLoggedIn: isLoggedIn,
      themeMode: 'system',
    );
  }

  GlobalState _loadOrCreateState(bool isLoggedIn, Box<GlobalState> box) {
    try {
      final savedData = box.get(0);
      if (savedData != null) {
        final migratedState = _migrateDataIfNeeded(savedData);
        return migratedState.copyWith(isLoggedIn: isLoggedIn);
      }
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'GlobalState saved state load failed',
      );
    }
    return _createInitialState(isLoggedIn);
  }

  String _detectLanguageFromSystem(Locale systemLocale) {
    final code = systemLocale.languageCode;
    const supportedLanguages = {'ko', 'en', 'ja', 'id'};
    return supportedLanguages.contains(code) ? code : 'en';
  }
}
