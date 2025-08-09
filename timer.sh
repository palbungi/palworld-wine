#!/bin/bash

# =============================================================================
# 색상 및 스타일 정의
# =============================================================================
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m' # 색상 초기화

# 입력 프롬프트 스타일
PROMPT_COLOR="${CYAN}${BOLD}"
INPUT_COLOR="${CYAN}"

# =============================================================================
# 경로 설정 (사용자 환경에 맞게 수정 필요)
# =============================================================================
USER_NAME=$(whoami)
CRON_FILE="/tmp/mycron"
SCRIPT_PATH="/home/$USER_NAME/palworld-wine/regular_maintenance.sh"
SCRIPT_URL="https://raw.githubusercontent.com/palbungi/palworld-wine/main/regular_maintenance.sh"

# =============================================================================
# 함수 정의
# =============================================================================

# 헤더 출력 함수
print_header() {
    echo -e "\n${CYAN}${BOLD}=============================================="
    echo -e " 팰월드 서버 재시작 스케줄 설정 도구"
    echo -e "==============================================${NC}\n"
}

# 오류 메시지 출력
print_error() {
    echo -e "\n${RED}${BOLD}[ERROR] $1${NC}${NORMAL}" >&2
}

# 성공 메시지 출력
print_success() {
    echo -e "\n${GREEN}${BOLD}$1${NC}${NORMAL}"
}

# 색상이 적용된 입력 함수
colored_read() {
    local prompt="$1"
    local var_name="$2"
    echo -ne "${PROMPT_COLOR}${prompt}${INPUT_COLOR}"
    read "$var_name"
    echo -ne "${NC}"
}

# 24시간제를 12시간제로 변환 (오전/오후 표시)
convert_to_12h() {
    local hour="$1"
    local minute="$2"
    local period suffix
    
    if [[ $hour -eq 0 || $hour -eq 24 ]]; then
        period="오전"
        hour=12
    elif [[ $hour -lt 12 ]]; then
        period="오전"
    elif [[ $hour -eq 12 ]]; then
        period="오후"
    else
        period="오후"
        hour=$((hour - 12))
    fi
    
    printf -v hour_str "%02d" "$hour"
    printf -v min_str "%02d" "$minute"
    
    echo "[$period] $hour_str:$min_str"
}

# 기존 크론 작업 삭제 함수
remove_existing_cron_jobs() {
    echo -e "${YELLOW}${BOLD}기존 재시작 스케줄을 삭제합니다...${NC}"
    
    # 기존 크론 작업에서 스크립트 관련 항목 제거
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        crontab -l | grep -v "$SCRIPT_PATH" > "$CRON_FILE"
        crontab "$CRON_FILE"
        rm -f "$CRON_FILE"
        print_success "기존 재시작 스케줄이 삭제되었습니다."
    else
        echo -e "${BLUE}${BOLD}삭제할 기존 스케줄이 없습니다.${NC}"
    fi
}

# =============================================================================
# 메인 스크립트 시작
# =============================================================================
clear
print_header

# regular_maintenance.sh 다운로드 (없는 경우)
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${YELLOW}${BOLD}⚠ 정기 관리 스크립트가 없어서 다운로드 중...${NC}"
    curl -o "$SCRIPT_PATH" "$SCRIPT_URL" || {
        print_error "스크립트 다운로드 실패"
        exit 1
    }
    chmod +x "$SCRIPT_PATH"
    print_success "정기 관리 스크립트 다운로드 및 실행 권한 설정 완료!"
fi

