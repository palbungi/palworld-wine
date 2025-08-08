#!/bin/bash
set -euo pipefail

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
ORANGE='\033[38;5;208m'
NC='\033[0m' # No Color

# =============================================================================
# 사용자 정보 및 경로 설정
# =============================================================================
USER_NAME=$(whoami)
USER_HOME="/home/$USER_NAME"
SERVER_DIR="$USER_HOME/palworld-wine"
GAME_DIR="$SERVER_DIR/game"
CONFIG_DIR="$GAME_DIR/Pal/Saved/Config/WindowsServer"
SAVE_DIR="$GAME_DIR/Pal/Saved/SaveGames/0/0123456789ABCDEF0123456789ABCDEF"
BINARIES_DIR="$GAME_DIR/Pal/Binaries/Win64"
MODS_DIR="$BINARIES_DIR/ue4ss/Mods"
GITHUB_REPO="https://raw.githubusercontent.com/palbungi/palworld-wine/main"

# =============================================================================
# 진행 상태 출력 함수
# =============================================================================
print_step() {
    echo -e "\n${CYAN}${BOLD}>>> $1${NC}${NORMAL}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${ORANGE}⚠ $1${NC}"
}

print_error() {
    echo -e "\n${RED}${BOLD}[ERROR] $1${NC}${NORMAL}" >&2
    exit 1
}

# =============================================================================
# 시작 메시지
# =============================================================================
clear
echo -e "${MAGENTA}${BOLD}"
echo "================================================"
echo "   팰월드 서버 자동 설치 스크립트 (Wine 버전)"
echo "================================================"
echo -e "${NC}"

print_step "시스템 정보 확인"
echo -e "• 사용자: ${BLUE}$USER_NAME${NC}"
echo -e "• 홈 디렉토리: ${BLUE}$USER_HOME${NC}"
echo -e "• 서버 디렉토리: ${BLUE}$SERVER_DIR${NC}"
echo -e "• OS: ${BLUE}$(lsb_release -ds)${NC}"
echo -e "• 커널 버전: ${BLUE}$(uname -r)${NC}"

# =============================================================================
# 한국 시간 설정
# =============================================================================
print_step "한국 시간대 설정"
sudo timedatectl set-timezone Asia/Seoul || print_error "시간대 설정 실패"
print_success "현재 시간: $(date +'%Y-%m-%d %H:%M:%S %Z')"

# =============================================================================
# 필수 패키지 설치 및 시스템 업데이트
# =============================================================================
print_step "필수 패키지 설치 및 시스템 업데이트"
export DEBIAN_FRONTEND=noninteractive
echo "tzdata tzdata/Areas select Asia" | sudo debconf-set-selections
echo "tzdata tzdata/Zones/Asia select Seoul" | sudo debconf-set-selections

sudo apt-get update || print_error "패키지 목록 업데이트 실패"
sudo apt-get install -y debconf-utils unzip cron gosu libgl1 libvulkan1 tzdata \
    nano man-db systemd net-tools iproute2 dialog apt-transport-https \
    ca-certificates gnupg software-properties-common util-linux || print_error "패키지 설치 실패"

# 시스템 업그레이드
sudo apt-get -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            upgrade -y || print_error "시스템 업그레이드 실패"
print_success "필수 패키지 설치 및 시스템 업그레이드 완료"

# =============================================================================
# Docker 설치
# =============================================================================
print_step "Docker 설치"
if ! getent group docker >/dev/null; then
    sudo groupadd docker || print_error "Docker 그룹 생성 실패"
fi

sudo usermod -aG docker $USER_NAME || print_error "사용자 Docker 그룹 추가 실패"

sudo mkdir -p /etc/apt/keyrings || print_error "디렉토리 생성 실패"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || print_error "GPG 키 다운로드 실패"

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || print_error "저장소 추가 실패"

sudo apt-get update || print_error "Docker 저장소 업데이트 실패"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io || print_error "Docker 설치 실패"

# Docker Compose 설치
DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
sudo curl -L "$DOCKER_COMPOSE_URL" -o /usr/local/bin/docker-compose || print_error "Docker Compose 다운로드 실패"
sudo chmod +x /usr/local/bin/docker-compose || print_error "Docker Compose 실행 권한 설정 실패"

