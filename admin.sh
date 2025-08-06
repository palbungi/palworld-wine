#!/bin/bash

# 파란색 ANSI 코드
BLUE='\033[0;34m'
NC='\033[0m' # 색상 초기화

# Config.json 위치
JSON_FILE="/home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/PalDefender/Config.json"

# jq 설치여부 확인
if ! command -v jq &> /dev/null; then
    echo -e "${BLUE}jq가 설치되어 있지 않습니다. 설치를 진행합니다...${NC}"
    sudo apt update && sudo apt install -y jq
fi

# 사용자로부터 IP 입력받기
echo -e "${BLUE}운영자 IP 주소를 입력받습니다...${NC}"
read -p "추가할 운영자 IP 주소를 입력하세요: " NEW_IP

# jq를 사용해 조건에 따라 삽입
jq --arg new_ip "$NEW_IP" '
  .adminIPs |= (
    (index("127.0.0.1") as $i |
      .[:$i+1] + [$new_ip] + .[$i+1:]
    ) // (. + [$new_ip])
  )
' "$JSON_FILE" > tmp.json && mv tmp.json "$JSON_FILE"

echo -e "${BLUE}운영자 IP 주소가 추가되었습니다: $NEW_IP${NC}"

bash /home/$(whoami)/restart.sh
