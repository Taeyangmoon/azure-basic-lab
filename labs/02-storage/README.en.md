# Lab 2. Azure Storage — Blob Upload and Static Website

⏱️ ~20 min · 💰 Nearly free (cents at most before you delete it)

## 🎯 Goals

- Create a storage account and upload a blob (file).
- See that files are **private by default**, then share one temporarily with a **SAS token**.
- Host a static website.

## 📚 Key concepts

| Term | In plain words |
|---|---|
| **Storage account** | The "cloud storage building". Blob, file, queue and table services live inside. |
| **Container** | A folder for blobs (not the same as a Docker container!). |
| **Blob** | A single file (image, document, video…). |
| **SAS token** | A temporary pass: "this file, with this permission, for this long". |
| **Static website** | Serves fixed HTML/CSS/JS directly from storage, no server needed (uses the `$web` container). |
| **LRS** | The cheapest redundancy option: 3 copies inside one datacenter. |

## Step 1. Variables and resource group

A storage account name must be **globally unique**. A stable suffix derived from your subscription ID gives the same name even if you reopen the terminal.

```bash
RG=rg-azlab-storage
LOCATION=koreacentral
SUFFIX=$(az account show --query id -o tsv | md5sum | cut -c1-8)
STORAGE=stazlab$SUFFIX
echo $STORAGE

# Data operations (uploads etc.) authenticate with your Entra ID login instead of the account key
export AZURE_STORAGE_AUTH_MODE=login
export AZURE_STORAGE_ACCOUNT=$STORAGE

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

> 💡 We use **Microsoft Entra ID** auth (`--auth-mode login`) instead of account keys. It's more secure and also works on subscriptions where policy blocks key auth (`KeyBasedAuthenticationNotPermitted`). In exchange you must grant yourself a data **RBAC role** (Step 2).

> ⚠️ If you open a new terminal, run the variable block again.

## Step 2. Create the storage account

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

- `--allow-blob-public-access false`: blocks anonymous public access at the account level.
- Takes 1–2 minutes.

Grant yourself a blob data role. (Management roles such as Owner/Contributor alone can't read or write data.)

```bash
az role assignment create \
  --assignee-object-id $(az ad signed-in-user show --query id -o tsv) \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope $(az storage account show --name $STORAGE --resource-group $RG --query id -o tsv)

# The role can take 1–2 minutes to take effect
sleep 60
```

## Step 3. Upload a blob

```bash
az storage container create --name docs

echo "Hello Azure Storage!" > hello.txt
az storage blob upload --container-name docs --name hello.txt --file hello.txt

az storage blob list --container-name docs --query "[].{Name:name, Size:properties.contentLength}" -o table
```

## Step 4. Private by default — verify

Try to reach the file without credentials.

```bash
curl -i https://$STORAGE.blob.core.windows.net/docs/hello.txt
```

An **error** such as `409 PublicAccessNotPermitted`, `403` or `404` is the expected result. The file is safely private.

## Step 5. Share temporarily with a SAS token

Create a 10-minute, read-only link.

```bash
EXPIRY=$(date -u -d "+10 minutes" '+%Y-%m-%dT%H:%MZ')
URL=$(az storage blob generate-sas \
  --container-name docs --name hello.txt \
  --permissions r --expiry $EXPIRY --https-only --full-uri --as-user -o tsv)

curl "$URL"
```

`Hello Azure Storage!` means it worked. After 10 minutes the same link stops working.

## Step 6. Host a static website

```bash
# Enable the feature
az storage blob service-properties update \
  --static-website \
  --index-document index.html \
  --404-document 404.html

# Upload labs/02-storage/web to the $web container (run from the repo root)
az storage blob upload-batch --source labs/02-storage/web --destination '$web' --overwrite

# The website URL
az storage account show --name $STORAGE --resource-group $RG --query "primaryEndpoints.web" -o tsv
```

`Ctrl+click` the URL in the terminal (or paste it into a browser). 🎉

Also open a non-existent path (e.g. `/nothing`) to see `404.html`.

> 💡 The static website (`$web`) works even though anonymous access is blocked at the account level; regular blob containers stay private.

## Step 7. Clean up

```bash
az group delete --name $RG --yes --no-wait
rm -f hello.txt
```

## ✅ Checkpoint

- [ ] Anonymous access was rejected in Step 4.
- [ ] The SAS link returned the file contents in Step 5.
- [ ] The website URL showed the "Hello, Azure!" page in Step 6.

## 🛠️ Troubleshooting

| Symptom | Fix |
|---|---|
| `StorageAccountAlreadyTaken` | Name collision. Append digits: `STORAGE=stazlab$SUFFIX$RANDOM`. |
| `date: invalid date` | You're on macOS locally. Run in Codespaces (Linux). |
| `AuthorizationPermissionMismatch` on upload | Make sure you granted the role in Step 2, then wait another 1–2 minutes. |
| `AuthorizationFailure` / "network rules" message on upload | Re-run the Step 1 variables (`AZURE_STORAGE_AUTH_MODE=login`). If it persists, see the policy row below. |
| `publicNetworkAccess` is `Disabled` and reverts when you change it (`az storage account show ... --query publicNetworkAccess`) | An organization/tenant policy forces storage public access off. Steps 5–6 (SAS, static website) can't be reached from the internet then. Use a personal free subscription without such policy, or ask your admin for an exception. |
| Website returns 403/404 | Make sure `--static-website` ran and files are in `$web`: `az storage blob list -c '$web' -o table`. |

⬅️ Previous: [Lab 1](../01-setup/README.en.md) · ➡️ Next: [Lab 3. VNet and NSG](../03-network/README.en.md)
