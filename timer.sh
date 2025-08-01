#!/bin/bash
CRON_FILE="/tmp/mycron"
SCRIPT_PATH="/home/YOUR_USERNAME/palworld-wine/regular_maintenance.sh"

# regular_maintenance.sh 유무 확인
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "regular_maintenance.sh이 없어서 다운로드중..."
    curl -o "$SCRIPT_PATH" https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/regular_maintenance.sh
    chmod +x "$SCRIPT_PATH"
fi

# 모드 선택
while true; do
    echo "팰월드서버 재시작 스케쥴 등록 방법을 선택하세요:"
    echo 
    echo "0. 팰월드서버 재시작 스케쥴 삭제 (재시작을 하지 않습니다)"
    echo 
    echo "1. 팰월드서버 재시작 횟수만 입력 (24시간에서 횟수를 자동으로 나눠서 등록)"
    echo 
    echo "2. 팰월드서버 재시작 횟수와 시간 직접입력"
    echo 
    read -p "번호 선택: " MODE

    if [[ "$MODE" == "0" ]]; then
        crontab -r
        echo "팰월드서버 재시작 스케쥴을 삭제했습니다."
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
        echo -e "\e[1;32m아래와 같은 시간에 서버가 재시작 되도록 설정됩니다.\e[0m"
        > "$CRON_FILE"
        for ((i=0; i<COUNT; i++)); do
            TOTAL_MINUTES=$((i * INTERVAL))
            HOUR=$((TOTAL_MINUTES / 60))
            MIN=$((TOTAL_MINUTES % 60))
            
            printf "\e[1;33m팰월드 서버 재시작 시간: %02d시 %02d분\e[0m\n" "$HOUR" "$MIN"
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
        echo -e "\e[1;32m아래와 같은 시간에 서버가 재시작 되도록 설정됩니다.\e[0m"
        > "$CRON_FILE"
        for TIME in "${TIMES[@]}"; do
            HOUR=$(echo "$TIME" | cut -d':' -f1)
            MIN=$(echo "$TIME" | cut -d':' -f2)
            printf "\e[1;33m팰월드 서버 재시작 시간: %02d시 %02d분\e[0m\n" "$HOUR" "$MIN"
            echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> "$CRON_FILE"
            echo "$MIN $HOUR * * * $SCRIPT_PATH" >> "$CRON_FILE"
        done
        break

    else
        echo "숫자 0 1 2 하나를 입력해주세요."
    fi
done

# 크론 등록
crontab "$CRON_FILE"
rm "$CRON_FILE"
sudo systemctl restart cron

echo -e "\e[1;32m팰월드서버 재시작 스케쥴이 등록되었습니다.\e[0m"
