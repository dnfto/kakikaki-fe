# Flutter 기본 변수
FLUTTER ?= flutter
DART ?= dart
ENV_FILE ?= dev.env

################################################################################
# FLAVOR 설정 주의사항
################################################################################
# 
# Android (productFlavors 필수):
#   - flutter run --flavor=dev 또는 --flavor=prod 필수
#   - build.gradle에서 dev/prod flavor 정의됨
#   - applicationId: TODO - 앱의 패키지명으로 변경 (예: com.example.app)
#   - (TODO: 추후 수정 방향) applicationId: com.example.app.dev (dev) / com.example.app (prod)
#
# iOS (Build Scheme 필수):
#   - Xcode scheme: "Debug-dev" (dev) 또는 "Debug" (prod)
#   - project.pbxproj에서 APP_FLAVOR 설정됨
#   - PRODUCT_BUNDLE_IDENTIFIER: TODO - 앱의 번들 ID로 변경 (예: com.example.app)
#   - (TODO: 추후 수정 방향) PRODUCT_BUNDLE_IDENTIFIER: com.example.app.dev (dev) / com.example.app (prod)
#
# Both Platforms (필수):
#   - --dart-define=FLAVOR=dev 또는 --dart-define=FLAVOR=prod 필수
#   - Config.initialize()에서 native platform에서 flavor 감지
#
# 환경 설정 파일 (루트에 위치):
#   - dev.env: 개발 환경 변수 (테스트 API URL, 테스트 카카오 키 등)
#   - prod.env: 프로덕션 환경 변수 (실제 API URL, 프로드 카카오 키 등)
#
################################################################################

# 도움말
help:
	@echo "Flutter 프로젝트 - Flavor 기반 빌드 시스템"
	@echo ""
	@echo "=== 앱 실행 (추천) ===";
	@echo "  make run-dev              - 개발 앱 실행 (dev 환경)"
	@echo "  make run-prod             - 프로덕션 앱 실행 (prod 환경)"
	@echo ""
	@echo "=== 빌드 (Android) ===";
	@echo "  make android-dev-build    - Android 디버그 APK 빌드 (dev flavor)"
	@echo "  make android-prod-build   - Android AAB 릴리즈 빌드 (prod flavor, Play Store 용)"
	@echo ""
	@echo "=== 빌드 (iOS) ===";
	@echo "  make ios-dev-build        - iOS 디버그 빌드 (dev flavor, macOS 전용)"
	@echo "  make ios-prod-build       - iOS 릴리즈 빌드 (prod flavor, App Store 용, macOS 전용)"
	@echo ""
	@echo "===  프로젝트 관리 ===";
	@echo "  make init                 - 프로젝트 초기화 (클론 후 1회 실행)"
	@echo "  make splash               - 스플래시 화면 생성"
	@echo "  make icons                - 앱 아이콘 생성"
	@echo "  make ios-env              - iOS용 env → xcconfig 생성 (dev.env/prod.env 변경 후 실행)"
	@echo "  make clean-all            - 전체 빌드 캐시 및 의존성 초기화"
	@echo "  make generate             - 코드 생성만 별도로 실행"
	@echo ""
	@echo "=== 테스트 & 분석 ===";
	@echo "  make test                 - 테스트 실행"
	@echo "  make analyze              - 코드 정적 분석"
	@echo "  make warning              - Warning 찾기"
	@echo "  make l10n                 - 다국어 지원 파일 생성"
	@echo ""
	@echo "=== Git 관리 ===";
	@echo "  make git-rm-cached FILE_PATH=<경로>  - Git 캐시에서 파일 제거 (파일은 로컬에 유지)"
	@echo "  make git-remove-history FILE_PATH=<경로>  - 과거 커밋에서 파일 완전 제거 (주의: 히스토리 재작성)"
	@echo ""

# 테스트 및 분석
test:
	$(FLUTTER) test

