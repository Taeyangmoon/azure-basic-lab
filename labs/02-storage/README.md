# 실습 2. Azure Storage — 스토리지 계정 만들고 살펴보기

⏱️ 약 10분 · 💰 계정 생성·조회 자체는 무료

## 🎯 목표

- 데이터를 담는 **스토리지 계정**을 만들고, 조회하고, 삭제한다.
- 데이터가 저장되는 **리전**과 복제 방식인 **LRS**를 이해한다.
- 리소스 그룹 안에 실제 리소스가 들어가는 모습을 확인한다.

> 이 실습은 파일 업로드나 웹사이트 공개 없이 계정을 관리하는 명령만 사용합니다. 별도의 데이터 접근 역할이나 네트워크 구성은 필요하지 않습니다.

## 📚 먼저 알아둘 개념

| 용어 | 쉬운 설명 |
|---|---|
| **스토리지 계정** | 파일과 데이터를 저장하는 Azure의 "클라우드 저장소 건물" |
| **Blob** | 이미지, 문서, 영상 같은 파일을 저장하는 서비스 |
| **컨테이너** | Blob을 모아 두는 폴더 (Docker 컨테이너와는 다른 개념!) |
| **리전** | 데이터가 저장되는 지역. 이 실습은 `koreacentral`(한국 중부)을 사용합니다. |
| **LRS** | 같은 데이터센터 안에 데이터를 3개 복사본으로 저장하는 방식 |
| **StorageV2** | Blob, 파일, 큐, 테이블 등을 지원하는 범용 스토리지 계정 종류 |

> 💡 LRS는 장비 고장에 대비하는 복제 방식이지, 실수로 삭제한 파일을 되살리는 백업은 아닙니다.

## 1단계. 변수 설정과 리소스 그룹 생성

스토리지 계정 이름은 **전 세계에서 유일**해야 하며, 소문자와 숫자로 된 3~24자 이름을 사용합니다. 구독 ID로 만든 고정 접미사를 사용하면 터미널을 다시 열어도 같은 이름이 만들어집니다.

```bash
RG=rg-azlab-storage
LOCATION=koreacentral
SUFFIX=$(az account show --query id -o tsv | md5sum | cut -c1-8)
STORAGE=stazlab$SUFFIX
echo $STORAGE

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

> ⚠️ 터미널을 새로 열었다면 위 변수 블록을 다시 실행하세요.

## 2단계. 스토리지 계정 만들기

```bash
az storage account create \
  --name $STORAGE \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2
```

- `--location`: 데이터를 저장할 지역입니다.
- `--sku Standard_LRS`: 표준 성능과 LRS 복제를 선택합니다.
- `--kind StorageV2`: 범용 스토리지 계정을 만듭니다.
- `--allow-blob-public-access false`: 일반 Blob의 익명 공개를 허용하지 않습니다.
- 계정 생성에는 1~2분 걸릴 수 있습니다. **아직 파일을 저장한 것은 아닙니다.**

## 3단계. 계정 살펴보기

```bash
# 이번 리소스 그룹의 스토리지 계정 목록
az storage account list --resource-group $RG \
  --query "[].{Name:name, Location:location, Replication:sku.name}" -o table

# 계정 하나의 설정 확인
az storage account show --name $STORAGE --resource-group $RG \
  --query "{Name:name, Location:location, Kind:kind, Replication:sku.name, State:provisioningState}" \
  -o table
```

`Location`은 `koreacentral`, `Kind`는 `StorageV2`, `Replication`은 `Standard_LRS`, `State`는 `Succeeded`인지 확인하세요.

```bash
# 실습 1에서는 비어 있던 그룹에 스토리지 리소스가 들어 있습니다
az resource list --resource-group $RG \
  --query "[].{Name:name, Type:type, Location:location}" -o table
```

🌐 [Azure Portal](https://portal.azure.com) → **리소스 그룹** → `rg-azlab-storage` → 스토리지 계정의 **개요**에서도 이름과 위치를 확인해 보세요.

## 4단계. 정리

```bash
# 삭제가 끝날 때까지 기다립니다
az group delete --name $RG --yes

# false면 삭제 완료
az group exists --name $RG
```

계정과 리소스 그룹이 함께 삭제됩니다. 이후 데이터를 저장한 계정을 삭제할 때는 **안의 데이터도 사라진다**는 점을 기억하세요.

## ✅ 체크포인트

- [ ] 스토리지 계정을 만들었다.
- [ ] 리전(`koreacentral`)과 복제 방식(`Standard_LRS`)을 확인했다.
- [ ] 리소스 그룹 안에서 `Microsoft.Storage/storageAccounts` 리소스를 조회했다.
- [ ] 정리 후 `az group exists`가 `false`를 반환한다.

## 🛠️ 문제 해결

| 증상 | 해결 |
|---|---|
| `StorageAccountAlreadyTaken` | 같은 이름이 이미 사용 중입니다. `STORAGE=stazlab$SUFFIX$RANDOM`으로 바꾸고 2단계를 다시 실행하세요. 새 터미널에서도 이 이름을 사용하세요. |
| `AuthorizationFailed` | 실습 1에서 선택한 구독과 리소스 생성 권한을 확인하세요. |
| 터미널을 새로 열었더니 변수가 사라짐 | 1단계 변수 블록을 다시 실행하세요. |

⬅️ 이전: [실습 1](../01-setup/README.md) · ➡️ 다음: [실습 3. VNet과 NSG](../03-network/README.md)