# Docker 권한 설정
sudo chmod 666 /var/run/docker.sock || print_warning "Docker 소켓 권한 설정 실패 (재시작 필요)"
print_success "Docker 및 Docker Compose 설치 완료"

# =============================================================================
# 서버 파일 다운로드 및 설정
# =============================================================================
print_step "팰월드 서버 설정 파일 다운로드"
mkdir -p "$SERVER_DIR" || print_error "서버 디렉토리 생성 실패"
cd "$SERVER_DIR" || print_error "디렉토리 이동 실패"

# docker-compose.yml 및 default.env 다운로드
wget -q "$GITHUB_REPO/docker-compose.yml" -O "$SERVER_DIR/docker-compose.yml" || print_error "docker-compose.yml 다운로드 실패"
wget -q "$GITHUB_REPO/default.env" -O "$SERVER_DIR/default.env" || print_error "default.env 다운로드 실패"

# 공인 IP 설정
PUBLIC_IP=$(curl -s ifconfig.me)
sed -i "s/^PUBLIC_IP=.*/PUBLIC_IP=$PUBLIC_IP/" "$SERVER_DIR/default.env" || print_error "PUBLIC_IP 설정 수정 실패"
print_success "공인 IP 설정 완료: $PUBLIC_IP"

# =============================================================================
# 관리 스크립트 설정
# =============================================================================
print_step "서버 관리 스크립트 설정"

scripts=(
    "regular_maintenance.sh"
    "start.sh"
    "restart.sh"
    "stop.sh"
)

for script in "${scripts[@]}"; do
    wget -q "$GITHUB_REPO/$script" -O "$USER_HOME/$script" || print_error "$script 다운로드 실패"
    chmod +x "$USER_HOME/$script" || print_error "$script 실행 권한 설정 실패"
    sed -i "s/YOUR_USERNAME/$USER_NAME/g" "$USER_HOME/$script" || print_error "$script 사용자 이름 수정 실패"
done

# 정기 관리 스크립트 경로 수정
sed -i "s|palworld-wine/regular_maintenance.sh|$USER_HOME/regular_maintenance.sh|g" "$USER_HOME/regular_maintenance.sh" || print_error "정기 관리 스크립트 경로 수정 실패"
print_success "관리 스크립트 설정 완료"

# =============================================================================
# 게임 디렉토리 구조 생성
# =============================================================================
print_step "게임 디렉토리 구조 생성"
mkdir -p "$CONFIG_DIR" || print_error "설정 디렉토리 생성 실패"
mkdir -p "$SAVE_DIR" || print_error "저장 디렉토리 생성 실패"
mkdir -p "$BINARIES_DIR" || print_error "실행 파일 디렉토리 생성 실패"

# 설정 파일 다운로드
wget -q "$GITHUB_REPO/Engine.ini" -O "$CONFIG_DIR/Engine.ini" || print_error "Engine.ini 다운로드 실패"
wget -q "$GITHUB_REPO/GameUserSettings.ini" -O "$CONFIG_DIR/GameUserSettings.ini" || print_error "GameUserSettings.ini 다운로드 실패"
print_success "기본 설정 파일 다운로드 완료"

# =============================================================================
# 모드 설치 (UE4SS 설치 부분 수정)
# =============================================================================
print_step "게임 모드 설치"

# UE4SS 설치
print_info "UE4SS 설치 중..."
wget -q https://github.com/Okaetsu/RE-UE4SS/releases/download/experimental-palworld/UE4SS-Palworld.zip || print_error "UE4SS 다운로드 실패"
unzip -q UE4SS-Palworld.zip -d "$BINARIES_DIR" || print_error "UE4SS 압축 해제 실패"

# 기존 파일 덮어쓰기 옵션 추가 (-f)
shopt -s dotglob
mv -f "$BINARIES_DIR/UE4SS-Palworld/"* "$BINARIES_DIR" || print_error "UE4SS 파일 이동 실패"
shopt -u dotglob