analyze:
	$(FLUTTER) analyze

# 초기화 (tool/init.dart 사용)
init:
	$(DART) run tool/init.dart

splash:
	$(DART) run flutter_native_splash:create

# 아이콘 생성 (flutter_launcher_icons 사용)
icons:
	$(FLUTTER) pub run flutter_launcher_icons:main

# 코드 생성
generate:
	$(DART) run build_runner build --delete-conflicting-outputs

# iOS: dev.env / prod.env → Env.dev.xcconfig, Env.prod.xcconfig (Kakao/Google 키 등)
ios-env:
	@echo "iOS env → xcconfig 생성 중..."
	@bash "$(CURDIR)/scripts/ios_env_from_env.sh"
	@echo "Env.dev.xcconfig, Env.prod.xcconfig 생성 완료."

################################################################################
# 앱 실행 (추천)
# 사용: make run-dev 또는 make run-prod
# 환경별 Firebase 설정을 사용하여 앱 실행
################################################################################
run-dev:
	@echo "개발 앱 실행 (dev flavor, dev.env, Firebase Dev 프로젝트)"
	$(FLUTTER) run --flavor dev -t lib/main.dart --dart-define-from-file=dev.env --dart-define=FLAVOR=dev

run-prod:
	@echo "프로덕션 앱 실행 (prod flavor, prod.env, Firebase Prod 프로젝트)"
	$(FLUTTER) run --flavor prod -t lib/main.dart --dart-define-from-file=prod.env --dart-define=FLAVOR=prod

################################################################################
# Android 빌드
# - dev-build: flavor=dev, debug 모드
# - prod-build: flavor=prod, release 모드 (Play Store 배포용)
################################################################################
android-dev-build:
	@echo " Android 개발 빌드 (APK, dev flavor, Firebase Dev)"
	$(FLUTTER) build apk --debug --flavor=dev -t lib/main.dart --dart-define-from-file=dev.env --dart-define=FLAVOR=dev
	@echo "빌드 완료: build/app/outputs/flutter-apk/app-dev-debug.apk"

android-dev-build-release:
	@echo " Android 개발 빌드 (AAB, dev flavor, Firebase Dev - Play 내부 테스트용)"
	$(FLUTTER) build appbundle --release --flavor=dev -t lib/main.dart --dart-define-from-file=dev.env --dart-define=FLAVOR=dev
	@echo "빌드 완료: build/app/outputs/bundle/devRelease/app-dev-release.aab"

android-prod-build:
	@echo " Android 프로덕션 빌드 (AAB, prod flavor, Firebase Prod - Play Store 용)"
	$(FLUTTER) build appbundle --release --flavor=prod -t lib/main.dart --dart-define-from-file=prod.env --dart-define=FLAVOR=prod
	@echo "빌드 완료: build/app/outputs/bundle/prodRelease/app-prod-release.aab"

################################################################################
# iOS 빌드 (macOS 전용)
# - dev-build: flavor=dev, debug 모드
# - prod-build: flavor=prod, release 모드 (App Store 배포용)
################################################################################
ios-dev-build:
	@if [[ "$$OSTYPE" == "darwin"* ]]; then \
		echo " iOS 개발 빌드 (dev flavor, Firebase Dev)"; \
		$(FLUTTER) build ios --debug --flavor=dev -t lib/main.dart --dart-define-from-file=dev.env --dart-define=FLAVOR=dev; \
		echo "빌드 완료: build/ios/Debug-dev/Runner.app"; \
	else \
		echo "iOS 빌드는 macOS 환경에서만 실행 가능"; \
	fi

ios-prod-build:
	@if [[ "$$OSTYPE" == "darwin"* ]]; then \
		echo " iOS 프로덕션 빌드 (IPA, prod flavor, Firebase Prod - App Store 용)"; \
		$(FLUTTER) build ipa --release --flavor=prod -t lib/main.dart --dart-define-from-file=prod.env --dart-define=FLAVOR=prod; \
		echo "빌드 완료: build/ios/ipa/"; \
	else \
		echo "iOS 빌드는 macOS 환경에서만 실행 가능"; \
	fi

