# 실습 4. Azure Virtual Machines — cloud-init으로 웹서버 자동 설치

⏱️ 약 25분 · 💰 VM 실행 시간과 디스크·공인 IP 사용에 따라 과금 (끝나면 반드시 삭제!)

## 🎯 목표

- 실습 3의 VNet(`snet-web`)에 Linux VM을 만든다.
- **cloud-init**으로 부팅 시 nginx 웹서버를 자동 설치한다.
- NSG 규칙을 지웠다 다시 만들며 **방화벽의 효과를 눈으로 확인**한다.

## 📚 먼저 알아둘 개념

| 용어 | 쉬운 설명 |
|---|---|
| **IaaS** | 서버(VM)를 빌려 쓰고 OS 이후는 내가 관리하는 방식 |
| **VM 크기** | CPU/메모리 사양. `Standard_B2ats_v2`는 2 vCPU / 1GB의 저렴한 입문용 (예전 `B1s`는 리전에 따라 더 이상 제공되지 않습니다) |
| **cloud-init** | VM 첫 부팅 때 자동으로 패키지 설치·파일 생성을 해주는 설정 파일 |
| **공인 IP** | 인터넷에서 VM에 접속하기 위한 주소 |
| **SSH 키** | 비밀번호 대신 쓰는 열쇠 쌍. 개인키는 내 환경에, 공개키는 VM에 둡니다. |
| **할당 취소 (deallocate)** | VM을 멈추고 컴퓨팅 요금을 중단하는 상태 (디스크 요금은 계속) |

## 사전 조건

**실습 3을 완료**하여 `rg-azlab-net` 그룹에 `vnet-azlab`, `nsg-web`이 있어야 합니다.

```bash
az network vnet list -g rg-azlab-net -o table
```

## 1단계. 변수 설정

```bash
RG=rg-azlab-net
VNET=vnet-azlab
VM=vm-web01
LOCATION=koreacentral
```

## 2단계. cloud-init 파일 살펴보기

[`cloud-init.yaml`](./cloud-init.yaml)을 열어 보세요. 하는 일은 세 가지입니다.

1. `packages`: nginx 설치
2. `write_files`: 첫 화면(`index.html`) 생성
3. `runcmd`: 호스트명을 페이지에 넣고 nginx 시작

## 3단계. VM 만들기

```bash
az vm create \
  --resource-group $RG \
  --name $VM \
  --image Ubuntu2204 \
  --size Standard_B2ats_v2 \
  --vnet-name $VNET \
  --subnet snet-web \
  --nsg "" \
  --public-ip-sku Standard \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data labs/04-vm/cloud-init.yaml
```

- `--nsg ""`: VM(NIC)에는 NSG를 따로 만들지 않습니다. 서브넷에 연결된 `nsg-web`이 보호합니다.
- `--generate-ssh-keys`: `~/.ssh/id_rsa`가 없으면 새로 만듭니다.
- 저장소 루트에서 실행하세요. 1~3분 걸립니다.

> ⚠️ `SkuNotAvailable` 오류가 나면 해당 리전에서 그 크기를 쓸 수 없는 것입니다. 사용 가능한 크기를 조회해 `--size`를 바꾸세요.
> ```bash
> az vm list-skus -l koreacentral --resource-type virtualMachines --size Standard_B \
>   --query '[?length(restrictions)==`0`].name' -o tsv | sort -u
> ```

## 4단계. cloud-init 완료 대기

VM이 "생성됨"과 "웹서버 설치 완료"는 다릅니다. 설치가 끝날 때까지 기다립니다.

```bash
az vm run-command invoke -g $RG -n $VM --command-id RunShellScript \
  --scripts "cloud-init status --wait" --query "value[0].message" -o tsv
```

`status: done`이 보이면 완료입니다.

## 5단계. 웹서버 접속

```bash
IP=$(az vm show -d -g $RG -n $VM --query publicIps -o tsv)
echo http://$IP

curl --fail --max-time 10 http://$IP
```

HTML이 출력되면 성공입니다. 브라우저에서 `http://<IP>`를 열어 봐도 됩니다. 🎉
실습 3에서 만든 `Allow-HTTP` 규칙 덕분에 접속이 가능합니다.

## 6단계. SSH 접속 (선택)

