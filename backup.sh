#!/bin/bash

# 모든 명령어에 절대 경로 사용
DATE_BIN="/usr/bin/date"
MKDIR_BIN="/usr/bin/mkdir"
FIND_BIN="/usr/bin/find"
CP_BIN="/usr/bin/cp"
CHOWN_BIN="/usr/bin/chown" # 이 명령어가 필요한지 재고
RM_BIN="/usr/bin/rm"

# 기본 경로 (YOUR_USERNAME을 실제 팔월드 서버를 실행하는 사용자 이름으로 변경)
# 예를 들어, 사용자 이름이 'gcpuser'라면 아래와 같이 명시
BASE_DIR="/home/gcpuser/palworld-wine/game/Pal/Saved/SaveGames/0/0123456789ABCDEF0123456789ABCDEF"
BACKUP_ROOT="$BASE_DIR/backup"

# 백업이 시작될 때 로그 메시지
echo "$(${DATE_BIN} '+%Y-%m-%d %H:%M:%S') - Backup started for $BASE_DIR"

# 날짜 및 시간
DATE=$(${DATE_BIN} +"%Y-%m-%d")
TIME=$(${DATE_BIN} +"%H-%M-%S")
BACKUP_DIR="$BACKUP_ROOT/$DATE/$TIME"

# 백업 디렉토리 생성
${MKDIR_BIN} -p "$BACKUP_DIR" || { echo "ERROR: Failed to create backup directory $BACKUP_DIR" ; exit 1; }

# .sav 파일 복사 (최상위 디렉토리)
${FIND_BIN} "$BASE_DIR" -maxdepth 1 -type f -name "*.sav" -exec ${CP_BIN} {} "$BACKUP_DIR" \; || echo "WARNING: Failed to copy top-level .sav files."

# Players 디렉토리 내 .sav 파일 복사
if [ -d "$BASE_DIR/Players" ]; then
    ${MKDIR_BIN} -p "$BACKUP_DIR/Players" || { echo "ERROR: Failed to create Players backup directory." ; exit 1; }
    ${FIND_BIN} "$BASE_DIR/Players" -type f -name "*.sav" -exec ${CP_BIN} --parents {} "$BACKUP_DIR" \; || echo "WARNING: Failed to copy Players .sav files."
else
    echo "WARNING: Players directory not found at $BASE_DIR/Players"
fi

# 7일 이상 지난 백업 디렉토리 삭제
${FIND_BIN} "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec ${RM_BIN} -rf {} \; || echo "WARNING: Failed to clean old backups."

# chown은 일반적으로 root 권한이 필요합니다.
# 이 스크립트를 일반 사용자 크론탭에 등록하고 싶다면 이 줄을 제거하세요.
# 만약 꼭 필요하다면, 이 스크립트를 root의 크론탭에 등록해야 합니다.
sudo ${CHOWN_BIN} -R 1001:1002 "$BACKUP_DIR" || echo "WARNING: Failed to change ownership of $BACKUP_DIR"

echo "$(${DATE_BIN} '+%Y-%m-%d %H:%M:%S') - Backup finished."
