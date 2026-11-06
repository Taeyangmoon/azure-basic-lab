# Lab 5. Bicep Basics — Recreate Labs 3 and 4 as Code

⏱️ ~25 min · 💰 Billed while the VM runs (delete when done!)

## 🎯 Goals

- Reproduce what you did with the CLI in Labs 3 and 4 using **one Bicep file**.
- Preview changes before deploying with `what-if`.
- Confirm that **deploying the same file repeatedly is safe** (idempotency).

## 📚 Key concepts

| Term | In plain words |
|---|---|
| **IaC (Infrastructure as Code)** | Define infrastructure as **code** so it is repeatable and reviewable. |
| **Bicep** | Azure's IaC language, far more readable than ARM JSON templates. |
| **Declarative** | You describe the desired end state, not the steps. Azure makes it so. |
| **Idempotent** | Deploying the same code many times gives the same result. |
| **what-if** | Shows what would be created/changed/deleted without deploying. |

### CLI vs Bicep

| | CLI (Labs 3–4) | Bicep (Lab 5) |
|---|---|---|
| Style | Run commands **in order** | **Declare** the desired state |
| Commands | ~20 | 1 deploy command |
| Re-run | May error or duplicate | Safe to re-run |
| Review/share | Terminal history only | Code review + Git history |
| Preview | None | `what-if` |

## Step 1. Variables and SSH key

```bash
RG=rg-azlab-bicep
LOCATION=koreacentral

# Create an SSH key if you don't have one
[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa

MY_IP=$(curl -s https://api.ipify.org)
echo $MY_IP

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

## Step 2. Read the Bicep file

Open [`main.bicep`](./main.bicep). The VS Code Bicep extension gives you highlighting and completion.

Match the CLI commands to the code:

| CLI in Labs 3–4 | Resource in `main.bicep` |
|---|---|
| `az network nsg create` + `rule create` | `resource nsgWeb`, `resource nsgDb` |
| `az network vnet create` + `subnet create` | `resource vnet` (subnets array) |
| `--network-security-group nsg-web` | `networkSecurityGroup: { id: nsgWeb.id }` |
| Public IP auto-created by `az vm create` | `resource pip` |
| NIC auto-created by `az vm create` | `resource nic` |
| `az vm create --custom-data` | `customData: loadFileAsBase64(...)` |
| `az vm create` | `resource vm` |

Things to notice:

- When you **reference** another resource, e.g. `nsgWeb.id`, Bicep works out the creation **order automatically**. (With the CLI you had to get the order right yourself.)
- `param` lets you change values from outside (VM size, SSH IP, …).

## Step 3. Validate the syntax

```bash
az bicep install   # already installed in Codespaces; safe to skip
az bicep build --file labs/05-bicep/main.bicep --stdout > /dev/null && echo "✅ Syntax OK"
```

## Step 4. Preview with what-if

```bash
az deployment group what-if \
  --resource-group $RG \
  --template-file labs/05-bicep/main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)" sshSourceCidr="$MY_IP/32"
```

Green `+ Create` lines show 6 resources about to be created (2 NSGs, VNet, public IP, NIC, VM). **Nothing has been created yet.**

## Step 5. Deploy

```bash
az deployment group create \
  --resource-group $RG \
  --template-file labs/05-bicep/main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)" sshSourceCidr="$MY_IP/32" \
  --query properties.outputs -o jsonc
```

After a few minutes the output includes `publicIp` and `webUrl`.

## Step 6. Verify

Wait for cloud-init to finish, then connect.

```bash
az vm run-command invoke -g $RG -n vm-web01 --command-id RunShellScript \
  --scripts "cloud-init status --wait" --query "value[0].message" -o tsv

IP=$(az deployment group show -g $RG -n main --query properties.outputs.publicIp.value -o tsv)
curl http://$IP
```

You get the **same web page** as in Lab 4: ~20 commands replaced by one file. 🎉

```bash
az resource list -g $RG -o table
```

## Step 7. Idempotency and change detection

Run what-if on the **same file** again.

```bash
az deployment group what-if -g $RG --template-file labs/05-bicep/main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)" sshSourceCidr="$MY_IP/32"
```

It reports no changes. Now edit `main.bicep`: change the `Allow-HTTP` rule's `destinationPortRange: '80'` to `'8080'` and run what-if again. **Only that part** shows up as `~ Modify`.

Revert it to `'80'` afterwards.

> 💡 That's the value of IaC: infrastructure changes go through **code review (PRs)**, you **preview the impact** before applying, and you can **recreate the same environment** any time.

## Step 8. Clean up

```bash
az group delete --name $RG --yes --no-wait
```

If you haven't yet deleted the Lab 3–4 group (`rg-azlab-net`), remove everything at once:

```bash
./scripts/cleanup-all.sh
```

## ✅ Checkpoint

- [ ] You previewed changes with `what-if` before deploying.
- [ ] The deployment served the same web page as Lab 4.
- [ ] Re-running what-if on the same template showed no changes.
- [ ] All `rg-azlab-*` groups are deleted. (`az group list -o table`)

## 🛠️ Troubleshooting

| Symptom | Fix |
|---|---|
| `SkuNotAvailable` | Pass another size, e.g. `--parameters vmSize=Standard_B2s` (see [Lab 4](../04-vm/README.en.md) for listing sizes). |
| `InvalidTemplateDeployment` with an SSH key error | Make sure `cat ~/.ssh/id_rsa.pub` is a single line starting with `ssh-rsa`. |
| `curl` fails | Do the cloud-init wait (Step 6) first. |

## 🎓 Congratulations!

You've completed all five basic labs. Next, explore App Service, Azure SQL, Key Vault, containers (ACA/AKS), and monitoring.

⬅️ Previous: [Lab 4](../04-vm/README.en.md) · 🏠 [Home](../../README.en.md)
