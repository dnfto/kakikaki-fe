import 'dart:io';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class KanjiDbHelper {
  static Database? _database;
  static final Map<String, String> _svgCache = {}; // SVG 데이터 캐싱

  // DB 객체 가져오기 (싱글턴 패턴)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    // 1. 스마트폰 내부의 데이터베이스 경로 찾기
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "kanji.db");

    // 2. 파일이 이미 존재하는지 확인
    var exists = await databaseExists(path);

    if (!exists) {
      // 3. 존재하지 않는다면(앱 최초 실행), assets에서 폰으로 복사!
      Log.i('Assets에서 DB를 복사합니다...', name: 'KanjiDbHelper');
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load("assets/data/kanji.db");
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e, stackTrace) {
        ErrorReporter.reportSync(
          e,
          stackTrace: stackTrace,
          context: 'KanjiDbHelper.copyDatabase',
        );
      }
    }

    // 4. 복사된 DB 열기
    return await openDatabase(path);
  }

  /// 특정 한자(예: '領')를 넣으면 SVG 텍스트를 반환하는 함수
  static Future<String?> getSvgData(String kanji) async {
    // 캐시에서 먼저 확인
    if (_svgCache.containsKey(kanji)) {
      return _svgCache[kanji];
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kanji_data',
      columns: ['svg_data'],
      where: 'character = ?',
      whereArgs: [kanji],
    );

    if (maps.isNotEmpty) {
      final svgData = maps.first['svg_data'] as String;
      _svgCache[kanji] = svgData; // 캐시에 저장
      return svgData;
    }
    return null; // DB에 해당 한자가 없을 경우
  }

  /// 캐시 초기화 (메모리 관리용)
  static void clearCache() {
    _svgCache.clear();
  }
}
