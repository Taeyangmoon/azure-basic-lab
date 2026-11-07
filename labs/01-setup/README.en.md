# Lab 1. Prepare Your Environment

⏱️ ~15 min · 💰 Free

## 🎯 Goals

- Use Azure CLI in GitHub Codespaces.
- Sign in with `az login --use-device-code`.
- Create, list, and delete a **resource group**.

## 📚 Key concepts

| Term | In plain words |
|---|---|
| **Subscription** | The "billing account" Azure charges usage to. |
| **Resource** | Anything you create in Azure: a VM, storage, a network… |
| **Resource group** | A **folder** that holds resources. Delete the folder and everything inside goes away. |
| **Region** | The geography of the datacenter. This lab uses `koreacentral`. |
| **Azure CLI (`az`)** | The command-line tool to manage Azure from a terminal. |

> 💡 **The golden habit**: create a separate resource group per lab and **delete the whole group** when you finish. It is the surest way to avoid surprise bills.

## Prerequisites

- A GitHub account
- An Azure subscription ([create a free account](https://azure.microsoft.com/free/))

## Step 1. Open Codespaces

1. On this repository's main page click **Code → Codespaces → Create codespace on main**.
2. Wait 1–2 minutes; VS Code opens in your browser (Azure CLI and Bicep are pre-installed).
3. Open a terminal (`` Ctrl+` ``) and check:

```bash
az version
```

## Step 2. Sign in to Azure

Codespaces runs in a browser, so use the **device code flow**.

```bash
az login --use-device-code
```

1. The terminal shows `https://microsoft.com/devicelogin` and a **code**.
2. Open the link, enter the code, and sign in with your Azure account.
3. When the terminal prints your subscriptions, you're in.

## Step 3. Check your subscription

```bash
# Current subscription
az account show --query "{Name:name, Id:id, State:state}" -o table

# All subscriptions
az account list --query "[].{Name:name, Id:id, IsDefault:isDefault}" -o table
```

To switch:

```bash
az account set --subscription "<name or ID>"
```

## Step 4. Register resource providers (first time only)

On a new subscription some services aren't registered yet and can fail. Register the ones this lab uses.

```bash
for ns in Microsoft.Storage Microsoft.Network Microsoft.Compute; do
  az provider register --namespace $ns
done

# It can take a few minutes to reach "Registered"
az provider list --query "[?namespace=='Microsoft.Storage' || namespace=='Microsoft.Network' || namespace=='Microsoft.Compute'].{Namespace:namespace, State:registrationState}" -o table
```

## Step 5. Create a resource group

```bash
RG=rg-azlab-hello
LOCATION=koreacentral

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

> 💡 Naming: every resource group in this lab starts with `rg-azlab-`, so you can find and delete them all at once later.

## Step 6. Inspect it

```bash
# My lab resource groups
az group list --query "[?starts_with(name,'rg-azlab-')].{Name:name, Location:location, State:properties.provisioningState}" -o table

# Details of one
az group show --name $RG -o jsonc

# Resources inside (empty for now)
az resource list --resource-group $RG -o table
```

🌐 Confirm the same group shows up in the [Azure Portal](https://portal.azure.com) → **Resource groups**.

## Step 7. Delete it

```bash
az group delete --name $RG --yes

# Confirm (false = deleted)
az group exists --name $RG
```

- `--yes`: skip the confirmation prompt
- The command waits for deletion to finish, which can take a few minutes.

## ✅ Checkpoint

- [ ] `az account show` shows your subscription.
- [ ] The group you created was visible in the Portal.
- [ ] `az group exists` returns `false`.

## 🛠️ Troubleshooting

| Symptom | Fix |
|---|---|
| No subscription after login | Check in the Portal that your free subscription is active. |
| `AuthorizationFailed` | You need at least **Contributor** on the subscription. |
| `MissingSubscriptionRegistration` | Re-run Step 4 and wait a bit. |
| Token expired | Run `az login --use-device-code` again. |

➡️ Next: [Lab 2. Azure Storage](../02-storage/README.en.md)
