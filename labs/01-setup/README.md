# 실습 1. 실습 환경 준비

⏱️ 약 15분 · 💰 비용 없음

## 🎯 목표

- GitHub Codespaces에서 Azure CLI를 사용할 수 있다.
- `az login --use-device-code`로 Azure에 로그인한다.
- **리소스 그룹**을 만들고, 조회하고, 삭제한다.

## 📚 먼저 알아둘 개념

| 용어 | 쉬운 설명 |
|---|---|
| **구독 (Subscription)** | Azure 사용 요금이 청구되는 "계정 단위"입니다. |
| **리소스 (Resource)** | VM, 스토리지, 네트워크처럼 Azure에서 만드는 모든 것입니다. |
| **리소스 그룹 (Resource Group)** | 리소스를 담는 **폴더**입니다. 폴더째 삭제하면 안의 리소스가 모두 사라집니다. |
| **리전 (Region)** | 데이터센터가 있는 지역입니다. 이 실습은 `koreacentral`(한국 중부)을 사용합니다. |
| **Azure CLI (`az`)** | 터미널에서 Azure를 조작하는 명령줄 도구입니다. |

> 💡 **핵심 습관**: 실습마다 리소스 그룹을 따로 만들고, 끝나면 **그룹째 삭제**합니다. 비용이 새는 것을 막는 가장 확실한 방법입니다.

## 사전 준비

- GitHub 계정
- Azure 구독 ([무료 계정 만들기](https://azure.microsoft.com/free/))

## 1단계. Codespaces 열기

1. 이 저장소 메인 페이지에서 **Code → Codespaces → Create codespace on main**을 클릭합니다.
2. 1~2분 기다리면 브라우저에서 VS Code가 열립니다. (Azure CLI와 Bicep이 자동 설치되어 있습니다.)
3. 터미널(`` Ctrl+` ``)을 열고 확인합니다.

```bash
az version
```

## 2단계. Azure 로그인

Codespaces는 브라우저 안에서 동작하므로 **디바이스 코드 방식**으로 로그인합니다.

```bash
az login --use-device-code
```

1. 터미널에 `https://microsoft.com/devicelogin` 주소와 **코드**가 표시됩니다.
2. 링크를 열고 코드를 입력한 뒤, 사용할 Azure 계정으로 로그인합니다.
3. 터미널에 구독 목록이 출력되면 성공입니다.

> ⚠️ 회사/학교 계정에서 구독이 여러 개 보이면 아래 3단계에서 실습용 구독을 선택하세요.

## 3단계. 구독 확인

```bash
# 현재 사용 중인 구독
az account show --query "{Name:name, Id:id, State:state}" -o table

# 구독 목록
az account list --query "[].{Name:name, Id:id, IsDefault:isDefault}" -o table
```

다른 구독을 쓰려면:

```bash
az account set --subscription "<구독 이름 또는 ID>"
```

## 4단계. 리소스 공급자 등록 (처음 한 번)

새 구독은 일부 서비스가 등록되어 있지 않아 오류가 날 수 있습니다. 이 실습에서 쓰는 서비스를 미리 등록합니다.

```bash
for ns in Microsoft.Storage Microsoft.Network Microsoft.Compute; do
  az provider register --namespace $ns
done

# 모두 Registered가 될 때까지 몇 분 걸릴 수 있습니다
az provider list --query "[?namespace=='Microsoft.Storage' || namespace=='Microsoft.Network' || namespace=='Microsoft.Compute'].{Namespace:namespace, State:registrationState}" -o table
```

## 5단계. 리소스 그룹 만들기

```bash
RG=rg-azlab-hello
LOCATION=koreacentral

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

> 💡 이름 규칙: 이 실습의 모든 리소스 그룹은 `rg-azlab-` 로 시작합니다. 나중에 한꺼번에 찾아 지우기 쉽습니다.

## 6단계. 조회하기

```bash
# 내 리소스 그룹 목록
az group list --query "[?starts_with(name,'rg-azlab-')].{Name:name, Location:location, State:properties.provisioningState}" -o table

# 하나만 자세히
az group show --name $RG -o jsonc

# 그룹 안의 리소스 (지금은 비어 있습니다)
az resource list --resource-group $RG -o table
```

🌐 [Azure Portal](https://portal.azure.com) → **리소스 그룹**에서도 같은 그룹이 보이는지 확인해 보세요.

## 7단계. 삭제하기

```bash
az group delete --name $RG --yes

# 삭제 완료 확인 (false면 삭제됨)
az group exists --name $RG
```

- `--yes`: 확인 질문 생략
- 삭제가 완료될 때까지 기다립니다. 몇 분 걸릴 수 있습니다.

## ✅ 체크포인트

- [ ] `az account show`에 내 구독이 표시된다.
- [ ] `az group create`로 만든 그룹이 Portal에서 보인다.
- [ ] `az group exists`가 `false`를 반환한다.

## 🛠️ 문제 해결

| 증상 | 해결 |
|---|---|
| 로그인 후 구독이 없다고 나옴 | 무료 구독이 활성화되었는지 Portal에서 확인하세요. |
| `AuthorizationFailed` | 해당 구독에서 **Contributor** 이상의 역할이 필요합니다. |
| `MissingSubscriptionRegistration` | 4단계의 공급자 등록을 다시 실행하고 잠시 기다리세요. |
| 토큰 만료 | `az login --use-device-code`를 다시 실행합니다. |

➡️ 다음: [실습 2. Azure Storage](../02-storage/README.md)