################################################################################
# 클린 & 초기화
################################################################################
clean-all:
	@echo "전체 캐시 및 빌드 파일 삭제 중..."
	rm -rf build .dart_tool .packages pubspec.lock
	rm -rf ios/Pods ios/Runner.xcworkspace ios/build
	rm -rf android/.gradle android/build
	rm -rf macos/Pods macos/Runner.xcworkspace
	$(FLUTTER) clean
	@echo "클린 완료! pub get 진행 중..."
	$(FLUTTER) pub get
	cd ios && pod install --repo-update
	cd ..
	@echo "코드 생성 중..."
	make generate
	@echo "모든 초기화 완료!"

################################################################################
# 다국어 & 로컬라이제이션
################################################################################
l10n:
	@echo "다국어 지원 파일 생성 중..."
	$(DART) run arb_merger
	$(FLUTTER) gen-l10n
	@echo "다국어 파일 생성 완료!"

################################################################################
# 코드 분석
################################################################################
warning:
	@echo " Warning 찾기 (생성 파일 제외)..."
	$(FLUTTER) analyze | grep warning | grep -v '\.g\.dart' | grep -v 'freezed\.dart'

################################################################################
# Firebase 다운로드 (필요시 URL 변경)
################################################################################
download-firebase:
	@echo " Firebase 설정 파일 다운로드 중..."
	curl -o android/app/google-services.json https://example.com/firebase-dev.json
	curl -o ios/Runner/GoogleService-Info.plist https://example.com/firebase-dev.plist
	@echo "Firebase 설정 완료!"


################################################################################
# Git 관리
# 사용: make git-rm-cached FILE_PATH=lib/firebase_options.dart
#      make git-remove-history FILE_PATH=.metadata
################################################################################
git-rm-cached:
	@if [ -z "$(FILE_PATH)" ]; then \
		echo "오류: FILE_PATH를 지정해주세요. 예: make git-rm-cached FILE_PATH=lib/firebase_options.dart"; \
		exit 1; \
	fi
	@echo "Git 캐시에서 파일 제거 중: $(FILE_PATH)"
	git rm --cached $(FILE_PATH)
	@echo "완료: $(FILE_PATH) 파일이 Git 캐시에서 제거되었습니다. (로컬 파일은 유지됨)"

git-remove-history:
	@if [ -z "$(FILE_PATH)" ]; then \
		echo "오류: FILE_PATH를 지정해주세요. 예: make git-remove-history FILE_PATH=.metadata"; \
		exit 1; \
	fi
	@echo "경고: 이 작업은 Git 히스토리를 재작성!"
	@echo "원격 저장소에 push하려면 force push가 필요"
	@echo "계속하시겠습니까? (y/N)"
	@read -r confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "과거 커밋에서 파일 제거 중: $(FILE_PATH)"
	git filter-repo --path $(FILE_PATH) --invert-paths --force
	@echo "완료: $(FILE_PATH) 파일이 모든 과거 커밋에서 제거되었습니다."
	@echo "원격 저장소에 push하려면: git push origin --force --all --tags"


# Supabase 관리
supa-deploy:
	@echo "Supabase 배포 중..."
	# supabase functions deploy gemini-agent
	supabase functions deploy gemini-agent --no-verify-jwt
	supabase functions deploy delete-account --no-verify-jwt
	@echo "Supabase 배포 완료!"

make splash:
	@echo "Splash 이미지 생성 중..."
	@flutter pub run flutter_native_splash:create
	@echo "Splash 이미지 생성 완료!"

make app-icons:
	@echo "앱 아이콘 생성 중..."
	@flutter pub run flutter_launcher_icons:main
	@echo "앱 아이콘 생성 완료!"