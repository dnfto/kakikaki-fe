/*
< 기능 >
- `flutter pub get` 실행
- `build_runner`을 통한 코드 생성 수행
- `flutter run` 실행 (`--dart-define-from-file`을 사용해 환경변수 파일을 지정 가능)
- Flavor 지원 (dev, prod)

< 앱 실행 예시 >
- `dart run tool/run.dart --env=dev.env`: dev 환경에서 실행
- `dart run tool/run.dart --env=prod.env`: prod 환경에서 실행
- `dart run tool/run.dart --env=prod.env --device-id=<device_id>`: 특정 디바이스에서 실행

< 기타 >
- `flutter build apk` 대신 `flutter build ios`로 변경하면 iOS 빌드 가능
- 매번 `dart run tool/run.dart`를 입력하기 번거로우면 터미널에서 alias 설정을 통해 간편하게 실행 가능
  1. `echo "alias run='dart run tool/run.dart'" >> ~/.zshrc`
  2. source ~/.zshrc
 */

import 'dart:io';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(methodCount: 0), // 깔끔한 CLI 출력
);

void main(List<String> args) async {
  final envFile = _getArgValue(args, '--env', 'dev.env');
  final flavor = _getFlavor(envFile);
  final deviceId = _getArgValue(args, '--device-id', '');

  logger.i('플러터 앱 실행 with $envFile (flavor: $flavor)');
  _runCommand('flutter', ['pub', 'get']);
  _runCommand(
      'dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);

  // flavor와 dart-define을 함께 전달
  final flutterArgs = [
    'run',
    '--uninstall-first',
    '--flavor=$flavor',
    '--dart-define-from-file=$envFile',
    '--dart-define=FLAVOR=$flavor',
  ];

  if (deviceId.isNotEmpty) {
    flutterArgs.addAll(['-d', deviceId]);
  }

  await _runInteractiveCommand('flutter', flutterArgs);

  logger.i('앱 시작!');
}

/// 환경 파일명에서 flavor를 추출하는 함수
String _getFlavor(String envFile) {
  if (envFile.contains('prod')) {
    return 'prod';
  } else if (envFile.contains('dev')) {
    return 'dev';
  }
  return 'dev'; // 기본값
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

/// 명령어 실행 함수 (일반 명령용)
void _runCommand(String command, List<String> arguments) {
  final result = Process.runSync(command, arguments, runInShell: true);
  if (result.stdout.isNotEmpty) logger.i(result.stdout);
  if (result.stderr.isNotEmpty) logger.e(result.stderr);
}

/// Interactive 명령 실행 함수 (flutter run 같은 사용자 입력이 필요한 명령용)
Future<void> _runInteractiveCommand(
    String command, List<String> arguments) async {
  try {
    final process = await Process.start(
      command,
      arguments,
      runInShell: true,
      mode: ProcessStartMode
          .inheritStdio, // stdin/stdout/stderr를 상속하여 interactive하게 작동
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      logger.e(
          '명령 실행 실패: $command ${arguments.join(" ")} (Exit code: $exitCode)');
    }
  } catch (e) {
    logger.e('명령 실행 오류: $e');
  }
}
