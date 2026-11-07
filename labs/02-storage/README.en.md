# Lab 2. Azure Storage — Create and Explore a Storage Account

⏱️ ~10 min · 💰 Creating and inspecting an account is free

## 🎯 Goals

- Create, inspect and delete a **storage account**.
- Understand the **region** where data lives and the **LRS** replication option.
- See an actual resource inside a resource group.

> This lab uses account management commands only, without uploading files or publishing a website. No additional data access roles or network configuration are needed.

## 📚 Key concepts

| Term | In plain words |
|---|---|
| **Storage account** | Azure's "cloud storage building" for files and data |
| **Blob** | A service for storing files such as images, documents and videos |
| **Container** | A folder for blobs (not the same as a Docker container!) |
| **Region** | Where the data is stored. This lab uses `koreacentral` (Korea Central). |
| **LRS** | Keeps 3 copies of your data inside one datacenter |
| **StorageV2** | A general-purpose account supporting blobs, files, queues and tables |

> 💡 LRS protects against hardware failures; it is not a backup that restores accidentally deleted files.

## Step 1. Variables and resource group

A storage account name must be **globally unique**, with 3–24 lowercase letters and digits. A stable suffix derived from your subscription ID gives the same name if you reopen the terminal.

```bash
RG=rg-azlab-storage
LOCATION=koreacentral
SUFFIX=$(az account show --query id -o tsv | md5sum | cut -c1-8)
STORAGE=stazlab$SUFFIX
echo $STORAGE

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

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

- `--location`: selects the region for your data.
- `--sku Standard_LRS`: selects standard performance and LRS replication.
- `--kind StorageV2`: creates a general-purpose storage account.
- `--allow-blob-public-access false`: prevents anonymous access to regular blobs.
- Creation can take 1–2 minutes. **You haven't stored any files yet.**

## Step 3. Explore the account

```bash
# Storage accounts in this resource group
az storage account list --resource-group $RG \
  --query "[].{Name:name, Location:location, Replication:sku.name}" -o table

# Inspect one account's settings
az storage account show --name $STORAGE --resource-group $RG \
  --query "{Name:name, Location:location, Kind:kind, Replication:sku.name, State:provisioningState}" \
  -o table
```

Check that `Location` is `koreacentral`, `Kind` is `StorageV2`, `Replication` is `Standard_LRS`, and `State` is `Succeeded`.

```bash
# Unlike the empty group in Lab 1, this group now contains a storage resource
az resource list --resource-group $RG \
  --query "[].{Name:name, Type:type, Location:location}" -o table
```

🌐 In the [Azure Portal](https://portal.azure.com), open **Resource groups** → `rg-azlab-storage` → the storage account's **Overview** to see its name and location.

## Step 4. Clean up

```bash
# Wait until deletion finishes
az group delete --name $RG --yes

# false means deletion is complete
az group exists --name $RG
```

The account and its resource group are deleted together. Remember that deleting an account with data in it **also deletes that data**.

## ✅ Checkpoint

- [ ] You created a storage account.
- [ ] You checked the region (`koreacentral`) and replication (`Standard_LRS`).
- [ ] You listed a `Microsoft.Storage/storageAccounts` resource inside the group.
- [ ] After cleanup, `az group exists` returns `false`.

## 🛠️ Troubleshooting

| Symptom | Fix |
|---|---|
| `StorageAccountAlreadyTaken` | The name is already in use. Set `STORAGE=stazlab$SUFFIX$RANDOM` and retry Step 2. Keep using this name in new terminals too. |
| `AuthorizationFailed` | Check the subscription selected in Lab 1 and your permission to create resources. |
| Variables gone after reopening the terminal | Re-run the Step 1 variable block. |

⬅️ Previous: [Lab 1](../01-setup/README.en.md) · ➡️ Next: [Lab 3. VNet and NSG](../03-network/README.en.md)
