# 실습 5. Bicep 기초 — 실습 3·4를 코드로 재현하기

⏱️ 약 25분 · 💰 VM 실행 시간만큼 과금 (끝나면 삭제!)

## 🎯 목표

- 실습 3·4에서 CLI로 한 작업을 **Bicep 파일 하나**로 재현한다.
- `what-if`로 배포 전에 변경 사항을 미리 확인한다.
- **같은 파일을 여러 번 배포해도 안전**(멱등성)함을 확인한다.

## 📚 먼저 알아둘 개념

| 용어 | 쉬운 설명 |
|---|---|
| **IaC (Infrastructure as Code)** | 인프라를 **코드**로 정의해 반복 가능하고 검토 가능하게 만드는 방식 |
| **Bicep** | Azure 전용 IaC 언어. ARM 템플릿(JSON)보다 훨씬 읽기 쉽습니다. |
| **선언형** | "어떻게 만들지"가 아니라 "최종 모습이 이래야 한다"를 적습니다. Azure가 알아서 맞춥니다. |
| **멱등성** | 같은 코드를 몇 번 배포해도 결과가 같다는 성질 |
| **what-if** | 실제 배포 없이 "무엇이 생성/변경/삭제될지" 미리 보여주는 기능 |

### CLI vs Bicep 비교

| | CLI (실습 3·4) | Bicep (실습 5) |
|---|---|---|
| 방식 | 명령을 **순서대로** 실행 | 원하는 상태를 **선언** |
| 명령 수 | 약 20개 | 배포 명령 1개 |
| 재실행 | 이미 있으면 오류/중복 가능 | 안전하게 다시 실행 가능 |
| 검토/공유 | 터미널 기록뿐 | 코드로 리뷰·버전 관리(Git) |
| 미리 보기 | 없음 | `what-if` |

## 1단계. 변수와 SSH 키 준비

```bash
RG=rg-azlab-bicep
LOCATION=koreacentral

# SSH 키가 없다면 생성
[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa

MY_IP=$(curl -s https://api.ipify.org)
echo $MY_IP

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

## 2단계. Bicep 파일 읽기

[`main.bicep`](./main.bicep)을 열어 보세요. VS Code의 Bicep 확장이 색상과 자동 완성을 제공합니다.

CLI 명령과 코드를 짝지어 보면 이해가 쉽습니다.

| 실습 3·4의 CLI | `main.bicep`의 리소스 |
|---|---|
| `az network nsg create` + `rule create` | `resource nsgWeb`, `resource nsgDb` |
| `az network vnet create` + `subnet create` | `resource vnet` (subnets 배열) |
| `--network-security-group nsg-web` | `networkSecurityGroup: { id: nsgWeb.id }` |
| `az vm create`가 자동 생성한 공인 IP | `resource pip` |
| `az vm create`가 자동 생성한 NIC | `resource nic` |
| `az vm create --custom-data` | `customData: loadFileAsBase64(...)` |
| `az vm create` | `resource vm` |

주목할 점:

- `nsgWeb.id`처럼 다른 리소스를 **참조**하면 Bicep이 생성 **순서를 자동으로** 계산합니다. (CLI에서는 내가 순서를 챙겨야 했죠.)
- `param`으로 값을 바깥에서 바꿀 수 있습니다. (VM 크기, SSH IP 등)

## 3단계. 문법 검사

```bash
az bicep install   # Codespaces에는 이미 설치되어 있어 건너뛰어도 됩니다
az bicep build --file labs/05-bicep/main.bicep --stdout > /dev/null && echo "✅ 문법 OK"
```

## 4단계. what-if로 미리 보기

```bash
az deployment group what-if \
  --resource-group $RG \
  --template-file labs/05-bicep/main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)" sshSourceCidr="$MY_IP/32"
```

초록색 `+ Create`로 6개 리소스(NSG 2, VNet, 공인 IP, NIC, VM)가 생성될 예정임을 보여 줍니다. **아직 아무것도 만들어지지 않았습니다.**

## 5단계. 배포

```bash
az deployment group create \
  --resource-group $RG \
  --template-file labs/05-bicep/main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)" sshSourceCidr="$MY_IP/32" \
  --query properties.outputs -o jsonc
```

몇 분 뒤 출력에 `publicIp`, `webUrl`이 나옵니다.

## 6단계. 확인

cloud-init 설치가 끝나길 기다린 뒤 접속합니다.

```bash
az vm run-command invoke -g $RG -n vm-web01 --command-id RunShellScript \
  --scripts "cloud-init status --wait" --query "value[0].message" -o tsv

IP=$(az deployment group show -g $RG -n main --query properties.outputs.publicIp.value -o tsv)
curl http://$IP
```

실습 4와 **똑같은 웹페이지**가 나옵니다. 20여 개 명령이 파일 하나로 대체되었습니다. 🎉

```bash
az resource list -g $RG -o table
```

## 7단계. 멱등성과 변경 확인

**같은 파일을 다시** what-if 해봅니다.

```bash
az deployment group what-if -g $RG --template-file labs/05-bicep/main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)" sshSourceCidr="$MY_IP/32"
```

VM·NSG·VNet은 `= Nochange`로 나옵니다. (NIC나 공인 IP는 Azure가 채운 기본값 때문에 `~ Modify`로 보일 수 있지만, 이는 what-if의 알려진 노이즈이며 실제 변경은 없습니다.)

이제 `main.bicep`에서 `nsgWeb`의 `Allow-HTTP` 규칙 `destinationPortRange: '80'`을 `'8080'`으로 바꾸고 다시 what-if 를 실행하면 `nsg-web`에 `~ properties.destinationPortRange: "80" => "8080"`이 표시됩니다.

확인했다면 `'80'`으로 되돌리세요.

> 💡 이것이 IaC의 가치입니다. 인프라 변경이 **코드 리뷰(PR)** 로 검토되고, 실행 전에 **영향을 미리 보고**, 언제든 **같은 환경을 재현**할 수 있습니다.

## 8단계. 정리

```bash
az group delete --name $RG --yes --no-wait
```

실습 3·4의 그룹(`rg-azlab-net`)을 아직 삭제하지 않았다면 함께 지웁니다.

```bash
./scripts/cleanup-all.sh
```

## ✅ 체크포인트

- [ ] `what-if`로 배포 전 변경 사항을 확인했다.
- [ ] 배포 결과가 실습 4와 같은 웹페이지를 보여 주었다.
- [ ] 같은 템플릿을 다시 what-if 했을 때 VM·NSG·VNet에 변경이 없었다.
- [ ] 모든 `rg-azlab-*` 그룹을 삭제했다. (`az group list -o table`)

## 🛠️ 문제 해결

| 증상 | 해결 |
|---|---|
| `SkuNotAvailable` | `--parameters vmSize=Standard_B2s_v2` 처럼 다른 크기를 지정하세요. (사용 가능 크기 조회는 [실습 4](../04-vm/README.md) 참고) |
| `InvalidTemplateDeployment` + SSH 키 오류 | `cat ~/.ssh/id_rsa.pub`가 `ssh-rsa`로 시작하는 한 줄인지 확인 |
| `curl` 안 됨 | cloud-init 대기(6단계)를 먼저 하세요. |

## 🎓 수료를 축하합니다!

기초 5개 실습을 모두 마쳤습니다. 다음 단계로 App Service, Azure SQL, Key Vault, 컨테이너(ACA/AKS), 모니터링 등을 학습해 보세요.

⬅️ 이전: [실습 4](../04-vm/README.md) · 🏠 [처음으로](../../README.md)
