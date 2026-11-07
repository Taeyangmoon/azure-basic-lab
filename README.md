# ☁️ Azure Basic Lab — 처음 시작하는 Azure 핸즈온

**한국어** | [English](./README.en.md)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/Taeyangmoon/azure-basic-lab)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

Azure를 처음 접하는 분을 위한 **5개의 기초 실습**입니다. 설치 없이 **GitHub Codespaces** 안에서 브라우저만으로 진행합니다.

## 📋 커리큘럼

| # | 실습 | 배우는 것 | 시간 |
|---|---|---|---|
| 1 | [실습 환경 준비](./labs/01-setup/README.md) | Codespaces, `az login --use-device-code`, 리소스 그룹 생성·삭제 | 15분 |
| 2 | [Azure Storage](./labs/02-storage/README.md) | 스토리지 계정 생성·조회·삭제, 리전과 LRS | 10분 |
| 3 | [VNet과 NSG](./labs/03-network/README.md) | 주소 공간, 서브넷, 보안 규칙 | 20분 |
| 4 | [Virtual Machines](./labs/04-vm/README.md) | Linux VM, cloud-init으로 웹서버 자동 설치 | 25분 |
| 5 | [Bicep 기초](./labs/05-bicep/README.md) | 3·4번을 코드(IaC)로 재현, what-if | 25분 |

> 순서대로 진행하는 것을 권장합니다. 실습 4는 실습 3에서 만든 네트워크 위에서 진행됩니다.

## 🧰 준비물

- GitHub 계정
- Azure 구독 ([무료 계정](https://azure.microsoft.com/free/)으로 충분합니다)

로컬에 아무것도 설치할 필요가 없습니다. Azure CLI와 Bicep은 Codespaces 환경에 미리 설치됩니다 ([`.devcontainer`](./.devcontainer/devcontainer.json)).

## 🚀 시작하기

1. 위 **Open in GitHub Codespaces** 버튼을 클릭합니다. (또는 **Code → Codespaces → Create codespace on main**)
2. 환경이 준비되면 터미널에서 [실습 1](./labs/01-setup/README.md)부터 시작합니다.

> 이 저장소를 포크했다면 위 Codespaces 배지의 `Taeyangmoon/azure-basic-lab`을 본인 저장소 경로로 바꾸세요.

## 💰 비용 주의

- 실습 1·2·3의 리소스 생성·조회는 무료입니다. 실습 4·5는 VM 실행 시간과 디스크·공인 IP 사용에 따라 과금됩니다.
- 실습 1·2·4·5가 끝나면 **리소스 그룹을 삭제**하세요. 실습 3의 그룹은 실습 4에서 이어서 사용합니다.
- 잊었을 때를 위한 일괄 정리 스크립트:

```bash
./scripts/cleanup-all.sh   # rg-azlab-* 그룹을 모두 삭제
```

- [Azure Portal → 비용 관리](https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview)에서 예산 알림을 설정해 두면 더 안전합니다.

## 🗂️ 저장소 구조

```
.
├── .devcontainer/        # Codespaces 환경 (Azure CLI + Bicep)
├── labs/
│   ├── 01-setup/         # 실습 문서 (README.md = 한국어, README.en.md = English)
│   ├── 02-storage/       # 스토리지 계정과 리전·LRS
│   ├── 03-network/
│   ├── 04-vm/cloud-init.yaml
│   └── 05-bicep/main.bicep
├── scripts/cleanup-all.sh
└── LICENSE
```

## 📏 실습 규칙

- 리소스 그룹 이름은 `rg-azlab-*`, 기본 리전은 `koreacentral`입니다.
- 모든 명령은 **저장소 루트**에서 실행하는 것을 기준으로 합니다.
- 터미널을 새로 열면 변수가 사라지므로, 각 실습 첫 단계의 변수 블록을 다시 실행하세요.

## 🤝 기여

오탈자, 개선 제안은 Issue/PR로 환영합니다.

## 📄 라이선스

[MIT License](./LICENSE)
