# 실습 3. Virtual Network와 네트워크 보안 그룹(NSG)

⏱️ 약 20분 · 💰 비용 없음 (VNet/NSG 자체는 무료)

## 🎯 목표

- VNet(가상 네트워크)과 **서브넷**을 만들고 **주소 공간**을 이해한다.
- **NSG 규칙**으로 트래픽을 허용/차단한다.
- 서브넷에 NSG를 연결해 웹 서브넷과 DB 서브넷을 서로 다르게 보호한다.

## 📚 먼저 알아둘 개념

비유: VNet은 **아파트 단지**, 서브넷은 **동**, NSG는 **동 출입구 경비원**입니다.

| 용어 | 쉬운 설명 |
|---|---|
| **VNet** | Azure 안에 만드는 나만의 사설 네트워크 |
| **주소 공간** | VNet이 쓸 수 있는 IP 범위. 예: `10.0.0.0/16` (약 65,000개) |
| **서브넷** | 주소 공간을 쪼갠 구역. 예: `10.0.1.0/24` (약 250개) |
| **NSG** | 서브넷/NIC에 붙이는 **방화벽 규칙 모음** |
| **우선순위** | 숫자가 **작을수록 먼저** 평가됩니다. 처음 일치한 규칙이 적용됩니다. |

### 이번에 만들 구조

```
vnet-azlab (10.0.0.0/16)
├── snet-web (10.0.1.0/24)  ← nsg-web : HTTP(80) 허용, SSH(22)는 내 IP만
└── snet-db  (10.0.2.0/24)  ← nsg-db  : 3306은 snet-web에서만 허용
```

> 💡 NSG에는 기본 규칙이 있습니다. 인터넷에서 들어오는 트래픽은 **기본 차단**(`DenyAllInBound`), 같은 VNet 안의 트래픽은 **기본 허용**(`AllowVnetInBound`)입니다.

## 1단계. 변수 설정과 리소스 그룹

> 이 리소스 그룹은 **실습 4에서도 사용**합니다. 실습 4를 마친 뒤 삭제하세요.

```bash
RG=rg-azlab-net
LOCATION=koreacentral
VNET=vnet-azlab

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

## 2단계. VNet과 웹 서브넷

```bash
az network vnet create \
  --resource-group $RG \
  --name $VNET \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-web \
  --subnet-prefixes 10.0.1.0/24
```

## 3단계. DB 서브넷 추가

```bash
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET \
  --name snet-db \
  --address-prefixes 10.0.2.0/24

az network vnet subnet list --resource-group $RG --vnet-name $VNET \
  --query "[].{Name:name, Prefix:addressPrefix}" -o table
```

## 4단계. 웹용 NSG 만들기

```bash
az network nsg create --resource-group $RG --name nsg-web

# HTTP는 누구나 허용
az network nsg rule create \
  --resource-group $RG --nsg-name nsg-web --name Allow-HTTP \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes Internet --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 80

# SSH는 지금 이 Codespace의 공인 IP에서만 허용
MY_IP=$(curl -fsS --max-time 20 https://api.ipify.org)
echo $MY_IP

az network nsg rule create \
  --resource-group $RG --nsg-name nsg-web --name Allow-SSH-From-MyIP \
  --priority 110 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes $MY_IP/32 --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 22
```

> 💡 SSH(22)를 `*`(전체)에 열어 두면 전 세계에서 접속 시도가 들어옵니다. 항상 **필요한 IP에만** 열어 주세요.

## 5단계. DB용 NSG 만들기

DB 서브넷은 **웹 서브넷에서 오는 3306 포트만** 허용하고, 같은 VNet의 다른 트래픽은 막습니다.

```bash
az network nsg create --resource-group $RG --name nsg-db

az network nsg rule create \
  --resource-group $RG --nsg-name nsg-db --name Allow-DB-From-Web \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes 10.0.1.0/24 --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 3306

# 기본 규칙(AllowVnetInBound, 65000)보다 먼저 평가되도록 4000번으로 차단
az network nsg rule create \
  --resource-group $RG --nsg-name nsg-db --name Deny-Other-VNet-Inbound \
  --priority 4000 --direction Inbound --access Deny --protocol '*' \
  --source-address-prefixes VirtualNetwork --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges '*'
```

## 6단계. 서브넷에 NSG 연결

```bash
az network vnet subnet update --resource-group $RG --vnet-name $VNET \
  --name snet-web --network-security-group nsg-web

az network vnet subnet update --resource-group $RG --vnet-name $VNET \
  --name snet-db --network-security-group nsg-db
```

## 7단계. 규칙 확인

```bash
az network nsg rule list --resource-group $RG --nsg-name nsg-web --include-default \
  --query "[].{Priority:priority, Name:name, Direction:direction, Access:access, Port:destinationPortRange, Source:sourceAddressPrefix}" \
  -o table
```

표 맨 아래에서 `65000`(AllowVnetInBound), `65500`(DenyAllInBound) **기본 규칙**을 찾아보세요.

🌐 Portal → `nsg-web` → **받는 보안 규칙**에서도 같은 내용을 볼 수 있습니다.

## ✅ 체크포인트

- [ ] 서브넷 2개(`snet-web`, `snet-db`)가 보인다.
- [ ] `nsg-web`에 `Allow-HTTP`, `Allow-SSH-From-MyIP` 규칙이 있다.
- [ ] 두 서브넷 모두 NSG가 연결되어 있다. (`az network vnet subnet show ... --query networkSecurityGroup.id`)

## 🧹 정리

**바로 삭제하지 마세요.** 다음 실습 4에서 이 VNet에 VM을 붙입니다. 실습 4를 끝낸 뒤 삭제합니다.

## 🛠️ 문제 해결

| 증상 | 해결 |
|---|---|
| `AddressSpaceOverlap` | 이미 같은 주소를 쓰는 VNet이 있습니다. 이름과 그룹을 확인하세요. |
| `MY_IP`가 비어 있음 | 네트워크 문제입니다. `curl -s https://ifconfig.me`로 다시 시도하세요. |
| 터미널을 다시 열었더니 변수가 사라짐 | 1단계 변수(`RG`, `LOCATION`, `VNET`)를 다시 입력하세요. |

⬅️ 이전: [실습 2](../02-storage/README.md) · ➡️ 다음: [실습 4. Virtual Machines](../04-vm/README.md)
