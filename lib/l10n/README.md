# 다국어 파일 구조

이 프로젝트는 **feature별**로 다국어 파일을 분리하여 관리합니다.

## 파일 구조

```
lib/l10n/
├── ko/                    # 한국어
│   ├── common.arb        # 공통 다국어 (삭제, 만들기, 수정, 재시도, 다이얼로그 등)
│   ├── custom.arb        # 기타 커스텀 (캘린더, 마이/설정, 문의, 탈퇴 등)
│   ├── home.arb          # 홈 feature
│   ├── grammar.arb       # 문법 feature
│   ├── auth.arb          # 로그인
│   ├── diary.arb         # 일기
│   ├── study.arb         # 학습
│   ├── vocabulary.arb    # 단어장
│   └── ai_agent.arb      # AI 채팅
├── en/
│   └── (동일 구조)
└── ja/
    └── (동일 구조)
```

## 파일별 설명

### common.arb
- 공통으로 사용되는 다국어
- 예: 날짜 형식, 시간 표시, 검증 메시지, 네트워크 에러, 다이얼로그 버튼(`action_cancel`, `action_confirm`) 등

### custom.arb
- 기타 커스텀 다국어
- 예: 캘린더, 설정, 업데이트 등

### feature별 arb 파일 (home.arb, grammar.arb 등)
- 각 feature에 특화된 다국어
- feature 이름과 동일한 파일명 사용
- 예: `lib/features/home/` → `home.arb`

## 새로운 feature 추가 방법

1. 각 언어 폴더(`ko/`, `en/`, `ja/`)에 feature 이름으로 `.arb` 파일 생성
   - 예: `lib/features/auth/` → `auth.arb`
   - 예: `lib/features/template/` → `template.arb`

2. 파일 형식:
```json
{
  "@@locale": "ko",
  "feature_key_name": "값"
}
```

3. 키 네이밍 규칙:
   - feature 이름을 prefix로 사용
   - 예: `home_today_topic`, `home_diary_body` 등

4. `arb_merger`가 자동으로 모든 arb 파일을 병합합니다
   - `make l10n` 또는 `dart run arb_merger` 실행

## 사용 예시

```dart
// common.arb의 키 사용
context.l10n.network_error_title
context.l10n.network_error_content
context.l10n.action_cancel
context.l10n.action_confirm

// home.arb의 키 사용
context.l10n.home_today_topic
context.l10n.home_diary_body
context.l10n.home_ai_feedback
```

## 주의사항

- 각 언어별로 동일한 키를 모두 정의해야 합니다
- 키 이름은 `snake_case`를 사용하며, feature 이름을 prefix로 사용합니다
- `arb_merger` 실행 후 `flutter gen-l10n`을 실행하여 코드를 생성합니다
