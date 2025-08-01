#!/bin/bash
CRON_FILE="/tmp/mycron"
SCRIPT_PATH="/home/YOUR_USERNAME/palworld-wine/regular_maintenance.sh"

# regular_maintenance.sh 유무 확인
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "regular_maintenance.sh이 없어서 다운로드중..."
    curl -o "$SCRIPT_PATH" https://raw.githubusercontent.com/palbungi/palworld-googlecloud/refs/heads/main/regular_maintenance.sh
    chmod +x "$SCRIPT_PATH"
fi

# 기존 크론 삭제
crontab -r
echo "기존 팰월드서버 재시작 목록을 삭제했습니다."

# 모드 선택
while true; do
    echo "팰월드서버 재시작 모드를 선택하세요:"
    echo "0. 팰월드서버 재시작 안함"
    echo "1. 하루 횟수만 지정 (자동 시간 계산)"
    echo "2. 하루 횟수와 시간 지정"
    read -p "번호 선택: " MODE

    if [[ "$MODE" == "0" ]]; then
        echo "스크립트를 종료합니다."
        exit 0
    elif [[ "$MODE" == "1" ]]; then
        # 횟수 입력
        while true; do
            read -p "하루에 몇 번 실행할까요? (숫자 입력, 0 입력 시 종료): " COUNT
            if [[ "$COUNT" == "0" ]]; then
                echo "스크립트를 종료합니다."
                exit 0
            elif [[ "$COUNT" =~ ^[1-9][0-9]*$ ]]; then
                break
            else
                echo "올바른 숫자를 입력해주세요."
            fi
        done

        # 자동 시간 계산 및 출력
        INTERVAL=$((24 * 60 / COUNT))
        echo "아래와 같은 시간에 서버가 재시작 되도록 설정됩니다."
        > "$CRON_FILE"
        for ((i=0; i<COUNT; i++)); do
            TOTAL_MINUTES=$((i * INTERVAL))
            HOUR=$((TOTAL_MINUTES / 60))
            MIN=$((TOTAL_MINUTES % 60))
            
            printf "팰월드 서버 재시작 시간: %02d시 %02d분\n" "$HOUR" "$MIN"
            echo "$MIN $HOUR * * * $SCRIPT_PATH" >> "$CRON_FILE"
        done
        break

    elif [[ "$MODE" == "2" ]]; then
        # 횟수 입력
        while true; do
            read -p "하루에 몇 번 실행할까요? (숫자 입력, 0 입력 시 종료): " COUNT
            if [[ "$COUNT" == "0" ]]; then
                echo "스크립트를 종료합니다."
                exit 0
            elif [[ "$COUNT" =~ ^[1-9][0-9]*$ ]]; then
                break
            else
                echo "올바른 숫자를 입력해주세요."
            fi
        done

        # 시간 직접 입력
        TIMES=()
        for ((i=1; i<=COUNT; i++)); do
            while true; do
                read -p "$i 번째 실행 시간 (시간:분 형식): " TIME
                # 24:00 변환 처리
                if [[ "$TIME" == "24:00" ]]; then
                    echo "24:00은 00:00으로 변환됩니다."
                    TIME="00:00"
                fi
                if [[ "$TIME" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ || "$TIME" == "00:00" ]]; then
                    TIMES+=("$TIME")
                    break
                else
                    echo "올바른 시간 형식(시간:분)을 입력해주세요."
                fi
            done
        done

        # 크론 파일 생성 및 출력
        echo "아래와 같은 시간에 서버가 재시작 되도록 설정됩니다."
        > "$CRON_FILE"
        for TIME in "${TIMES[@]}"; do
            HOUR=$(echo "$TIME" | cut -d':' -f1)
            MIN=$(echo "$TIME" | cut -d':' -f2)
            printf "팰월드 서버 재시작 시간: %02d시 %02d분\n" "$HOUR" "$MIN"
            echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> "$CRON_FILE"
            echo "$MIN $HOUR * * * $SCRIPT_PATH" >> "$CRON_FILE"
        done
        break

    else
        echo "1 또는 2를 입력해주세요."
    fi
done

# 크론 등록
crontab "$CRON_FILE"
rm "$CRON_FILE"
sudo systemctl restart cron

echo "팰월드 재시작 스크립트가 성공적으로 등록되었습니다."
