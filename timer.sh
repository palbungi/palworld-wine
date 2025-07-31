#!/bin/bash

CONFIG_FILE="/home/YOUR_USERNAME/config.env"
SCRIPT_FILE="/home/YOUR_USERNAME/regular_maintenance.sh"

# 1. Check ADMIN_PASSWORD
ADMIN_PASSWORD=$(grep "^ADMIN_PASSWORD=" "$CONFIG_FILE" | cut -d= -f2)

if [ "$ADMIN_PASSWORD" == "adminpasswd" ]; then
    read -s -p "운영자 비밀번호를 입력하세요: " NEW_PASSWORD
    echo
    sed -i "s/^ADMIN_PASSWORD=.*/ADMIN_PASSWORD=$NEW_PASSWORD/" "$CONFIG_FILE"
fi

# 2. Clear existing crontab
crontab -r
echo "기존 팰월드서버 재시작 목록을 삭제했습니다."

# 3. Menu
echo "0. 팰월드서버 재시작 안함"
echo "1. 하루 횟수만 지정 (자동 시간 계산)"
echo "2. 하루 횟수와 시간 지정"
read -p "번호를 선택하세요: " MODE

# 6. Crontab header
CRON_HEADER="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CRON_ENTRIES=("$CRON_HEADER")

if [ "$MODE" == "0" ]; then
    echo "팰월드서버 재시작을 하지 않도록 설정했습니다. 스크립트를 종료합니다."
    exit 0
elif [ "$MODE" == "1" ]; then
    read -p "하루에 몇 번 실행할까요? (0 입력시 종료): " COUNT
    if [ "$COUNT" -eq 0 ]; then
        echo "0번 입력으로 종료합니다."
        exit 0
    fi
    INTERVAL=$((24 / COUNT))
    for ((i=0; i<COUNT; i++)); do
        HOUR=$((i * INTERVAL))
        CRON_ENTRIES+=("0 $HOUR * * * $SCRIPT_FILE")
    done
elif [ "$MODE" == "2" ]; then
    read -p "하루에 몇 번 실행할까요? (0 입력시 종료): " COUNT
    if [ "$COUNT" -eq 0 ]; then
        echo "0번 입력으로 종료합니다."
        exit 0
    fi
    for ((i=1; i<=COUNT; i++)); do
        read -p "$i 번째 실행 시간을 입력하세요 (0~24): " HOUR
        [ "$HOUR" == "24" ] && HOUR="0"
        CRON_ENTRIES+=("0 $HOUR * * * $SCRIPT_FILE")
    done
else
    echo "잘못된 입력입니다. 스크립트를 종료합니다."
    exit 1
fi

# Apply crontab
( for ENTRY in "${CRON_ENTRIES[@]}"; do echo "$ENTRY"; done ) | crontab -

echo "팰월드서버 재시작이 성공적으로 설정되었습니다."
