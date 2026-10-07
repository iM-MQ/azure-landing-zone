# Azure Landing Zone Labs

Hands-on labs building an **Azure landing zone** with **Terraform**: the management group hierarchy, governance with Azure Policy, hub-and-spoke networking, and central management and monitoring. Each lab is written up with the commands I ran, what I saw and the problems I hit along the way.

These labs follow on from my [Terraform Azure Labs](https://github.com/iM-MQ/terraform-azure-labs) and [Kubernetes Labs](https://github.com/iM-MQ/kubernetes-labs). Those built individual workloads; this project builds the platform that workloads run inside.

**Requires:** an Azure subscription, permission to create management groups in your tenant, Terraform and the Azure CLI. See [Prerequisites](#prerequisites).

| Lab | Topic | Status |
|---|---|---|
| [01](lab-01-management-groups) | The management group hierarchy, in the Cloud Adoption Framework layout, with drift and deletion tests | Complete ✅ |
| 02 | Azure Policy guardrails: allowed regions, required tags and blocked resources, assigned at management group level | Planned ⏳ |
| 03 | Hub-and-spoke networking: a hub VNet, spoke VNets, peering and network security groups | Planned ⏳ |
| 04 | Platform management: central logging, activity logs, budgets and role assignments at scope | Planned ⏳ |

## What is a landing zone?

A **landing zone** is the prepared environment that an organisation's applications are deployed into. Instead of every team building its own subscription from scratch, a central platform team sets up the structure, the rules and the shared services once, and every new workload "lands" in a place that is already governed, connected and monitored.

Microsoft's guidance for this is the **Cloud Adoption Framework (CAF)**, and these labs follow its reference design.

```
Without a landing zone            With a landing zone
──────────────────────            ───────────────────
Each team builds its own          One platform, built once
Rules applied by hand, or not     Rules inherited automatically
Networks joined ad hoc            Hub-and-spoke by design
Logs scattered everywhere         Central logging from day one
```

### Key terms

| Term | Meaning |
|---|---|
| **Tenant** | An organisation's Microsoft Entra directory. Every Azure subscription belongs to one |
| **Management group** | A container above subscriptions. Anything assigned to it is inherited by everything beneath |
| **Tenant Root Group** | The top management group, created automatically for every tenant |
| **Azure Policy** | Rules that Azure enforces, such as "only these regions" or "every resource must have a cost-centre tag" |
| **Hub-and-spoke** | A network design with one central hub for shared services and separate spokes for each workload |
| **Platform team** | The central team that builds and runs the landing zone for everyone else |

### Why organisations use one

| Benefit | What it means in practice |
|---|---|
| **Governance by default** | Policies assigned once at the top apply to every current and future subscription |
| **Security** | Guardrails such as blocked public IPs or required encryption can't be skipped by individual teams |
| **Consistency** | Every workload gets the same networking, logging and access model |
| **Speed** | New projects get a ready-made, compliant subscription instead of starting from nothing |
| **Cost control** | Tags, budgets and region rules make spending visible and predictable |

### Working with one subscription

In a real organisation, the platform and each application team have their own subscriptions in different parts of the hierarchy. I have a single free trial subscription, so it plays the role of one application team's subscription in **Corp**, and everything is built inside it. The hierarchy, policies and inheritance behave exactly as they would at full scale.

## Practices followed

- Everything is built with Terraform and reviewed with `terraform plan` before `apply`
- Subscription and tenant IDs are never written in code; Terraform reads them from the signed-in session
- Terraform state is kept in Azure Storage, never in the repository (see `.gitignore`)
- Every commit is scanned for subscription IDs, tenant IDs and personal details before it is pushed
- The account that manages Azure uses multi-factor authentication

## Prerequisites

| Requirement | Version used | Purpose | Install (Windows) |
|---|---|---|---|
| Azure subscription | Free trial | Where the resources are deployed | [azure.microsoft.com/free](https://azure.microsoft.com/free) |
| Tenant permissions | Owner of the subscription, able to create management groups | Management groups are created at tenant level | Your own tenant, or ask your administrator |
| Terraform | 1.16.x (1.9 or later required) | Builds the landing zone from code | `winget install --id Hashicorp.Terraform -e` |
| Azure CLI | 2.x | Signs Terraform in to Azure | `winget install --id Microsoft.AzureCLI -e` |
| Git | 2.x | Clones this repository | `winget install --id Git.Git -e` |
| VS Code + HashiCorp Terraform extension | Latest (optional) | Editing with syntax highlighting and validation | `winget install --id Microsoft.VisualStudioCode -e` |

### Check everything is installed

```powershell
terraform -version
```

```powershell
az version
```

```powershell
git --version
```

## First-time setup

**1. Sign in to Azure, with MFA**

Sign in to your directory directly, so the MFA prompt can appear:

```powershell
az login --tenant <your-tenant-id>
```

**2. Tell Terraform which subscription to use** (needed in each new terminal session)

```powershell
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
```

This keeps the subscription ID out of the code and out of source control.

**3. Create the state storage**

Terraform state for every lab is kept in Azure Storage, created with the bootstrap code from my [Terraform Lab 04](https://github.com/iM-MQ/terraform-azure-labs/tree/main/lab-04-remote-state). Put the storage account name it outputs into each lab's `backend.tf`.

## Cost

Management groups and Azure Policy are free. Lab 03's networking is free while no traffic flows, and Lab 04's logging costs very little at lab scale. The state storage account costs pennies while it exists. Everything is removed with `terraform destroy` at the end of the project.