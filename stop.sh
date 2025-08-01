#!/usr/bin/bash

# 명령어 절대 경로 설정 (각자의 시스템에 맞게 확인하여 채워넣어야 함)
DOCKER_BIN="/usr/bin/docker"
DOCKER_COMPOSE_BIN="/usr/local/bin/docker-compose" # 또는 /usr/bin/docker-compose
SLEEP_BIN="/bin/sleep"
ECHO_BIN="/usr/bin/echo" # 로깅을 위해 추가

# YAML 파일 및 컨테이너 이름 (절대 경로 명시 권장)
YAML_FILE="/home/YOUR_USERNAME/palworld-wine/docker-compose.yml" # docker-compose.yml 파일의 실제 절대 경로
CONTAINER_NAME="palworld-wine-server"

# 시작 메시지
${ECHO_BIN} -e "\e[32m5초 후 서버가 종료 됩니다\e[0m"

# 서버 저장시간 5초대기
${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Save" || { ${ECHO_BIN} "Save" ; exit 1; }
${SLEEP_BIN} 5

# 도커 재시작
${DOCKER_COMPOSE_BIN} -f "${YAML_FILE}" pull || { ${ECHO_BIN} "ERROR: Failed to pull docker images." ; exit 1; }
${DOCKER_COMPOSE_BIN} -f "${YAML_FILE}" down || { ${ECHO_BIN} "ERROR: Failed to stop docker containers." ; exit 1; }

# 서버 재시작 알림
${ECHO_BIN} -e "\e[31m서버가 종료 되었습니다.\e[0m"
