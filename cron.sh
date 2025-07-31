#!/bin/bash

# 스크립트가 있는 디렉토리와 backup.sh 경로
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SCRIPT_PATH="$SCRIPT_DIR/backup.sh" # backup.sh 경로

# backup.sh 에 실행 권한 부여
chmod +x "$BACKUP_SCRIPT_PATH" || { echo "ERROR: Failed to set executable permission on $BACKUP_SCRIPT_PATH" ; exit 1; }

# 크론탭 명령어 구성 (로그 리다이렉션 포함)
# 30분마다 실행되도록 예시: "30 * * * *"
CRON_JOB="30 * * * * $BACKUP_SCRIPT_PATH >> SCRIPT_DIR/backup.log 2>&1"

# 기존 크론탭 내용을 가져와서 새로운 항목 추가 (안전하게)
(sudo crontab -l 2>/dev/null; echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"; echo "$CRON_JOB") | sudo crontab -

echo "Cron job for $BACKUP_SCRIPT_PATH added/updated."
echo "Check /var/log/backup_cron.log for script output and errors."

sudo systemctl restart cron
