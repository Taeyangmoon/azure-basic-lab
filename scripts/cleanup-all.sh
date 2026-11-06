#!/usr/bin/env bash
# 이 실습에서 만든 모든 리소스 그룹(rg-azlab-*)을 삭제합니다.
# Deletes every resource group created by this lab (rg-azlab-*).
set -euo pipefail

groups=$(az group list --query "[?starts_with(name, 'rg-azlab-')].name" -o tsv)

if [ -z "$groups" ]; then
  echo "삭제할 리소스 그룹이 없습니다. / Nothing to delete."
  exit 0
fi

echo "다음 리소스 그룹을 삭제합니다 / The following resource groups will be deleted:"
echo "$groups" | sed 's/^/  - /'
read -r -p "계속할까요? / Continue? (y/N) " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
  for g in $groups; do
    az group delete --name "$g" --yes --no-wait
    echo "삭제 요청 / Delete requested: $g"
  done
  echo "백그라운드에서 삭제됩니다. 확인: az group list -o table"
else
  echo "취소했습니다. / Cancelled."
fi
