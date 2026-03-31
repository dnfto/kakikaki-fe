# カキカキ (kakikaki)
**카키카키**는 Flutter와 Supabase를 기반으로 한 일본어 학습 지원 애플리케이션입니다. 
---

## Tech Stack

- **FrontEnd**: Flutter (Dart)
- **BackEnd**: Supabase

---

## 브랜치 전략 (Branch Strategy)

본 프로젝트는 효율적인 협업과 안정적인 배포를 위해 **Git Flow** 기반의 브랜치 전략을 사용합니다.
아래는 팀원이 2명 이상일 경우 시나리오이며,
현재는 1인 개발로 진행되고 있는 관계로 개발 편의성을 위해 `main`, `develop` 브랜치만 운용합니다.
필요 시 `feat/` 브랜치도 간헐적으로 운용합니다.

### 1. 브랜치 구조
| 브랜치명 | 역할 | 설명 |
| :--- | :--- | :--- |
| **`main`** | **배포 브랜치** | 스토어에 출시된 가장 안정적인 코드입니다. 직접 커밋하지 않습니다. |
| **`release/`** | **출시 준비** | 심사 전 최종 버그 수정 및 버전(`pubspec.yaml`)을 조정하는 단계입니다. |
| **`develop`** | **개발 중심** | 다음 버전 출시를 위해 모든 기능이 합쳐지는 메인 개발 브랜치입니다. |
| **`feat/`** | **기능 개발** | 새로운 기능 단위로 생성하며, 작업 완료 후 `develop`으로 합칩니다. |
| **`hotfix/`** | **긴급 수정** | 출시된 앱에서 발견된 치명적인 버그를 급히 수정할 때 사용합니다. |

### 2. 작업 흐름 (Workflow)
1. 새로운 기능을 만들 때는 `develop`에서 **`feat/기능명`** 브랜치를 생성합니다.
2. 기능 구현이 끝나면 `develop` 브랜치로 **Pull Request (PR)**를 보냅니다.
3. 배포 시점이 되면 `develop`에서 **`release/vX.X.X`**를 생성하여 최종 점검을 수행합니다.
4. 배포가 완료되면 `main`에 병합하고 **버전 태그(Tag)**를 답니다. 수정 사항은 `develop`에도 반영합니다.

---

## 시작하기 (Setup)

### 1. 환경 변수 설정

프로젝트 실행을 위해 환경별 `.env` 파일이 필요합니다. `.env.example` 파일을 참고하여 생성하세요.

```bash
# 개발 환경용 설정
cp .env.example dev.env

# 프로덕션 환경용 설정
cp .env.example prod.env
```

### 2. 프로젝트 초기화

의존성 설치, iOS Pod 설치, 코드 생성을 한 번에 수행합니다.

```bash
make init
```

---

## 개발 및 실행 (Development)

모든 실행 명령어는 Flavor(`dev` / `prod`) 구분을 지원합니다.

### 앱 실행

| 명령어        | 설명                                           |
| ------------- | ---------------------------------------------- |
| `make run-dev`  | 개발 환경 실행 (dev flavor / `dev.env`)        |
| `make run-prod` | 프로덕션 환경 실행 (prod flavor / `prod.env`) |

### 코드 생성 및 UI 관리

| 명령어           | 설명                                                                 |
| ---------------- | -------------------------------------------------------------------- |
| `make generate`  | 코드 자동 생성 (`build_runner`)                                      |
| `make l10n`      | 다국어 파일(L10n) 생성                                               |
| `make splash`    | 스플래시 화면 생성                                                   |
| `make icons`     | 앱 아이콘 생성                                                       |
| `make ios-env`   | iOS용 환경설정 동기화 (`dev.env` / `prod.env` 변경 후 실행) |

---

## 빌드 및 배포 (Build)

### Android 빌드

```bash
# 개발용 APK 빌드 (Debug)
make android-dev-build

# 스토어 배포용 AAB 빌드 (Release, Play Store용)
make android-prod-build
```

### iOS 빌드 (macOS 전용)

```bash
# 개발용 빌드 (Debug Scheme)
make ios-dev-build

# 앱스토어 배포용 IPA 빌드 (Release, App Store용)
make ios-prod-build
```

### Supabase Edge Functions 배포

```bash
# Gemini Agent 및 계정 삭제 함수 등 배포
make supa-deploy
```

---

## 유지보수 및 유틸리티

### 프로젝트 클린 (전체 초기화)

빌드 캐시, 의존성, iOS Pods, 생성된 파일을 모두 지우고 다시 설치합니다. 코드가 꼬였을 때 사용하세요.

```bash
make clean-all
```

### 코드 분석 및 테스트

| 명령어         | 설명                                      |
| -------------- | ----------------------------------------- |
| `make analyze` | 정적 분석                                 |
| `make warning` | 경고(Warning) 확인 (생성된 파일 제외)     |
| `make test`    | 유닛 테스트                               |

### Git 관리 (민감 정보 제거 등)

| 명령어 | 설명 |
| ------ | ---- |
| `make git-rm-cached FILE_PATH=<경로>` | 캐시에서 파일 제거 (로컬 파일은 유지) |
| `make git-remove-history FILE_PATH=<경로>` | 히스토리에서 파일 완전 삭제 (**주의: 히스토리 재작성**) |

---

## 주의 사항

- **Flavor 설정**: Android는 `build.gradle`에, iOS는 Xcode Scheme에 각 flavor(`dev` / `prod`)가 정의되어 있어야 합니다.
- **iOS 환경**: iOS 관련 빌드 및 `ios-env` 명령어는 **반드시 macOS** 환경에서 실행해야 합니다.
- **Firebase**: 환경별 Firebase 설정(`google-services.json`, `GoogleService-Info*.plist` 등)이 올바른지 확인하세요.

---

## 명령어 도움말

전체 명령어 목록은 터미널에서 아래와 같이 입력하여 확인할 수 있습니다.

```bash
make help
```
