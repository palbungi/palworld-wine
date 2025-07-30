#!/bin/bash

# 현재 디렉토리의 절대 경로 구하기
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/backup.sh"

# 실행 권한 부여
chmod +x "$SCRIPT_PATH"

# 크론탭 명령어 구성
CRON_JOB="30 * * * * $SCRIPT_PATH"

# 기존 크론탭에서 중복 제거 후 새 항목 추가
( sudo crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" ; echo "$CRON_JOB" ) | sudo crontab -
