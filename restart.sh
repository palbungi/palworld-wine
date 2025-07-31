#!/usr/bin/bash

# 명령어 절대 경로 설정 (각자의 시스템에 맞게 확인하여 채워넣어야 함)
DOCKER_BIN="/usr/bin/docker"
DOCKER_COMPOSE_BIN="/usr/local/bin/docker-compose" # 또는 /usr/bin/docker-compose
SLEEP_BIN="/bin/sleep"
ECHO_BIN="/usr/bin/echo" # 로깅을 위해 추가

# YAML 파일 및 컨테이너 이름 (절대 경로 명시 권장)
YAML_FILE="/home/YOUR_USERNAME/palworld-wine/docker-compose.yml" # docker-compose.yml 파일의 실제 절대 경로
CONTAINER_NAME="palworld-wine-server"

# 로그 시작 메시지
${ECHO_BIN} "$(${DOCKER_BIN} exec -i ${CONTAINER_NAME} /usr/bin/date '+%Y-%m-%d %H:%M:%S') - Server restart script started."

# 10초 서버 종료 명령어 
${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Shutdown 10" || { ${ECHO_BIN} "Shutdown 10" ; exit 1; }

# 10초 경고
${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Broadcast Server_will_restart_in_10_seconds" || { ${ECHO_BIN} "ERROR: Failed to broadcast 10s message." ; exit 1; }

# 서버 저장
${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Save" || { ${ECHO_BIN} "Save" ; exit 1; }

${SLEEP_BIN} 5

${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Broadcast Server_will_restart_in_5_seconds" || { ${ECHO_BIN} "ERROR: Failed to broadcast 5s message." ; exit 1; }

${SLEEP_BIN} 1

${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Broadcast Server_will_restart_in_4_seconds" || { ${ECHO_BIN} "ERROR: Failed to broadcast 4s message." ; exit 1; }

${SLEEP_BIN} 1

${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Broadcast Server_will_restart_in_3_seconds" || { ${ECHO_BIN} "ERROR: Failed to broadcast 3s message." ; exit 1; }

${SLEEP_BIN} 1

${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Broadcast Server_will_restart_in_2_seconds" || { ${ECHO_BIN} "ERROR: Failed to broadcast 2s message." ; exit 1; }

${SLEEP_BIN} 1

${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Broadcast Server_will_restart_in_1_seconds" || { ${ECHO_BIN} "ERROR: Failed to broadcast 1s message." ; exit 1; }

# 로그 종료 메시지
${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Broadcast Server_is_shutting_down_for_maintance" || { ${ECHO_BIN} "ERROR: Failed to broadcast shutdown message." ; exit 1; }
