#!/bin/bash

# 기본 경로 (YOUR_USERNAME을 실제 사용자 이름으로 대체)
BASE_DIR="/home/YOUR_USERNAME/palworld-wine/game/Pal/Saved/SaveGames/0/0123456789ABCDEF0123456789ABCDEF"
BACKUP_ROOT="$BASE_DIR/backup"

# 날짜 및 시간
DATE=$(/usr/bin/date +"%Y-%m-%d")
TIME=$(/usr/bin/date +"%H-%M-%S")
BACKUP_DIR="$BACKUP_ROOT/$DATE/$TIME"

# 백업 디렉토리 생성
/usr/bin/mkdir -p "$BACKUP_DIR"

# .sav 파일 복사 (최상위 디렉토리)
/usr/bin/find "$BASE_DIR" -maxdepth 1 -type f -name "*.sav" -exec /usr/bin/cp {} "$BACKUP_DIR" \;

# Players 디렉토리 내 .sav 파일 복사
if [ -d "$BASE_DIR/Players" ]; then
    /usr/bin/mkdir -p "$BACKUP_DIR/Players"
    /usr/bin/find "$BASE_DIR/Players" -type f -name "*.sav" -exec /usr/bin/cp --parents {} "$BACKUP_DIR" \;
fi

# 7일 이상 지난 백업 디렉토리 삭제
/usr/bin/find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec /usr/bin/rm -rf {} \;

/usr/bin/chown -R 1001:1002 "$BACKUP_DIR"
