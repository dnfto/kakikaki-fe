/*
< 기능 >
- `flutter pub get` 실행
- `build_runner`을 통한 코드 생성 수행
- `flutter build apk` 실행 (`--dart-define-from-file`을 사용해 환경변수 파일을 지정 가능)

< 빌드 실행 예시 >
- `dart run tool/build.dart --env=dev.env`: `dev.env` 환경변수 파일을 사용해 빌드 실행
- `dart run tool/build.dart --env=prod.env`: `prod.env` 환경변수 파일을 사용해 빌드 실행

< 기타 >
- `flutter build apk` 대신 `flutter build ios`로 변경하면 iOS 빌드 가능
- 매번 `dart run tool/build.dart`를 입력하기 번거로우면 터미널에서 alias 설정을 통해 간편하게 실행 가능
  1. `echo "alias build='dart run tool/build.dart'" >> ~/.zshrc`
  2. source ~/.zshrc
  ---
  Windows - `Set-Alias -Name build -Value "dart run tool/build.dart"`
 */
import 'dart:io';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(methodCount: 0), // CLI에 적합하게 간단 출력
);
void main(List<String> args) {
  final envFile = _getArgValue(args, '--env', 'dev.env');

  logger.i('플러터 빌드 with $envFile');
  _runCommand('flutter', ['pub', 'get']);
  _runCommand(
      'dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);
  _runCommand('flutter',
      ['build', 'apk', '--release', '--dart-define-from-file=$envFile']);

  logger.i('빌드 완료!');
}

/// 명령어 인자를 파싱하는 함수
String _getArgValue(List<String> args, String key, String defaultValue) {
  for (var arg in args) {
    if (arg.startsWith(key)) {
      return arg.split('=').last;
    }
  }
  return defaultValue;
}

/// 명령어 실행 함수
void _runCommand(String command, List<String> arguments) {
  final result = Process.runSync(command, arguments, runInShell: true);
  if (result.stdout.isNotEmpty) logger.i(result.stdout);
  if (result.stderr.isNotEmpty) logger.e(result.stderr);
}
