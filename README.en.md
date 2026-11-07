# ☁️ Azure Basic Lab — Hands-on Azure for Beginners

[한국어](./README.md) | **English**

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/Taeyangmoon/azure-basic-lab)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

**Five beginner labs** for people new to Azure. Everything runs in your browser with **GitHub Codespaces**, with nothing to install locally.

## 📋 Curriculum

| # | Lab | You'll learn | Time |
|---|---|---|---|
| 1 | [Prepare your environment](./labs/01-setup/README.en.md) | Codespaces, `az login --use-device-code`, create/delete resource groups | 15 min |
| 2 | [Azure Storage](./labs/02-storage/README.en.md) | Create/inspect/delete a storage account, regions and LRS | 10 min |
| 3 | [VNet and NSG](./labs/03-network/README.en.md) | Address spaces, subnets, security rules | 20 min |
| 4 | [Virtual Machines](./labs/04-vm/README.en.md) | Linux VM, auto-install a web server with cloud-init | 25 min |
| 5 | [Bicep basics](./labs/05-bicep/README.en.md) | Recreate Labs 3–4 as code (IaC), what-if | 25 min |

> Follow them in order. Lab 4 builds on the network created in Lab 3.

## 🧰 Prerequisites

- A GitHub account
- An Azure subscription (a [free account](https://azure.microsoft.com/free/) is enough)

Azure CLI and Bicep come pre-installed in the Codespaces environment ([`.devcontainer`](./.devcontainer/devcontainer.json)).

## 🚀 Getting started

1. Click **Open in GitHub Codespaces** above (or **Code → Codespaces → Create codespace on main**).
2. When the environment is ready, start with [Lab 1](./labs/01-setup/README.en.md) in the terminal.

> If you forked this repo, replace `Taeyangmoon/azure-basic-lab` in the Codespaces badge with your own repository path.

## 💰 Cost warning

- Creating and inspecting resources in Labs 1–3 is free. Labs 4–5 incur charges for VM runtime, disks and public IPs.
- **Delete the resource group** after Labs 1, 2, 4 and 5. Keep Lab 3's group for Lab 4.
- A bulk cleanup script in case you forget:

```bash
./scripts/cleanup-all.sh   # deletes every rg-azlab-* group
```

- Setting a budget alert in [Azure Portal → Cost Management](https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview) adds extra safety.

## 🗂️ Repository layout

```
.
├── .devcontainer/        # Codespaces environment (Azure CLI + Bicep)
├── labs/
│   ├── 01-setup/         # Lab docs (README.md = Korean, README.en.md = English)
│   ├── 02-storage/       # Storage accounts, regions and LRS
│   ├── 03-network/
│   ├── 04-vm/cloud-init.yaml
│   └── 05-bicep/main.bicep
├── scripts/cleanup-all.sh
└── LICENSE
```

## 📏 Conventions

- Resource groups are named `rg-azlab-*`; the default region is `koreacentral`.
- Commands assume you run them from the **repository root**.
- Variables are lost when you open a new terminal, so re-run the variable block at the start of each lab.

## 🤝 Contributing

Typo fixes and suggestions are welcome via Issues/PRs.

## 📄 License

[MIT License](./LICENSE)
