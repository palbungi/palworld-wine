#!/bin/bash

# 기본 경로
BASE_DIR="/home/$(whoami)/palworld-wine/game/Pal/Saved/SaveGames/0/0123456789ABCDEF0123456789ABCDEF"
BACKUP_ROOT="$BASE_DIR/backup"

# 날짜 및 시간
DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H-%M-%S")
BACKUP_DIR="$BACKUP_ROOT/$DATE/$TIME"

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# .sav 파일 복사 (최상위 디렉토리)
find "$BASE_DIR" -maxdepth 1 -type f -name "*.sav" -exec cp {} "$BACKUP_DIR" \;

# Players 디렉토리 내 .sav 파일 복사
if [ -d "$BASE_DIR/Players" ]; then
    mkdir -p "$BACKUP_DIR/Players"
    find "$BASE_DIR/Players" -type f -name "*.sav" -exec cp --parents {} "$BACKUP_DIR" \;
fi

# 7일 이상 지난 백업 디렉토리 삭제
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

chown -R 1001:1002 $BACKUP_DIR
