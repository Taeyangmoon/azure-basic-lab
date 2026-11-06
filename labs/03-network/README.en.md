# Lab 3. Virtual Network and Network Security Groups (NSG)

⏱️ ~20 min · 💰 Free (VNets and NSGs themselves cost nothing)

## 🎯 Goals

- Create a VNet with **subnets** and understand **address spaces**.
- Allow/deny traffic with **NSG rules**.
- Attach NSGs to subnets so the web and DB subnets are protected differently.

## 📚 Key concepts

Analogy: a VNet is an **apartment complex**, a subnet is a **building**, an NSG is the **security guard at the building entrance**.

| Term | In plain words |
|---|---|
| **VNet** | Your own private network inside Azure. |
| **Address space** | The IP range the VNet can use, e.g. `10.0.0.0/16` (~65,000 addresses). |
| **Subnet** | A slice of the address space, e.g. `10.0.1.0/24` (~250 addresses). |
| **NSG** | A **set of firewall rules** attached to a subnet or NIC. |
| **Priority** | **Lower number = evaluated first.** The first matching rule wins. |

### What we'll build

```
vnet-azlab (10.0.0.0/16)
├── snet-web (10.0.1.0/24)  ← nsg-web : allow HTTP(80); SSH(22) only from my IP
└── snet-db  (10.0.2.0/24)  ← nsg-db  : allow 3306 only from snet-web
```

> 💡 NSGs come with default rules: inbound from the Internet is **denied** (`DenyAllInBound`), traffic inside the same VNet is **allowed** (`AllowVnetInBound`).

## Step 1. Variables and resource group

> This resource group is **reused in Lab 4**. Delete it after Lab 4.

```bash
RG=rg-azlab-net
LOCATION=koreacentral
VNET=vnet-azlab

az group create --name $RG --location $LOCATION --tags purpose=azlab
```

## Step 2. VNet and the web subnet

```bash
az network vnet create \
  --resource-group $RG \
  --name $VNET \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-web \
  --subnet-prefixes 10.0.1.0/24
```

## Step 3. Add the DB subnet

```bash
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET \
  --name snet-db \
  --address-prefixes 10.0.2.0/24

az network vnet subnet list --resource-group $RG --vnet-name $VNET \
  --query "[].{Name:name, Prefix:addressPrefix}" -o table
```

## Step 4. Create the web NSG

```bash
az network nsg create --resource-group $RG --name nsg-web

# HTTP from anywhere
az network nsg rule create \
  --resource-group $RG --nsg-name nsg-web --name Allow-HTTP \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes Internet --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 80

# SSH only from this Codespace's public IP
MY_IP=$(curl -s https://api.ipify.org)
echo $MY_IP

az network nsg rule create \
  --resource-group $RG --nsg-name nsg-web --name Allow-SSH-From-MyIP \
  --priority 110 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes $MY_IP/32 --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 22
```

> 💡 Opening SSH (22) to `*` invites login attempts from all over the world. Always open it **only to the IPs you need**.

## Step 5. Create the DB NSG

The DB subnet accepts **only port 3306 from the web subnet** and blocks other traffic from the VNet.

```bash
az network nsg create --resource-group $RG --name nsg-db

az network nsg rule create \
  --resource-group $RG --nsg-name nsg-db --name Allow-DB-From-Web \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes 10.0.1.0/24 --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 3306

# Priority 4000 is evaluated before the default AllowVnetInBound (65000)
az network nsg rule create \
  --resource-group $RG --nsg-name nsg-db --name Deny-Other-VNet-Inbound \
  --priority 4000 --direction Inbound --access Deny --protocol '*' \
  --source-address-prefixes VirtualNetwork --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges '*'
```

## Step 6. Attach NSGs to subnets

```bash
az network vnet subnet update --resource-group $RG --vnet-name $VNET \
  --name snet-web --network-security-group nsg-web

az network vnet subnet update --resource-group $RG --vnet-name $VNET \
  --name snet-db --network-security-group nsg-db
```

## Step 7. Review the rules

```bash
az network nsg rule list --resource-group $RG --nsg-name nsg-web --include-default \
  --query "[].{Priority:priority, Name:name, Direction:direction, Access:access, Port:destinationPortRange, Source:sourceAddressPrefix}" \
  -o table
```

At the bottom of the table find the **default rules** `65000` (AllowVnetInBound) and `65500` (DenyAllInBound).

🌐 You can see the same in Portal → `nsg-web` → **Inbound security rules**.

## ✅ Checkpoint

- [ ] Two subnets (`snet-web`, `snet-db`) exist.
- [ ] `nsg-web` has `Allow-HTTP` and `Allow-SSH-From-MyIP`.
- [ ] Both subnets have an NSG attached. (`az network vnet subnet show ... --query networkSecurityGroup.id`)

## 🧹 Clean up

**Don't delete yet.** Lab 4 attaches a VM to this VNet. Delete after Lab 4.

## 🛠️ Troubleshooting

| Symptom | Fix |
|---|---|
| `AddressSpaceOverlap` | A VNet with the same range already exists. Check names and groups. |
| `MY_IP` is empty | Network hiccup. Retry with `curl -s https://ifconfig.me`. |
| Variables gone after reopening the terminal | Re-enter the Step 1 variables (`RG`, `LOCATION`, `VNET`). |

⬅️ Previous: [Lab 2](../02-storage/README.en.md) · ➡️ Next: [Lab 4. Virtual Machines](../04-vm/README.en.md)
