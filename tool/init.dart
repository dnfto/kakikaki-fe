/*
<기능>
- Flutter 프로젝트 초기화 스크립트
- `flutter clean` 실행: 불필요한 파일 삭제
- `flutter pub get` 실행: 의존성 설치
- `build_runner`실행: 코드 자동 생성 수행
 */
import 'dart:io';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(methodCount: 0), // 깔끔한 CLI 출력
);

void main() {
  logger.i('Flutter 프로젝트 초기화 시작...');

  _runCommand('flutter', ['clean']);
  _runCommand('flutter', ['pub', 'get']);
  _runCommand(
      'dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);

  logger.i('초기화 완료!');
}

/// 명령어 실행 함수
void _runCommand(String command, List<String> arguments) {
  final result = Process.runSync(command, arguments, runInShell: true);
  if (result.stdout.isNotEmpty) logger.i(result.stdout);
  if (result.stderr.isNotEmpty) logger.e(result.stderr);
}