# 임시 디렉토리 정리
rm -rf "$BINARIES_DIR/UE4SS-Palworld" || print_warning "UE4SS 임시 폴더 삭제 실패"
rm UE4SS-Palworld.zip || print_warning "UE4SS ZIP 파일 삭제 실패"
print_success "UE4SS 설치 완료"

# 팰디펜더 설치
print_info "팰디펜더 설치 중..."
wget -q https://github.com/Ultimeit/PalDefender/releases/latest/download/PalDefender_ProtonWine.zip || print_error "팰디펜더 다운로드 실패"
unzip -q PalDefender_ProtonWine.zip -d "$BINARIES_DIR" || print_error "팰디펜더 압축 해제 실패"
rm PalDefender_ProtonWine.zip || print_warning "팰디펜더 ZIP 파일 삭제 실패"

# 팰디펜더 설정 파일
mkdir -p "$BINARIES_DIR/PalDefender" || print_error "팰디펜더 디렉토리 생성 실패"
wget -q "$GITHUB_REPO/Config.json" -O "$BINARIES_DIR/PalDefender/Config.json" || print_error "Config.json 다운로드 실패"

# 운영자 IP 설정
USER_IP=$(who | awk '{print $5}' | tr -d '()' | head -1)
sed -i "s|127.0.0.1|$USER_IP|g" "$BINARIES_DIR/PalDefender/Config.json" || print_error "팰디펜더 IP 설정 실패"
print_success "팰디펜더 설치 완료 (운영자 IP: $USER_IP)"

# 팰디펜더 운영자 스크립트
wget -q "$GITHUB_REPO/admin.sh" -O "$USER_HOME/admin.sh" || print_error "admin.sh 다운로드 실패"
chmod +x "$USER_HOME/admin.sh" || print_error "admin.sh 실행 권한 설정 실패"

# 팰셰마 설치
print_info "팰셰마 설치 중..."
wget -q https://github.com/Okaetsu/PalSchema/releases/download/0.4.2/PalSchema_0.4.2.zip || print_error "팰셰마 다운로드 실패"
unzip -q PalSchema_0.4.2.zip -d "$MODS_DIR" || print_error "팰셰마 압축 해제 실패"
rm PalSchema_0.4.2.zip || print_warning "팰셰마 ZIP 파일 삭제 실패"
print_success "팰셰마 설치 완료"

# =============================================================================
# 심볼릭 링크 생성 (모드 관리 편의)
# =============================================================================
print_step "모드 관리 심볼릭 링크 생성"

# 디렉토리 존재 여부 확인 후 링크 생성
create_symlink() {
    local target="$1"
    local link_name="$2"
    
    # 대상 디렉토리가 존재하는지 확인
    if [ ! -d "$target" ]; then
        print_warning "대상 디렉토리가 존재하지 않아 링크를 생성하지 않습니다: $target"
        return 1
    fi
    
    # 기존 링크가 존재하면 제거
    if [ -L "$link_name" ]; then
        rm "$link_name" || print_warning "기존 링크 삭제 실패: $link_name"
    fi
    
    # 심볼릭 링크 생성
    ln -s "$target" "$link_name" || print_warning "링크 생성 실패: $target → $link_name"
}

# UE4SS 모드 링크
if [ -d "$MODS_DIR" ]; then
    create_symlink "$MODS_DIR" "$USER_HOME/>>> UE4SS 모드 <<<"
else
    print_warning "UE4SS 모드 디렉토리가 존재하지 않아 링크를 생성하지 않습니다: $MODS_DIR"
fi

# PAK 모드 링크
LOGIC_MODS_DIR="$GAME_DIR/Pal/Content/Paks/LogicMods"
if [ -d "$LOGIC_MODS_DIR" ]; then
    create_symlink "$LOGIC_MODS_DIR" "$USER_HOME/>>> PAK 모드 <<<"
else
    print_warning "PAK 모드 디렉토리가 존재하지 않아 링크를 생성하지 않습니다: $LOGIC_MODS_DIR"
fi

# 팰디펜더 링크
PALDEFENDER_DIR="$BINARIES_DIR/PalDefender"
if [ -d "$PALDEFENDER_DIR" ]; then
    create_symlink "$PALDEFENDER_DIR" "$USER_HOME/>>> 팰디펜더 <<<"
