# Infracost POC — Summary

## What is Infracost?

Infracost is an open-source tool that reads Terraform HCL and produces a cloud cost estimate before any infrastructure is provisioned.

This POC shows the full workflow on a dummy Azure Terraform project:

- **Baseline cost**: generated automatically on every merge to `main`
- **Cost diff**: posted as a PR comment showing exactly how much a proposed change will increase or decrease the monthly bill
- **Guardrails**: block or warn on PRs that exceed a defined cost increase threshold (e.g. cost increased by $2,322 — threshold was $250)
- **FinOps policies**: enforce cloud best practices such as using Azure Hybrid Benefit for SQL Server, adding lifecycle policies to blob storage, and removing geo-redundant backups in non-production environments
- **Other policies**: fail the workflow if resources are missing required FinOps tags (e.g. `Owner`, `CostCentre`, `Environment`)
- **PR governance**: each PR is scored for policy violations and cost impact, giving reviewers a clear signal before merging

All prices are public list prices from the Infracost Cloud Pricing API. Organisations with Enterprise Agreement or CSP rates will see different actual charges.

---

## How it works

1. `infracost/actions/setup` installs the Infracost CLI and authenticates it using only the `INFRACOST_API_KEY` secret.
2. `infracost breakdown` (or `infracost diff`) parses Terraform HCL in the runner's workspace — **no Terraform plan, no Azure credentials, no `terraform init` against a real backend**.
3. The CLI sends resource metadata (SKU names, regions, sizes) to the Infracost Cloud Pricing API and receives monthly price estimates.
4. Results are rendered in the Actions log, uploaded to Infracost Cloud, and (on PRs) posted as a PR comment.

---

## GitHub Actions workflows

| Workflow | File | Trigger |
|----------|------|---------|
| Infracost Baseline | [infracost-baseline.yml](.github/workflows/infracost-baseline.yml) | Push to `main` on `.tf`/`.tfvars` files |
| Infracost PR Cost Diff | [infracost-pr.yml](.github/workflows/infracost-pr.yml) | Pull request targeting `main` |

### Baseline workflow log
When code merges to `main`, the [baseline workflow](https://github.com/naasirosman-mhra/infracost-dummy/actions/workflows/infracost-baseline.yml) runs `infracost breakdown` and prints a full cost table to the Actions log. The JSON output is uploaded as a workflow artifact and to Infracost Cloud. For this repo, the `main` baseline is **$445/month**.

### PR workflow log
When a PR is opened, the [PR workflow](https://github.com/naasirosman-mhra/infracost-dummy/actions/workflows/infracost-pr.yml) runs these steps:
1. Generates a baseline JSON from `main`
2. Generates a diff JSON from the PR branch
3. Posts the diff as a comment on the PR and uploads to Infracost Cloud
4. **Fails the CI check** if any Infracost Cloud guardrails or policies are violated


https://github.com/naasirosman-mhra/infracost-dummy/actions/runs/24565417869
For the `feature/bigger-vm` PR the log shows: cost increased by **+$2,322/month (+522%)**, which exceeded the $250 guardrail threshold — causing the workflow to exit with code 1 and the PR to be marked **Blocked**.

---

## Infracost Cloud dashboard

Infracost Cloud provides a centralised view across all branches and PRs.

### Branches tab
Shows the latest cost estimate per branch. For `main`:
- **$445/month** baseline cost
- **12 failing policies** detected on the baseline infrastructure, including:
  - Database: consider removing geo-redundant backups in non-production projects
  - SQL: consider using Azure Hybrid Benefit for SQL Server
  - Storage Accounts: consider using a lifecycle policy for blob storage
  - FinOps tags: 9 resources missing required tags

![Infracost Cloud — Branches tab showing $445/month baseline and 12 failing policies](image.png)

### Pull requests tab
Lists all open PRs with their cost impact at a glance:

| PR | Cost change | Governance |
|----|------------|-----------|
| Feature/bigger vm #1 | **+$2,322 (+522%)** | 7 issues, 1 cost guardrail |

![Infracost Cloud — Pull requests tab showing +$2,322 cost increase](image-1.png)

The PR is shown as **Blocked** in Infracost Cloud, mirroring the failed GitHub Actions check. The PR can be unblocked manually by an approver in Infracost Cloud once reviewed.

![Infracost Cloud — PR detail showing blocked status, failing policies, and guardrail](image-2.png)

---

## Pricing

| Tier | Hosted by | What you get | Cost |
|------|-----------|-------------|------|
| **CLI + GitHub Action** | Your CI runner | Cost breakdown, diff, PR comments | Free, open source |
| **Infracost Cloud SaaS** | Infracost (app.infracost.io) | Dashboard, guardrails, FinOps policies, tagging policies, PR governance | Paid, per seat |
| **Infracost Cloud self-hosted** | You, on your own infrastructure | Same as SaaS but data stays in your environment | Paid, enterprise licence |

Both cloud options are paid regardless of who hosts it — the self-hosted option is not a free alternative. Pricing is per unique PR author per month. See [infracost.io/pricing](https://infracost.io/pricing) for current figures.

> **Verdict**: At the scale of most teams, the Cloud tier likely runs into the thousands of pounds/dollars per year and is probably not worth it. The majority of features — guardrails, tagging policies, FinOps best practice checks, and PR comments — can be replicated for free using the Infracost CLI, [Checkov](https://www.checkov.io/) (open source static analysis), and a small `jq` script in the workflow to enforce cost thresholds.

| Feature | Infracost Cloud | Free alternative | Effort |
|---------|----------------|-----------------|--------|
| Cost breakdown in CI log | Yes | Infracost CLI (`infracost breakdown`) | None — already in this repo |
| PR cost diff comment | Yes | Infracost CLI (`infracost comment github`) | None — already in this repo |
| Guardrails (block PR on cost spike) | Yes | Infracost CLI JSON output + `jq` threshold check in workflow | Low — ~5 lines of bash |
| FinOps policies (Hybrid Benefit, lifecycle, backups) | Yes | [Checkov](https://www.checkov.io/) — has built-in Azure rules | Low — add one workflow step |
| Tagging policies | Yes | Checkov tag-checking rules or OPA/Conftest | Low — add one workflow step |
| PR governance dashboard | Yes | No direct equivalent | High — build your own or use GitHub Actions summary |
| Cross-repo cost visibility | Yes | No direct equivalent | High — would need custom tooling |

![alt text](image-3.png)

---
