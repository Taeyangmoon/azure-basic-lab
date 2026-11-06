# 실습 2. Azure Storage — Blob 업로드와 정적 웹사이트

⏱️ 약 20분 · 💰 거의 무료 (삭제 전까지 몇 원 미만)

## 🎯 목표

- 스토리지 계정을 만들고 Blob(파일)을 업로드한다.
- 파일이 기본적으로 **비공개**임을 확인하고, **SAS 토큰**으로 임시 공유한다.
- 정적 웹사이트를 호스팅해 웹페이지를 공개한다.

## 📚 먼저 알아둘 개념

| 용어 | 쉬운 설명 |
|---|---|
| **스토리지 계정** | Azure의 "클라우드 저장소 건물". 안에 Blob/파일/큐/테이블 서비스가 들어 있습니다. |
| **컨테이너** | Blob을 담는 폴더 (Docker 컨테이너와는 다른 개념!) |
| **Blob** | 파일 하나 (이미지, 문서, 영상 등) |
| **SAS 토큰** | "이 파일을, 이 권한으로, 이 시간 동안만" 접근하게 해주는 임시 출입증 |
| **정적 웹사이트** | HTML/CSS/JS 같은 고정 파일을 서버 없이 바로 서비스하는 기능 (`$web` 컨테이너 사용) |
| **LRS** | 같은 데이터센터 안에 3개 복사본을 저장하는 가장 저렴한 중복 옵션 |

## 1단계. 변수 설정과 리소스 그룹 생성

스토리지 계정 이름은 **전 세계에서 유일**해야 합니다. 내 구독 ID로 만든 고정 접미사를 사용하면 터미널을 다시 열어도 같은 이름이 만들어집니다.

```bash
RG=rg-azlab-storage
LOCATION=koreacentral
SUFFIX=$(az account show --query id -o tsv | md5sum | cut -c1-8)
STORAGE=stazlab$SUFFIX
echo $STORAGE

# 실습 편의를 위해 계정 키로 데이터 작업을 수행합니다 (아래 💡 참고)
export AZURE_STORAGE_AUTH_MODE=key
export AZURE_STORAGE_ACCOUNT=$STORAGE

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

> 💡 운영 환경에서는 계정 키 대신 **Microsoft Entra ID 인증**(`--auth-mode login`)과 RBAC 역할(Storage Blob Data Contributor)을 권장합니다. 이 실습은 단순함을 위해 키를 사용합니다.

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

- `--allow-blob-public-access false`: 익명 공개를 계정 수준에서 막는 보안 설정입니다.
- 1~2분 걸립니다.

## 3단계. Blob 업로드

```bash
az storage container create --name docs

echo "Hello Azure Storage!" > hello.txt
az storage blob upload --container-name docs --name hello.txt --file hello.txt

az storage blob list --container-name docs --query "[].{Name:name, Size:properties.contentLength}" -o table
```

## 4단계. 기본은 비공개! 확인하기

인증 없이 파일 주소에 접근해 봅니다.

```bash
curl -i https://$STORAGE.blob.core.windows.net/docs/hello.txt
```

`409 PublicAccessNotPermitted` 또는 `404` 같은 **오류**가 나오면 정상입니다. 파일은 안전하게 비공개 상태입니다.

## 5단계. SAS 토큰으로 임시 공유

10분짜리 읽기 전용 링크를 만듭니다.

```bash
EXPIRY=$(date -u -d "+10 minutes" '+%Y-%m-%dT%H:%MZ')
URL=$(az storage blob generate-sas \
  --container-name docs --name hello.txt \
  --permissions r --expiry $EXPIRY --https-only --full-uri -o tsv)

curl "$URL"
```

`Hello Azure Storage!`가 출력되면 성공입니다. 10분이 지나면 같은 링크가 더 이상 동작하지 않습니다.

## 6단계. 정적 웹사이트 호스팅

```bash
# 기능 켜기
az storage blob service-properties update \
  --static-website \
  --index-document index.html \
  --404-document 404.html

# labs/02-storage/web 폴더를 $web 컨테이너로 업로드 (저장소 루트에서 실행)
az storage blob upload-batch --source labs/02-storage/web --destination '$web' --overwrite

# 웹사이트 주소
az storage account show --name $STORAGE --resource-group $RG --query "primaryEndpoints.web" -o tsv
```

출력된 주소를 터미널에서 `Ctrl+클릭`(또는 브라우저에 붙여넣기)해서 열어 보세요. 🎉

존재하지 않는 경로(예: `/nothing`)도 열어 `404.html`이 나오는지 확인해 보세요.

> 💡 정적 웹사이트(`$web`)는 계정 수준에서 익명 공개를 막아 두어도 동작합니다. 일반 Blob 컨테이너는 계속 비공개입니다.

## 7단계. 정리

```bash
az group delete --name $RG --yes --no-wait
rm -f hello.txt
```

## ✅ 체크포인트

- [ ] 4단계에서 익명 접근이 거부되었다.
- [ ] 5단계 SAS 링크로 파일 내용을 읽었다.
- [ ] 6단계 웹사이트 주소에서 "Hello, Azure!" 페이지가 보였다.

## 🛠️ 문제 해결

| 증상 | 해결 |
|---|---|
| `StorageAccountAlreadyTaken` | 이름이 중복됩니다. `STORAGE=stazlab$SUFFIX$RANDOM`처럼 숫자를 덧붙이세요. |
| `date: invalid date` | macOS 로컬에서 실행한 경우입니다. Codespaces(Linux)에서 실행하세요. |
| 업로드 시 `AuthorizationFailure` | `echo $AZURE_STORAGE_AUTH_MODE`가 `key`인지 확인하고, 1단계 변수 블록을 다시 실행하세요. |
| 웹사이트가 403/404 | 6단계 `--static-website`를 실행했는지, 파일이 `$web`에 있는지 `az storage blob list -c '$web' -o table`로 확인하세요. |

⬅️ 이전: [실습 1](../01-setup/README.md) · ➡️ 다음: [실습 3. VNet과 NSG](../03-network/README.md)