else
    print_warning "팰디펜더 디렉토리가 존재하지 않아 링크를 생성하지 않습니다: $PALDEFENDER_DIR"
fi

# 돌아가기 링크 (대상 디렉토리가 없으면 생성하지 않음)
if [ -d "$MODS_DIR" ]; then
    ln -s "$USER_HOME" "$MODS_DIR/>>> 처음으로 돌아가기 <<<" 2>/dev/null || print_warning "돌아가기 링크 생성 실패: UE4SS 모드"
fi

if [ -d "$LOGIC_MODS_DIR" ]; then
    ln -s "$USER_HOME" "$LOGIC_MODS_DIR/>>> 처음으로 돌아가기 <<<" 2>/dev/null || print_warning "돌아가기 링크 생성 실패: PAK 모드"
fi

if [ -d "$PALDEFENDER_DIR" ]; then
    ln -s "$USER_HOME" "$PALDEFENDER_DIR/>>> 처음으로 돌아가기 <<<" 2>/dev/null || print_warning "돌아가기 링크 생성 실패: 팰디펜더"
fi

print_success "모드 관리 링크 생성 완료 (일부 실패 항목 있을 수 있음)"

# =============================================================================
# 서버 설정 수정
# =============================================================================
print_step "서버 설정 수정"
echo -e "\n${ORANGE}${BOLD}=== 서버 설정 편집기 실행 ===${NC}"
echo -e "• 현재 공인 IP: ${BLUE}$PUBLIC_IP${NC}"
echo -e "• 필수 설정 항목:"
echo -e "  - ${CYAN}SERVER_PASSWORD${NC}: 서버 접속 비밀번호"
echo -e "  - ${CYAN}ADMIN_PASSWORD${NC}: 관리자 비밀번호"
echo -e "  - ${CYAN}SERVER_NAME${NC}: 서버 이름"
echo -e "\n${YELLOW}편집을 마치면 ${ORANGE}Ctrl+O${YELLOW}, ${GREEN}Enter${YELLOW}, ${RED}Ctrl+X${YELLOW} 를 눌러 저장하세요.${NC}"
sleep 3

nano "$SERVER_DIR/default.env" || print_error "설정 파일 편집 실패"

# =============================================================================
# 정기 재시작 설정
# =============================================================================
print_step "정기 재시작 작업 설정"
wget -q "$GITHUB_REPO/timer.sh" -O "$USER_HOME/timer.sh" || print_error "타이머 스크립트 다운로드 실패"
chmod +x "$USER_HOME/timer.sh" || print_error "스크립트 실행 권한 설정 실패"
sed -i "s/YOUR_USERNAME/$USER_NAME/g" "$USER_HOME/timer.sh" || print_error "스크립트 경로 수정 실패"

print_info "화면을 지웁니다..."
sleep 1
clear

bash "$USER_HOME/timer.sh" || print_error "cron 작업 설정 실패"
sudo systemctl restart cron || print_error "cron 서비스 재시작 실패"
sudo systemctl enable cron || print_error "cron 서비스 활성화 실패"
print_success "정기 재시작 작업 설정 완료"

# =============================================================================
# 팰월드 서버 시작
# =============================================================================
print_step "팰월드 서버 시작"
docker-compose -f "$SERVER_DIR/docker-compose.yml" up -d || print_error "서버 시작 실패"
print_info "서버가 시작 중입니다. 완전히 준비되기까지 5-10분이 소요될 수 있습니다."

# =============================================================================
# 설치 완료 메시지
# =============================================================================
clear
echo -e "\n${MAGENTA}${BOLD}================================================"
echo -e "       팰월드 서버 설치 완료! (Wine 버전)"
echo -e "================================================${NC}"

# 서버 접속 정보 추출
SERVER_IP=$(curl -s ifconfig.me)
SERVER_PASSWORD=$(grep '^SERVER_PASSWORD=' "$SERVER_DIR/default.env" | cut -d '=' -f2- | tr -d '"')
ADMIN_PASSWORD=$(grep '^ADMIN_PASSWORD=' "$SERVER_DIR/default.env" | cut -d '=' -f2- | tr -d '"')
SERVER_NAME=$(grep '^SERVER_NAME=' "$SERVER_DIR/default.env" | cut -d '=' -f2- | tr -d '"')

