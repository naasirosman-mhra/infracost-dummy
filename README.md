# Infracost POC — Summary

## What is Infracost?

Infracost is an open-source tool that reads Terraform HCL and produces a cloud cost estimate before any infrastructure is provisioned.

This POC demonstrates the full workflow on a dummy Azure Terraform project:

- **Baseline cost**: generated automatically on every merge to `main`
- **Cost diff**: posted as a PR comment showing exactly how much a proposed change will increase or decrease the monthly bill

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
1. Checks out the base branch (`main`) into a git worktree at `/tmp/base`
2. Generates a baseline JSON from `main`: `infracost breakdown --path /tmp/base`
3. Generates a diff JSON from the PR branch: `infracost diff --path . --compare-to /tmp/infracost-base.json`
4. Posts the diff as a comment on the PR and uploads to Infracost Cloud
5. **Fails the CI check** if any Infracost Cloud guardrails or policies are violated

For the `feature/bigger-vm` PR the log shows: cost increased by **+$2,322/month (+522%)**, which exceeded the $250 guardrail threshold — causing the workflow to exit with code 1 and the PR to be marked **Blocked**.

---

## Infracost Cloud dashboard

Infracost Cloud at [app.infracost.io](https://app.infracost.io) provides a centralised view across all branches and PRs.

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

### PR detail view
Drilling into the PR shows:

**Failing policies (7 issues)**
- SQL — consider using Azure Hybrid Benefit for SQL Server
- Database — consider removing geo-redundant backups in non-production projects
- FinOps tags — 5 resources missing required tags

**Guardrails**
- Significant cost increase: please review *(blocking)* — cost increased by $2,322, threshold was $250

**Cost estimate**
- +$2,322/month cost increase (+522%) compared to `main`

The PR is shown as **Blocked** in Infracost Cloud, mirroring the failed GitHub Actions check. The PR can be unblocked manually by an approver in Infracost Cloud once reviewed.

![Infracost Cloud — PR detail showing blocked status, failing policies, and guardrail](image-2.png)

---

## Pricing

The **Infracost CLI**, **GitHub Action**, and self-hosted use are free and open source (MIT licence). **Infracost Cloud** — the SaaS dashboard, team policies, PR comments at scale, and budget guardrails — is a paid product priced per seat based on unique PR authors per month. See [infracost.io/pricing](https://infracost.io/pricing) for current figures.

---

## Next steps

- **Enable Infracost Cloud features**: connect the repo in the dashboard to unlock org-wide cost visibility and trend charts.
- **Add tagging policies**: fail the workflow if resources are missing required tags (e.g. `Owner`, `CostCentre`).
- **Set budget guardrails**: block merges that exceed a defined cost increase percentage.
- **Gate PRs on cost thresholds**: use `infracost diff` exit codes in branch protection rules so large cost increases require manual approval.