# =============================================================================
# 모드 선택
# =============================================================================
while true; do
    echo -e "${MAGENTA}${BOLD}■ 재시작 스케줄 설정 방법 선택${NC}"
    echo -e "  ${BLUE}0. 재시작 스케줄 삭제 (재시작 기능 비활성화)${NC}"
    echo -e "  ${GREEN}${BOLD}1. 횟수 기반 자동 스케줄 설정 (*추천)${NC}"
    echo -e "  ${YELLOW}2. 시간 직접 입력 (사용자 지정 스케줄)${NC}"
    echo ""
    
    colored_read "▶ 선택 (0-2): " MODE

    # 모드 0: 스케줄 삭제
    if [[ "$MODE" == "0" ]]; then
        remove_existing_cron_jobs
        print_success "모든 재시작 스케줄이 삭제되었습니다."
        exit 0
        
    # 모드 1: 횟수 기반 자동 스케줄
    elif [[ "$MODE" == "1" ]]; then
        # 기존 스케줄 삭제
        remove_existing_cron_jobs
        
        echo -e "\n${GREEN}${BOLD}■ 하루 재시작 횟수 설정${NC}"
        while true; do
            colored_read "▶ 하루에 몇 번 재시작할까요? (0 입력 시 종료): " COUNT
            
            if [[ "$COUNT" == "0" ]]; then
                echo -e "${BLUE}${BOLD}스크립트를 종료합니다.${NC}"
                exit 0
            elif [[ "$COUNT" =~ ^[1-9][0-9]*$ ]]; then
                break
            else
                print_error "양의 정수를 입력해주세요."
            fi
        done

        # 자동 시간 계산
        INTERVAL=$((24 * 60 / COUNT))
        TIMES=()
        > "$CRON_FILE"
        
        echo -e "\n${GREEN}${BOLD}■ 설정된 재시작 시간${NC}"
        for ((i=0; i<COUNT; i++)); do
            TOTAL_MINUTES=$((i * INTERVAL))
            HOUR=$((TOTAL_MINUTES / 60))
            MIN=$((TOTAL_MINUTES % 60))
            
            # 시간 포맷팅
            printf -v HOUR_STR "%02d" "$HOUR"
            printf -v MIN_STR "%02d" "$MIN"
            
            # 12시간제로 변환 (오전/오후 표시)
            TIME_12H=$(convert_to_12h "$HOUR" "$MIN")
            
            # 시간 출력 (오전/오후 구분)
            if [ $HOUR -lt 12 ]; then
                # 오전 시간 (00:00 ~ 11:59)
                echo -e "  ${YELLOW}${BOLD}• $((i+1))번: $TIME_12H${NC}"
            else
                # 오후 시간 (12:00 ~ 23:59)
                echo -e "  ${GREEN}${BOLD}• $((i+1))번: $TIME_12H${NC}"
            fi
            
            # 크론 항목 추가
            echo "$MIN_STR $HOUR_STR * * * $SCRIPT_PATH" >> "$CRON_FILE"
        done
        break
        
    # 모드 2: 시간 직접 입력
    elif [[ "$MODE" == "2" ]]; then
        # 기존 스케줄 삭제
        remove_existing_cron_jobs
        
        echo -e "\n${YELLOW}${BOLD}■ 하루 재시작 횟수 설정${NC}"
        while true; do
            colored_read "▶ 하루에 몇 번 재시작할까요? (0 입력 시 종료): " COUNT
            
            if [[ "$COUNT" == "0" ]]; then
                echo -e "${BLUE}${BOLD}스크립트를 종료합니다.${NC}"
                exit 0
            elif [[ "$COUNT" =~ ^[1-9][0-9]*$ ]]; then
                break
            else
                print_error "양의 정수를 입력해주세요."
            fi
        done

        # 시간 입력
        TIMES=()
        echo -e "\n${YELLOW}${BOLD}■ 재시작 시간 입력 (HH:MM 형식)${NC}"
        for ((i=1; i<=COUNT; i++)); do
            while true; do
                colored_read "▶ $i번째 시간 입력 (예: 03:00): " TIME
                
                # 24:00 변환 처리
                if [[ "$TIME" == "24:00" ]]; then
                    echo -e "${BLUE}24:00 → 00:00으로 변환됩니다.${NC}"
                    TIME="00:00"
                fi
                
                # 시간 형식 검증
                if [[ "$TIME" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]] || [[ "$TIME" == "00:00" ]]; then
                    TIMES+=("$TIME")
                    break
                else
                    print_error "올바른 시간 형식이 아닙니다. (예: 03:00)"
                fi
            done
        done

        # 크론 파일 생성
        > "$CRON_FILE"
        echo -e "\n${GREEN}${BOLD}■ 설정된 재시작 시간${NC}"
        for TIME in "${TIMES[@]}"; do
            HOUR=$(echo "$TIME" | cut -d':' -f1)
            MIN=$(echo "$TIME" | cut -d':' -f2)
            
            # 시간 포맷팅
            printf -v HOUR_STR "%02d" "$HOUR"
            printf -v MIN_STR "%02d" "$MIN"
            
            # 12시간제로 변환 (오전/오후 표시)
            TIME_12H=$(convert_to_12h "$HOUR" "$MIN")
            
            # 시간 출력 (오전/오후 구분)
            if [ $HOUR -lt 12 ]; then
                # 오전 시간 (00:00 ~ 11:59)
                echo -e "  ${YELLOW}${BOLD}• $TIME_12H${NC}"
            else
                # 오후 시간 (12:00 ~ 23:59)
                echo -e "  ${BLUE}${BOLD}• $TIME_12H${NC}"
            fi
            
            # 크론 항목 추가
            echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> "$CRON_FILE"
            echo "$MIN_STR $HOUR_STR * * * $SCRIPT_PATH" >> "$CRON_FILE"
        done
        break
        
    else
        print_error "0, 1, 2 중 하나를 입력해주세요."
    fi
done

# =============================================================================
# 크론 작업 등록
# =============================================================================
crontab "$CRON_FILE" || {
    print_error "크론 작업 등록 실패"
    exit 1
}
rm -f "$CRON_FILE"
sudo systemctl restart cron || {
    print_error "cron 서비스 재시작 실패"
    exit 1
}

# =============================================================================
# 완료 메시지
# =============================================================================
print_success "팰월드 서버 재시작 스케줄이 성공적으로 등록되었습니다!"

# 현재 설정된 크론 작업 출력
echo -e "\n${CYAN}${BOLD}■ 현재 설정된 재시작 일정${NC}"
crontab -l | grep "$SCRIPT_PATH" || echo -e "${YELLOW}설정된 재시작 스케줄이 없습니다.${NC}"

# 최종 안내 메시지
echo -e "\n${MAGENTA}${BOLD}※ 서버 재시작은 매일 지정된 시간에 자동으로 수행됩니다"
echo -e "※ 설정을 변경하려면 이 스크립트를 다시 실행해주세요${NC}"