실습 3에서 SSH(22)는 **Codespace의 공인 IP**에만 열어 두었습니다. Codespace 터미널에서 접속해 보세요.

```bash
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new azureuser@$IP
```

VM 안에서 확인하고 `exit`로 나옵니다.

```bash
hostname
systemctl status nginx --no-pager | head -5
exit
```

> 접속이 안 되면 Codespace를 재시작해 공인 IP가 바뀐 경우입니다. 실습 3의 `Allow-SSH-From-MyIP` 규칙의 IP를 갱신하세요.
> ```bash
> az network nsg rule update -g $RG --nsg-name nsg-web -n Allow-SSH-From-MyIP \
>   --source-address-prefixes $(curl -fsS --max-time 20 https://api.ipify.org)/32
> ```

회사망 등에서 SSH 접속이 제한되어 있다면 이 단계는 건너뛰어도 됩니다. 대신 4단계와 같은 **Run Command**로 VM 안에서 명령을 실행해 보세요. SSH를 전체 인터넷에 열 필요가 없습니다.

```bash
az vm run-command invoke -g $RG -n $VM --command-id RunShellScript \
  --scripts "hostname; systemctl is-active nginx" --query "value[0].message" -o tsv
```

## 7단계. 🔬 NSG 효과 직접 확인하기

HTTP 허용 규칙을 **삭제**합니다.

```bash
az network nsg rule delete -g $RG --nsg-name nsg-web -n Allow-HTTP

# 적용에 몇 초 걸립니다
sleep 15
curl --max-time 5 http://$IP
```

`curl: (28)` 시간 초과 오류가 나오면 방화벽이 접속을 막은 것입니다. 다른 오류는 차단 확인으로 간주하지 마세요. 서버는 계속 실행 중입니다. 이제 규칙을 **복구**합니다.

```bash
az network nsg rule create \
  --resource-group $RG --nsg-name nsg-web --name Allow-HTTP \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes Internet --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 80

sleep 15
curl --fail --max-time 10 http://$IP
```

다시 접속되면 성공입니다.

## 8단계. 비용 아끼기: 중지와 정리

잠시 쉬어 갈 때는 **할당 취소**로 컴퓨팅 요금을 멈춥니다. (그냥 OS에서 shutdown 하면 요금이 계속됩니다.)

```bash
az vm deallocate -g $RG -n $VM    # 중지
az vm start -g $RG -n $VM         # 다시 시작
```

실습을 모두 마쳤다면 **리소스 그룹을 삭제**합니다.

```bash
az group delete --name $RG --yes
az group exists --name $RG   # false면 삭제 완료
```

> 💡 실습 5에서 같은 구성을 Bicep으로 다시 만들어 보므로 이 시점에 삭제하는 것을 권장합니다.

## ✅ 체크포인트

- [ ] `curl http://$IP`에서 "Hello from Azure VM!" 페이지가 보였다.
- [ ] `Allow-HTTP` 삭제 후 접속이 차단되었고, 복구 후 다시 접속되었다.
- [ ] 리소스 그룹을 삭제했다.

## 🛠️ 문제 해결

| 증상 | 해결 |
|---|---|
| `curl` 연결 거부/시간 초과 (처음부터) | 4단계 cloud-init 완료 대기를 했는지, `nsg-web`에 `Allow-HTTP`가 있고 서브넷에 연결됐는지 확인 |
| `ssh: Permission denied (publickey)` | `ls ~/.ssh/id_rsa*` 확인. Codespace를 새로 만들었다면 키가 없으므로 VM을 다시 만드세요. |
| `ssh` 시간 초과 | 6단계의 SSH 규칙 IP를 갱신하세요. 그래도 안 되면 SSH 대신 Run Command를 사용하세요. 회사망/VPN에서는 접속이 제한되거나 출발지 IP가 다를 수 있습니다. |
| `cloud-init status`가 `error` | VM 안에서 `sudo cat /var/log/cloud-init-output.log` 확인 |
| `--custom-data` 파일을 찾을 수 없음 | 저장소 루트에서 실행했는지 확인 (`pwd`) |

⬅️ 이전: [실습 3](../03-network/README.md) · ➡️ 다음: [실습 5. Bicep 기초](../05-bicep/README.md)
