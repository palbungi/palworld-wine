#!/usr/bin/bash

# =============================================================================
# 상수 및 경로 설정
# =============================================================================
DOCKER_BIN="/usr/bin/docker"
DOCKER_COMPOSE_BIN="/usr/local/bin/docker-compose"
SLEEP_BIN="/bin/sleep"
ECHO_BIN="/usr/bin/echo"
DATE_BIN="/usr/bin/date"

# 서버 설정 (사용자 환경에 맞게 수정 필요)
YAML_FILE="/home/YOUR_USERNAME/palworld-wine/docker-compose.yml"
CONTAINER_NAME="palworld-wine-server"

# =============================================================================
# 함수 정의
# =============================================================================

# 브로드캐스트 메시지 전송 함수
broadcast() {
    local message="$1"
    ${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "Broadcast ${message}" || {
        ${ECHO_BIN} "ERROR: Failed to broadcast message: ${message}" >&2
        return 1
    }
    return 0
}

# rcon 명령어 실행 함수
execute_rcon() {
    local command="$1"
    ${DOCKER_BIN} exec -i ${CONTAINER_NAME} rconcli "${command}" || {
        ${ECHO_BIN} "ERROR: Failed to execute RCON command: ${command}" >&2
        return 1
    }
    return 0
}

# 대기 함수 (로그 포함)
wait_with_log() {
    local seconds=$1
    local reason="$2"
    ${ECHO_BIN} "$(${DATE_BIN} '+%Y-%m-%d %H:%M:%S') - Waiting ${seconds}s: ${reason}"
    ${SLEEP_BIN} ${seconds}
}

# =============================================================================
# 서버 재시작 프로세스 시작
# =============================================================================
${ECHO_BIN} "$(${DATE_BIN} '+%Y-%m-%d %H:%M:%S') - Server restart script started"

# 10분 후 서버 종료 예약
execute_rcon "Shutdown 600" || exit 1
broadcast "Server_will_restart_in_10_minutes" || exit 1

# 5분 대기
wait_with_log 300 "Until 5-minute warning"

# 5분 경고
broadcast "Server_will_restart_in_5_minutes" || exit 1

# 2분 대기
wait_with_log 120 "Until 3-minute warning"

# 3분 경고
broadcast "Server_will_restart_in_3_minutes" || exit 1

# 1분 대기
wait_with_log 60 "Until 2-minute warning"

# 2분 경고
broadcast "Server_will_restart_in_2_minutes" || exit 1

# 1분 대기
wait_with_log 60 "Until 1-minute warning"

# 1분 경고
broadcast "Server_will_restart_in_60_seconds" || exit 1

# 서버 상태 저장
execute_rcon "save" || exit 1

# 50초 대기
wait_with_log 50 "Until 10-second warning"

# 10초 경고
broadcast "Server_will_restart_in_10_seconds" || exit 1

# 5초 대기
wait_with_log 5 "Until 5-second countdown"

# 서버 상태 저장
execute_rcon "save" || exit 1

# 초 단위 카운트다운
for i in {5..1}; do
    broadcast "Server_will_restart_in_${i}_seconds" || exit 1
    ${SLEEP_BIN} 1
done

# 최종 서버 종료 알림
execute_rcon "Broadcast Server_is_shutting_down_for_maintance" || exit 1

# =============================================================================
# 스크립트 종료
# =============================================================================
${ECHO_BIN} "$(${DATE_BIN} '+%Y-%m-%d %H:%M:%S') - Server restart script completed successfully"
exit 0
