# 한국시간 설정
sudo timedatectl set-timezone Asia/Seoul

# 서버 디렉토리 생성
mkdir palworld-wine
cd palworld-wine

# 리눅스 업데이트 & 업그레이드
echo "tzdata tzdata/Areas select Asia" | sudo debconf-set-selections
echo "tzdata tzdata/Zones/Asia select Beirut" | sudo debconf-set-selections
sudo apt-get -y install debconf-utils
sudo debconf-set-selections <<< 'debconf debconf/frontend select Noninteractive'
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get -y -o Dpkg::Options::="--force-confdef" \
                -o Dpkg::Options::="--force-confold" \
                upgrade -y


# 도커&도커컴포즈 설치
sudo groupadd docker
sudo usermod -aG docker $(whoami)
sudo apt install -y nano && sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && yes | sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo chmod 666 /var/run/docker.sock


# 팰월드 도커 다운로드
wget https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/docker-compose.yml
wget https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/default.env

# 서버 재시작 스크립트 다운로드, 경로설정, 실행 권한 추가
wget https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/regular_maintenance.sh
chmod +x /home/$(whoami)/palworld-wine/regular_maintenance.sh
sed -i "s/YOUR_USERNAME/$(whoami)/g" regular_maintenance.sh
wget https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/restart.sh
chmod +x /home/$(whoami)/palworld-wine/restart.sh
sed -i "s/YOUR_USERNAME/$(whoami)/g" restart.sh

# 서버 디렉토리 생성 및 설정파일 다운로드(Engine.ini 최적화, GameUserSettings.ini 서버저장 디렉토리 지정)
mkdir -p /home/$(whoami)/palworld-wine/game/Pal/Saved/Config/WindowsServer
wget -P /home/$(whoami)/palworld-wine/game/Pal/Saved/Config/WindowsServer https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/Engine.ini
wget -P /home/$(whoami)/palworld-wine/game/Pal/Saved/Config/WindowsServer https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/GameUserSettings.ini

# 차후 서버이동을 위해 서버저장 폴더 미리 생성(nano 화면에서 새 콘솔창으로 서버데이터 업로드)
mkdir -p /home/$(whoami)/palworld-wine/game/Pal/Saved/SaveGames/0/0123456789ABCDEF0123456789ABCDEF

# 모드설치를 위한 UE4SS,unzip 다운로드 및 압축해제
sudo apt install -y unzip
mkdir -p /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64
wget https://github.com/Okaetsu/RE-UE4SS/releases/download/experimental-palworld/UE4SS-Palworld.zip
unzip UE4SS-Palworld.zip -d "/home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64"
shopt -s dotglob
mv /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/UE4SS-Palworld/* /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/
shopt -u dotglob
rm -r /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/UE4SS-Palworld
rm UE4SS-Palworld.zip

# 팰디펜더 최신버전 다운로드 및 압축해제
wget https://github.com/Ultimeit/PalDefender/releases/latest/download/PalDefender_ProtonWine.zip
unzip PalDefender_ProtonWine.zip -d "/home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64"
rm PalDefender_ProtonWine.zip
mkdir -p /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/PalDefender
wget -P /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/PalDefender https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/Config.json
sed -i "s|127.0.0.1|$(who | awk '{print $5}' | tr -d '()')|g" /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/PalDefender/Config.json

# 팰셰마 최신버전 다운로드 및 압축해제
wget https://github.com/Okaetsu/PalSchema/releases/download/0.4.2/PalSchema_0.4.2.zip
unzip PalSchema_0.4.2.zip -d "/home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/ue4ss/Mods/"
rm PalSchema_0.4.2.zip

# 모드관리 편의를 위한 심불릭링크 
ln -s /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/ue4ss/Mods/ /home/$(whoami)/palworld-wine/UE4SSMods
ln -s /home/$(whoami)/palworld-wine/game/Pal/Content/Paks/LogicMods/ /home/$(whoami)/palworld-wine/LogicMods
ln -s /home/$(whoami)/palworld-wine/game/Pal/Binaries/Win64/PalDefender/ /home/$(whoami)/palworld-wine/PalDefender

# 서버설정 수정
nano default.env
sed -i "s/^REGION=.*/REGION=$(curl -s ifconfig.me)/" default.env

# 팰월드 서버 시작
docker-compose -f /home/$(whoami)/palworld-wine/docker-compose.yml up -d

# Portainer 설치 및 실행(웹에서 서버관리)
mkdir /home/$(whoami)/portainer
wget -P /home/$(whoami)/portainer https://raw.githubusercontent.com/palbungi/palworld-googlecloud/refs/heads/main/portainer/docker-compose.yml
docker-compose -f /home/$(whoami)/portainer/docker-compose.yml up -d

# 팰월드 서버 재시작 설정 스크립트 다운로드 및 실행
wget https://raw.githubusercontent.com/palbungi/palworld-wine/refs/heads/main/timer.sh
chmod +x /home/$(whoami)/palworld-wine/timer.sh
sed -i "s/YOUR_USERNAME/$(whoami)/g" timer.sh
echo "화면을 지웁니다..."
sleep 1
clear
bash timer.sh
sudo systemctl start cron
sudo systemctl enable cron

# 초보들을 위한 Portainer 접속 IP 안내
clear
echo "인터넷창을 열고 접속해주세요: $(curl -s ifconfig.me):8888"
echo "인터넷창을 열고 접속해주세요: $(curl -s ifconfig.me):8888"
echo "인터넷창을 열고 접속해주세요: $(curl -s ifconfig.me):8888"
echo "게임서버 접속 아이피: $(curl -s ifconfig.me):8211"
echo "위 주소들 메모해두세요. 게임서버는 10분 후 접속해주세요."
echo "이제 이 창은 닫아도 됩니다."

# 설치파일 삭제
rm /home/$(whoami)/pb
cd /home/$(whoami)/palworld-wine
