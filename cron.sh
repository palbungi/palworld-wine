#!/bin/bash

# 스크립트 실행 중 오류 발생 시 즉시 종료
set -e

# 스크립트가 있는 디렉토리 경로
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# 백업 스크립트 경로
BACKUP_SCRIPT_PATH="$SCRIPT_DIR/backup.sh"
# 백업 로그 파일 경로
BACKUP_LOG_PATH="$SCRIPT_DIR/backup.log"

echo "크론 작업 설정을 시작합니다..."
echo "스크립트 디렉토리: $SCRIPT_DIR"
echo "백업 스크립트 경로: $BACKUP_SCRIPT_PATH"
echo "백업 로그 경로: $BACKUP_LOG_PATH"

# 1. backup.log 파일 생성 및 올바른 권한 설정
# 로그 파일은 실행 가능할 필요가 없습니다. 일반적인 파일 권한 644 (rw-r--r--)를 부여합니다.
touch "$BACKUP_LOG_PATH" || { echo "오류: 로그 파일 '$BACKUP_LOG_PATH' 생성 실패." ; exit 1; }
chmod +x "$BACKUP_LOG_PATH" || { echo "오류: 로그 파일 '$BACKUP_LOG_PATH' 권한 설정 실패." ; exit 1; }
echo "'$BACKUP_LOG_PATH' 파일이 생성되었거나 존재하며, 권한이 644로 설정되었습니다."

# 2. backup.sh 에 실행 권한 부여
# 크론이 스크립트를 실행하려면 이 권한이 필수적입니다.
chmod +x "$BACKUP_SCRIPT_PATH" || { echo "오류: 백업 스크립트 '$BACKUP_SCRIPT_PATH' 실행 권한 설정 실패." ; exit 1; }
echo "'$BACKUP_SCRIPT_PATH' 에 실행 권한이 부여되었습니다."

# 3. 크론탭 명령어 구성 (로그 리다이렉션 경로 수정)
# 30분마다 실행되도록 설정: "30 * * * *"
# 로그 리다이렉션 시 'SCRIPT_DIR' 변수를 올바르게 사용합니다.
# 또한, 크론 환경의 PATH 문제를 해결하기 위해 스크립트 내에서 절대 경로를 사용하거나,
# 크론탭에 SHELL 및 PATH 환경 변수를 명시적으로 설정하는 것이 좋습니다.
CRON_JOB="30 * * * * $BACKUP_SCRIPT_PATH >> $BACKUP_LOG_PATH 2>&1"

# 4. 기존 크론탭 내용을 가져와서 새로운 항목 추가 (중복 방지 및 안전하게)
# 이 스크립트를 실행하는 '현재 사용자'의 크론탭에 등록합니다.
# 만약 'root' 사용자의 크론탭에 등록하려면, 아래 'crontab -l' 및 'crontab -' 명령 앞에 'sudo'를 붙여야 합니다.
# (예: `sudo crontab -l`, `sudo crontab -`)
# root 크론탭은 `sudo crontab -e`로 편집하거나 `sudo crontab -u root -l` 등으로 접근할 수 있습니다.

# 기존 PATH 설정이 있는지 확인하고 중복 추가 방지
# 기존 크론탭에서 해당 백업 스크립트와 관련된 라인을 먼저 제거하여 중복을 방지합니다.
(sudo crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT_PATH" ; \
 echo "SHELL=/bin/bash"; \
 echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$SCRIPT_DIR"; \
 echo "$CRON_JOB") | crontab -

echo "크론 작업이 현재 사용자의 크론탭에 추가/업데이트 되었습니다."
echo "추가된 크론 엔트리: $CRON_JOB"
echo "스크립트 출력 및 오류는 '$BACKUP_LOG_PATH' 에서 확인하세요."

# 5. cron 서비스 재시작 (변경 사항 즉시 적용)
# 대부분의 Linux 시스템은 crontab이 편집되면 자동으로 변경 사항을 감지하지만,
# 명시적으로 재시작하는 것이 확실합니다.
echo "크론 서비스 재시작 중..."
# systemctl 명령은 sudo 권한이 필요합니다.
sudo systemctl restart cron || { echo "경고: 크론 서비스 재시작 실패. 변경 사항 적용에 시간이 걸릴 수 있습니다." ; }

echo "크론 작업 설정 완료!"
