#!/usr/bin/bash

YAML_FILE="docker-compose.yml"
CONTAINER_NAME="palworld-wine-server"

# 10분
docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_10_minutes"

# 5분
sleep 300
docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_5_minutes"

# 3분
sleep 120
docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_3_minutes"

# 2분
sleep 60
docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_2_minutes"

# 1분
sleep 60
docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_60_seconds"

# 저장
docker exec -i $CONTAINER_NAME rcon-cli save

# 10초
sleep 50
docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_10_seconds"

sleep 5

docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_5_seconds"

sleep 1

docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_4_seconds"

sleep 1

docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_3_seconds"

sleep 1

docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_2_seconds"

sleep 1

docker exec -i ${CONTAINER_NAME} rcon-cli "Broadcast Server_will_restart_in_1_seconds"

sleep 1

# 서버 종료
docker exec -i $CONTAINER_NAME rcon-cli "Broadcast Server_is_shutting_down_for_maintance"

# 5초 대기
sleep 5

# 서버 재시작
docker-compose -f "${YAML_FILE}" pull
docker-compose -f "${YAML_FILE}" down
docker-compose -f "${YAML_FILE}" up -d
