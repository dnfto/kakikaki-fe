# カキカキ
카키카키 Flutter와 Django 기반으로 개발된 프로젝트입니다.
해당 프로젝트는 Dart Script를 사용하여 코드 실행을 간소화했습니다.

## Tech Stack
- **FrontEnd**: Dart / Flutter
- **BackEnd**: SUpabase

## 설치 및 실행 방법
### 1. 프로젝트 세팅
프로젝트 최초 세팅을 위해 아래 명령어를 실행.
```bash
dart run tool/init.dart
```
위 명령어는 의존성 설치 및 코드 자동 생성을 포함

### 2. 코드 생성 (수동 실행)
자동 코드 생성만을 원할 경우 아래 명령어를 실행.
```bash
dart run build_runner build -d
```

### 3. 앱 실행
앱을 실행하려면 다음 명령어를 사용.
```bash
dart run tool/run.dart --env=dev.env
```
환경 파일은 `dev.env`, `prod.env` 등으로 설정할 수 있습니다.

## 빌드 (배포)
### 1. Android 빌드
```bash
dart run tool/build.dart --env=dev.env  # 개발용 APK 빌드
dart run tool/build.dart --env=prod.env # 배포용 AAB 빌드
```
- 개발용 APK 빌드: `dev.env` 환경 사용
- 배포용 AAB 빌드: `prod.env` 환경 사용

### 2. iOS 빌드 (MacOS 환경 필요)
```bash
dart run tool/build.dart --env=dev.env  # 개발용 IPA 빌드
dart run tool/build.dart --env=prod.env # 배포용 IPA 빌드
```

## 주의 사항
- 프로젝트 실행 전 `dev.env` 또는 `prod.env` 환경 파일이 필요
- iOS 빌드는 반드시 macOS 환경에서 실행해야 
- `.env` 환경 파일이 없을 경우 `.env.example`을 참고하여 생성.
  - `cp .env.example dev.env`
  - `cp .env.example prod.env`