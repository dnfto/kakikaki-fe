#!/usr/bin/env bash
# dev.env / prod.env 내용을 읽어 ios/Env.dev.xcconfig, ios/Env.prod.xcconfig 생성
# 프로젝트 루트에서 실행: ./scripts/ios_env_from_env.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"

read_env_value() {
  local env_file="$1"
  local key="$2"
  if [[ -f "$env_file" ]]; then
    grep -E "^${key}=" "$env_file" 2>/dev/null | head -1 | cut -d= -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true
  fi
}

# GOOGLE_IOS_CLIENT_ID (XXX.apps.googleusercontent.com) → iOS URL scheme (REVERSED_CLIENT_ID)
client_id_to_url_scheme() {
  local client_id="$1"
  if [[ -z "$client_id" ]]; then
    echo ""
    return
  fi
  if [[ "$client_id" == *.apps.googleusercontent.com ]]; then
    echo "com.googleusercontent.apps.${client_id%.apps.googleusercontent.com}"
  else
    echo "$client_id"
  fi
}

write_xcconfig() {
  local env_file="$1"
  local out_file="$2"
  local kakao_key
  local maps_key
  local google_scheme
  local flavor_name

  flavor_name="$(basename "$env_file" .env)"
  kakao_key="$(read_env_value "$env_file" "KAKAO_NATIVE_APP_KEY")"
  maps_key="$(read_env_value "$env_file" "GOOGLE_MAPS_API_KEY")"
  # prod.env / dev.env 의 GOOGLE_IOS_CLIENT_ID 와 동일해야 GoogleSignIn 이 크래시하지 않음
  local ios_client
  ios_client="$(read_env_value "$env_file" "GOOGLE_IOS_CLIENT_ID")"
  if [[ -z "$ios_client" ]]; then
    ios_client="$(read_env_value "$env_file" "GOOGLE_CLIENT_ID")"
  fi
  # dev.env 에 구글 ID가 비어 있으면 동일 Firebase 프로젝트 기준 prod.env 로 폴백
  if [[ -z "$ios_client" ]] && [[ "$(basename "$env_file")" == "dev.env" ]]; then
    ios_client="$(read_env_value "$PROJECT_ROOT/prod.env" "GOOGLE_IOS_CLIENT_ID")"
  fi
  google_scheme="$(client_id_to_url_scheme "$ios_client")"

  cat > "$out_file" << EOF
// Generated from $(basename "$env_file") - do not edit by hand
APP_FLAVOR = ${flavor_name}
APP_ENV = ${flavor_name}
FLAVOR = ${flavor_name}
KAKAO_NATIVE_APP_KEY = ${kakao_key:-}
KAKAO_SCHEME = kakao${kakao_key:-}
GOOGLE_MAPS_API_KEY = ${maps_key:-}
GoogleMapsAPIKey = ${maps_key:-}
GOOGLE_URL_SCHEME=${google_scheme:-}
EOF
  echo "Wrote $out_file"
}

write_xcconfig "$PROJECT_ROOT/dev.env"  "$IOS_DIR/Env.dev.xcconfig"
write_xcconfig "$PROJECT_ROOT/prod.env" "$IOS_DIR/Env.prod.xcconfig"
