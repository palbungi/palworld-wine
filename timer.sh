#!/bin/bash

SCRIPT_PATH="/home/$(whoami)/palworld-wine/regular_maintenance.sh"
CRON_FILE="/tmp/mycron"

# 기존 크론 삭제
crontab -r
echo "기존 재시작 목록을 삭제했습니다."

# 모드 선택
echo "0. 팰월드서버 재시작 안함"
echo "1. 하루 횟수만 지정 (자동 시간 계산)"
echo "2. 하루 횟수와 시간 지정"
read -p "번호를 선택하세요: " MODE

if [[ "$MODE" == "0" ]]; then
    echo "서버 재시작을 하지 않도록 설정했습니다. 스크립트를 종료합니다."
    exit 0
fi

echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > "$CRON_FILE"

if [[ "$MODE" == "1" ]]; then
    read -p "하루에 몇 번 실행할까요? (숫자 입력, 0 입력 시 종료): " COUNT
    if [[ "$COUNT" == "0" ]]; then
        echo "스크립트를 종료합니다."
        exit 0
    fi
    INTERVAL=$((24 * 60 / COUNT))
    for ((i=0; i<COUNT; i++)); do
        TOTAL_MINUTES=$((i * INTERVAL))
        HOUR=$((TOTAL_MINUTES / 60))
        MIN=$((TOTAL_MINUTES % 60))
        echo "$MIN $HOUR * * * $SCRIPT_PATH" >> "$CRON_FILE"
    done

elif [[ "$MODE" == "2" ]]; then
    read -p "하루에 몇 번 실행할까요? (숫자 입력, 0 입력 시 종료): " COUNT
    if [[ "$COUNT" == "0" ]]; then
        echo "스크립트를 종료합니다."
        exit 0
    fi
    for ((i=1; i<=COUNT; i++)); do
        while true; do
            read -p "$i 번째 실행 시간 (시간:분 형식): " TIME
            if [[ "$TIME" == "24:00" ]]; then
                echo "24:00은 00:00으로 변환됩니다."
                TIME="00:00"
            fi
            if [[ "$TIME" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
                HOUR=$(echo "$TIME" | cut -d':' -f1)
                MIN=$(echo "$TIME" | cut -d':' -f2)
                echo "$MIN $HOUR * * * $SCRIPT_PATH" >> "$CRON_FILE"
                break
            else
                echo "올바른 시간 형식(시간:분)을 입력해주세요."
            fi
        done
    done
else
    echo "잘못된 선택입니다. 스크립트를 종료합니다."
    exit 1
fi

# 크론 등록
crontab "$CRON_FILE"
rm "$CRON_FILE"
echo "팰월드 재시작 스크립트가 성공적으로 등록되었습니다."
sudo systemctl start cron
sudo systemctl enable cron
sudo systemctl restart cron