# 게임 서버 접속 정보 출력
echo -e "\n${GREEN}${BOLD}■ 게임 서버 정보${NC}"
echo -e "  ${CYAN}서버 이름: ${YELLOW}${SERVER_NAME:-[미설정]}${NC}"
echo -e "  ${CYAN}서버 주소: ${YELLOW}${SERVER_IP}:8211${NC}"

if [ -n "$SERVER_PASSWORD" ]; then
    echo -e "  ${CYAN}접속 비밀번호: ${YELLOW}${SERVER_PASSWORD}${NC}"
else
    echo -e "  ${RED}※ 주의: 비밀번호가 설정되지 않았습니다!${NC}"
fi

if [ -n "$ADMIN_PASSWORD" ]; then
    echo -e "  ${CYAN}관리자 비밀번호: ${YELLOW}${ADMIN_PASSWORD}${NC}"
else
    echo -e "  ${RED}※ 주의: 관리자 비밀번호가 설정되지 않았습니다!${NC}"
fi

# 관리 도구 정보 출력
echo -e "\n${GREEN}${BOLD}■ 관리 도구${NC}"
echo -e "  ${CYAN}서버 시작: ${BLUE}./start.sh${NC}"
echo -e "  ${CYAN}서버 재시작: ${BLUE}./restart.sh${NC}"
echo -e "  ${CYAN}서버 중지: ${BLUE}./stop.sh${NC}"
echo -e "  ${CYAN}정기 관리: ${BLUE}./regular_maintenance.sh${NC}"
echo -e "  ${CYAN}운영자 추가: ${BLUE}./admin.sh [IP]${NC}"

# 모드 관리 정보 출력
echo -e "\n${GREEN}${BOLD}■ 모드 관리${NC}"
echo -e "  ${CYAN}UE4SS 모드: ${BLUE}$USER_HOME/>>> UE4SS 모드 <<<${NC}" | grep -v 'cannot access'
echo -e "  ${CYAN}PAK 모드: ${BLUE}$USER_HOME/>>> PAK 모드 <<<${NC}" | grep -v 'cannot access'
echo -e "  ${CYAN}팰디펜더 설정: ${BLUE}$USER_HOME/>>> 팰디펜더 <<<${NC}" | grep -v 'cannot access'

# 중요 정보 출력
echo -e "\n${ORANGE}${BOLD}■ 중요 정보${NC}"
echo -e " 1. 서버 완전 시작까지 ${YELLOW}5-10분${NC} 소요 (게임 접속 전 대기 필요)"
echo -e " 2. 서버 설정 파일: ${CYAN}$SERVER_DIR/default.env${NC}"
echo -e " 3. 서버 로그 확인: ${CYAN}docker-compose -f $SERVER_DIR/docker-compose.yml logs${NC}"
echo -e " 4. 정기 재시작 설정 확인: ${CYAN}crontab -l${NC}"

# 보안 상태 메시지
if [ -z "$SERVER_PASSWORD" ]; then
    echo -e "\n${RED}${BOLD}※ 보안 경고: 비밀번호가 설정되지 않아 공개 서버입니다!${NC}"
    echo -e "   ${YELLOW}default.env 파일에서 SERVER_PASSWORD를 설정해주세요${NC}"
else
    echo -e "\n${GREEN}${BOLD}※ 보안: 비밀번호가 설정된 비공개 서버입니다${NC}"
fi

if [ -z "$ADMIN_PASSWORD" ]; then
    echo -e "\n${RED}${BOLD}※ 보안 경고: 관리자 비밀번호가 설정되지 않았습니다!${NC}"
    echo -e "   ${YELLOW}default.env 파일에서 ADMIN_PASSWORD를 설정해주세요${NC}"
fi

# 종료 메시지
echo -e "\n${MAGENTA}${BOLD}이 창은 닫아도 됩니다. 즐거운 게임 되세요!${NC}"
echo -e "${MAGENTA}${BOLD}================================================${NC}"

# 설치 파일 정리
rm -f "$USER_HOME/pb" || print_warning "설치 파일 삭제 실패"
