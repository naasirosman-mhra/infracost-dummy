# Infracost POC — Dummy Azure Infrastructure

This repository is a **dummy Terraform project** created solely to demonstrate [Infracost](https://infracost.io) cost estimation on Azure infrastructure. No real resources are deployed; `terraform apply` is never run.

> **Warning:** If you were to run `terraform apply` against a real Azure subscription, the resources defined here would incur real charges. See the pricing breakdown in the CI workflow output for estimated costs.

## Resources

| File | Resource | Details |
|------|----------|---------|
| `compute.tf` | Linux Virtual Machine | Standard_D4s_v5 |
| `compute.tf` | Managed Disk | Premium LRS, 512 GB |
| `compute.tf` | Public IP | Standard, Static |
| `storage.tf` | Storage Account | Standard LRS, Hot tier |
| `storage.tf` | Storage Container | Private |
| `database.tf` | Azure SQL Server | SQL Server 12.0 |
| `database.tf` | Azure SQL Database | S3 tier, 250 GB |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `uksouth` | Azure region |
| `environment` | `dev` | Deployment environment |

## CI Setup

To run the Infracost workflows in your own GitHub repository:

1. **Push this repo** to a GitHub repository (e.g. `https://github.com/<your-org>/infracost-dummy`).

2. **Get a free Infracost API key** by signing up at [infracost.io](https://infracost.io). Copy the key from your dashboard.

3. **Add the secret** to your repo:
   - Go to **Settings → Secrets and variables → Actions**
   - Click **New repository secret**
   - Name: `INFRACOST_API_KEY`
   - Value: your key from step 2

4. **`GITHUB_TOKEN`** is provided automatically by GitHub Actions — no action needed.

5. **No Azure credentials are required.** Infracost parses Terraform HCL directly and calls its own Cloud Pricing API. It never talks to Azure.

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `infracost-baseline.yml` | Push to `main` (`.tf`/`.tfvars` files) or manual | Full cost breakdown table in Actions log + artifact |
| `infracost-pr.yml` | Pull request targeting `main` | Cost diff comment posted to the PR |
