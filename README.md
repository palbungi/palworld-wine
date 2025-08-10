# 팰월드 WINE 서버 구축 가이드 (구글 클라우드)
> **TIP**: 구글 클라우드 계정 생성 시 **가상 카드(신한, 국민, 현대)** 사용을 권장합니다.  
> 무료 평가판 이후 예상치 못한 과금을 방지하고 예산을 제어할 수 있습니다.
---
## 🔒 필수 선행 작업: 방화벽 설정
팰월드 서버가 정상적으로 작동하려면 특정 포트를 개방해야 합니다. 구글 클라우드 콘솔에서 다음 절차를 수행하세요.
1. [구글 클라우드 VPC 방화벽 규칙 페이지](https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/add)로 이동합니다.
2. **방화벽 규칙 만들기**를 클릭합니다.
3. **이름**을 입력하고, **대상**은 `네트워크의 모든 인스턴스`로 설정합니다.
4. **소스 IPv4 범위**에 `0.0.0.0/0`을 입력합니다.
5. **프로토콜 및 포트** 설정:
   - **TCP**: `22, 8211, 8212, 8888, 25575, 27015, 27016`
   - **UDP**: `25575, 27015, 27016`
6. **저장**을 클릭합니다.
> **참고**: 이 포트들은 팰월드 서버 통신에 필수적입니다. ([Steam 통신 포트 공식 문서](https://partner.steamgames.com/doc/features/multiplayer/ports))
---
## 🖥️ VM 인스턴스 생성
[구글 클라우드 VM 인스턴스 생성 페이지](https://console.cloud.google.com/compute/instances)에서 다음 설정으로 인스턴스를 생성합니다.
- **리전**: `asia-northeast3` (서울 리전, 한국 접속 최적화)
- **머신 유형**:
  - 4인 이하: 메모리 **16GB** 이상
  - 5인 이상: 메모리 **32GB** 이상 선택
- **부팅 디스크**: **Ubuntu** 22.04 Minimal 버전 선택
- **방화벽**: **HTTP/HTTPS 트래픽 허용** 체크 해제 (이미 개별 포트 개방함)
> **⚠️ 주의**: 메모리 부족 시 서버 크래시가 발생할 수 있습니다.  
> [Palworld 공식 서버 권장 사양](https://tech.palworldgame.com/server-requirements)에 따르면 10명 동시 접속 시 32GB 메모리 권장.
---
## ⚙️ 서버 자동 설정 스크립트 실행
SSH로 VM 인스턴스에 접속한 후 다음 명령어를 실행합니다:
```bash
wget -O pb https://sundang.mooo.com/wine && bash pb
```
이 스크립트는 다음과 같은 작업을 자동으로 수행합니다:
- Docker 및 Docker Compose 설치
- 팰월드 서버 파일 다운로드
- 서버 점검 스크립트 설정
---
## 🛠️ 서버 설정 변경
스크립트 실행이 완료되면 `nano` 편집기가 열립니다. 다음 항목을 수정하세요:
- `서버 이름`
- `접속 비밀번호`
- `경험치/드롭률 등 게임 내 배율 설정`
저장 방법:
1. **Ctrl+O** 누름
2. **Enter** 입력 (변경 사항 저장)
3. **Ctrl+x** 누름
---
## ⚡ 최적화 팁
- **서버 부하 감소**: 설정 파일에서 `bEnableInvaderEnemy` 값을 `false`로 변경하면 NPC 침략 이벤트가 비활성화되어 서버 부하를 20% 가량 줄일 수 있습니다. ([Reddit 실험 결과 참고](https://redd.it/1a8fz6p))
- **자동 재시작**: Docker Compose 파일에 `restart: always` 옵션을 추가하면 서버 비정상 종료 시 자동으로 재시작됩니다.
```yaml
# docker-compose.yml 예시
services:
  palworld:
    image: ...
    restart: always
```
---
## ❓ 문제 해결
- **접속 불가 시**: 방화벽 규칙이 올바르게 적용되었는지 확인하세요.
- **서버 크래시**: 메모리 부족일 수 있습니다. VM 머신 유형을 상위 사양으로 업그레이드하세요.
- **스크립트 오류**: 최신 Ubuntu 버전을 사용 중인지 확인하세요.
> 문의 사항은 [GitHub 이슈](https://github.com/palbungi/palworld-wine/issues)로 등록해 주세요.

