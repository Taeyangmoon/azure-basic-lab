# Lab 4. Azure Virtual Machines — Auto-install a Web Server with cloud-init

⏱️ ~25 min · 💰 Billed while the VM runs (`Standard_B2ats_v2` is well under a few cents/hour, varies by region and time. Delete when done!)

## 🎯 Goals

- Create a Linux VM in Lab 3's VNet (`snet-web`).
- Auto-install nginx at first boot using **cloud-init**.
- Delete and restore an NSG rule to **see the firewall's effect first-hand**.

## 📚 Key concepts

| Term | In plain words |
|---|---|
| **IaaS** | You rent a server (VM) and manage everything from the OS up. |
| **VM size** | CPU/memory spec. `Standard_B2ats_v2` is a cheap 2 vCPU / 1 GB starter size (the older `B1s` is no longer offered in some regions). |
| **cloud-init** | A config file that installs packages and creates files automatically on first boot. |
| **Public IP** | The address used to reach the VM from the internet. |
| **SSH key** | A key pair used instead of a password: private key stays with you, public key goes on the VM. |
| **Deallocate** | Stops the VM and stops compute billing (disks are still billed). |

## Prerequisite

**Finish Lab 3** so `rg-azlab-net` contains `vnet-azlab` and `nsg-web`.

```bash
az network vnet list -g rg-azlab-net -o table
```

## Step 1. Variables

```bash
RG=rg-azlab-net
VNET=vnet-azlab
VM=vm-web01
LOCATION=koreacentral
```

## Step 2. Read the cloud-init file

Open [`cloud-init.yaml`](./cloud-init.yaml). It does three things:

1. `packages`: install nginx
2. `write_files`: create the landing page (`index.html`)
3. `runcmd`: put the hostname in the page and start nginx

## Step 3. Create the VM

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

- `--nsg ""`: don't create a NIC-level NSG; `nsg-web` on the subnet protects the VM.
- `--generate-ssh-keys`: creates `~/.ssh/id_rsa` if missing.
- Run from the repository root. Takes 1–3 minutes.

> ⚠️ If you get `SkuNotAvailable`, the size isn't available in that region. List available sizes and change `--size`:
> ```bash
> az vm list-skus -l koreacentral --resource-type virtualMachines --size Standard_B \
>   --query '[?length(restrictions)==`0`].name' -o tsv | sort -u
> ```

## Step 4. Wait for cloud-init

"VM created" is not the same as "web server installed". Wait for the install to finish.

```bash
az vm run-command invoke -g $RG -n $VM --command-id RunShellScript \
  --scripts "cloud-init status --wait" --query "value[0].message" -o tsv
```

`status: done` means it's finished.

## Step 5. Visit the web server

```bash
IP=$(az vm show -d -g $RG -n $VM --query publicIps -o tsv)
echo http://$IP

curl http://$IP
```

HTML output means success; you can also open `http://<IP>` in a browser. 🎉
It works thanks to the `Allow-HTTP` rule from Lab 3.

## Step 6. SSH in

In Lab 3 SSH (22) was opened only to **this Codespace's public IP**, so connect from the Codespace terminal.

```bash
ssh -o StrictHostKeyChecking=accept-new azureuser@$IP
```

Look around, then `exit`.

```bash
hostname
systemctl status nginx --no-pager | head -5
exit
```

> If it fails, the Codespace's public IP probably changed (e.g. after a restart). Update the IP in the `Allow-SSH-From-MyIP` rule:
> ```bash
> az network nsg rule update -g $RG --nsg-name nsg-web -n Allow-SSH-From-MyIP \
>   --source-address-prefixes $(curl -s https://api.ipify.org)/32
> ```

## Step 7. 🔬 See the NSG in action

**Delete** the HTTP allow rule.

```bash
az network nsg rule delete -g $RG --nsg-name nsg-web -n Allow-HTTP

# Takes a few seconds to apply
sleep 15
curl --max-time 5 http://$IP || echo "❌ Blocked (timeout)"
```

The server is running fine, but the firewall blocks you. Now **restore** the rule.

```bash
az network nsg rule create \
  --resource-group $RG --nsg-name nsg-web --name Allow-HTTP \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes Internet --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 80

sleep 15
curl --max-time 5 http://$IP | head -n 5
```

If it responds again, you're done.

## Step 8. Save money: stop and clean up

To take a break, **deallocate** to stop compute billing. (Shutting down from inside the OS keeps billing you.)

```bash
az vm deallocate -g $RG -n $VM    # stop
az vm start -g $RG -n $VM         # start again
```

When you're finished, **delete the resource group**.

```bash
az group delete --name $RG --yes --no-wait
```

> 💡 Lab 5 rebuilds the same setup with Bicep, so deleting now is recommended.

## ✅ Checkpoint

- [ ] `curl http://$IP` showed the "Hello from Azure VM!" page.
- [ ] Access was blocked after deleting `Allow-HTTP` and worked again after restoring it.
- [ ] You deleted the resource group.

## 🛠️ Troubleshooting

| Symptom | Fix |
|---|---|
| `curl` refused/timeout from the start | Did you wait for cloud-init (Step 4)? Does `nsg-web` have `Allow-HTTP` and is it attached to the subnet? |
| `ssh: Permission denied (publickey)` | Check `ls ~/.ssh/id_rsa*`. If you recreated the Codespace the key is gone; recreate the VM. |
| `ssh` times out | Run the SSH-rule IP update command in Step 6. If it still fails, behind a corporate network/VPN/proxy the IP Azure sees can differ from what `api.ipify.org` reports. Temporarily set the rule's source to `*`, connect, run `echo $SSH_CLIENT` on the VM to see the real IP, then restore the rule with that IP. |
| `cloud-init status` is `error` | On the VM: `sudo cat /var/log/cloud-init-output.log`. |
| `--custom-data` file not found | Run from the repo root (`pwd`). |

⬅️ Previous: [Lab 3](../03-network/README.en.md) · ➡️ Next: [Lab 5. Bicep Basics](../05-bicep/README.en.md)
