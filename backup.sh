#!/bin/bash

# 모든 명령어에 절대 경로 사용 (크론 환경 PATH 문제 방지)
DATE_BIN="/usr/bin/date"
MKDIR_BIN="/usr/bin/mkdir"
FIND_BIN="/usr/bin/find"
CP_BIN="/usr/bin/cp"
CHOWN_BIN="/usr/bin/chown"
RM_BIN="/usr/bin/rm"
# RSYNC_BIN="/usr/bin/rsync" # rsync를 사용하려면 주석 해제

# 스크립트 실행 중 오류 발생 시 즉시 종료
set -e

# Palworld 저장 경로의 기본 디렉토리
# 'YOUR_USERNAME' 부분을 실제 사용자 이름으로 변경해야 합니다.
BASE_DIR="/home/YOUR_USERNAME/palworld-wine/game/Pal/Saved/SaveGames/0/0123456789ABCDEF0123456789ABCDEF"
# 백업 파일이 저장될 루트 디렉토리
BACKUP_ROOT="$BASE_DIR/backup"

# 백업이 시작될 때 로그 메시지
echo "$(${DATE_BIN} '+%Y-%m-%d %H:%M:%S') - Backup started for $BASE_DIR"

# 백업을 위한 현재 날짜 및 시간 디렉토리 이름 생성
DATE=$(${DATE_BIN} +"%Y-%m-%d")
TIME=$(${DATE_BIN} +"%H-%M-%S")
BACKUP_DIR="$BACKUP_ROOT/$DATE/$TIME"

# 백업 디렉토리 생성
${MKDIR_BIN} -p "$BACKUP_DIR" || { echo "ERROR: Failed to create backup directory $BACKUP_DIR" ; exit 1; }
echo "Created backup directory: $BACKUP_DIR"

# 1. 최상위 디렉토리의 .sav 파일 복사
# BASE_DIR 바로 아래에 있는 .sav 파일만 복사합니다.
${FIND_BIN} "$BASE_DIR" -maxdepth 1 -type f -name "*.sav" -exec ${CP_BIN} {} "$BACKUP_DIR" \; || echo "WARNING: Failed to copy top-level .sav files."
echo "Copied top-level .sav files."

# 2. Players 디렉토리와 그 안의 .sav 파일들을 백업
# 'home' 디렉토리 생성을 방지하기 위해 Players 디렉토리 전체를 재귀적으로 복사합니다.
# 이렇게 하면 $BACKUP_DIR/Players/ 아래에 파일들이 생성됩니다.
if [ -d "$BASE_DIR/Players" ]; then
    echo "Copying Players directory..."
    # 'cp -r'을 사용하여 Players 디렉토리 전체를 $BACKUP_DIR 아래로 복사
    # 예: /home/user/.../Players -> $BACKUP_DIR/Players
    ${CP_BIN} -r "$BASE_DIR/Players" "$BACKUP_DIR/" || { echo "WARNING: Failed to copy Players directory." ; }
    echo "Copied Players directory."
else
    echo "WARNING: Players directory not found at $BASE_DIR/Players. Skipping Players backup."
fi

# 3. World 디렉토리 백업 (선택 사항, 필요 시 추가)
# World 디렉토리도 백업해야 한다면 아래 주석을 해제하고 사용하세요.
# Palworld 세이브는 World, Players, Level.sav 등으로 구성됩니다.
# if [ -d "$BASE_DIR/World" ]; then
#     echo "Copying World directory..."
#     ${CP_BIN} -r "$BASE_DIR/World" "$BACKUP_DIR/" || { echo "WARNING: Failed to copy World directory." ; }
#     echo "Copied World directory."
# else
#     echo "WARNING: World directory not found at $BASE_DIR/World. Skipping World backup."
# fi


# 7일 이상 지난 백업 디렉토리 삭제
# BACKUP_ROOT 아래의 날짜별 디렉토리(예: 2023-01-01)를 기준으로 7일 이상 된 것을 삭제합니다.
echo "Cleaning up old backups (older than 7 days)..."
${FIND_BIN} "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec ${RM_BIN} -rf {} \; || echo "WARNING: Failed to clean old backups."
echo "Old backups cleaned."

# chown은 일반적으로 root 권한이 필요합니다.
# 이 스크립트를 일반 사용자 크론탭에 등록하고 싶다면 이 줄을 제거하거나,
# 스크립트가 실행되는 사용자에게 해당 디렉토리의 소유권을 변경할 권한이 있는지 확인하세요.
# 만약 꼭 필요하다면, 이 스크립트를 root의 크론탭에 등록해야 합니다.
# 현재 스크립트가 일반 사용자로 실행될 경우를 대비하여 'sudo'를 제거했습니다.
# 소유권 변경이 필요하다면, 스크립트를 root crontab에 등록하거나,
# 해당 사용자에게 sudoers 설정을 통해 chown 권한을 부여해야 합니다 (권장하지 않음).
sudo ${CHOWN_BIN} -R YOUR_USERNAME:YOUR_USERNAME "$BACKUP_DIR" || echo "WARNING: Failed to change ownership of $BACKUP_DIR. Check permissions or user."

echo "$(${DATE_BIN} '+%Y-%m-%d %H:%M:%S') - Backup finished."
