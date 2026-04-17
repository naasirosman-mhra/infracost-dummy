# Infracost POC — Summary

## What is Infracost?

Infracost reads Terraform HCL and produces cloud cost estimates before any infrastructure is provisioned. no `terraform apply` or cloud credentials.

**Key features**

| Feature | What it does |
|---------|-------------|
| Baseline cost | Generated with CLI` |
| Cost diff | PR comment showing `+/-` per resource vs `main` |
| Guardrails | Blocks PRs that exceed a cost threshold (e.g. +$2,322 > $250 limit) |
| FinOps policies | Flags best practice violations — Hybrid Benefit, lifecycle policies, geo-redundant backups |
| Other policies | Fails CI if resources are missing required tags (`Owner`, `CostCentre`, `Environment`) |
| PR governance | Each PR scored for policy violations + cost impact before merge |

> Prices are public list prices from the Infracost Cloud Pricing API. Rates will differ. Enterprise more accurate

---

## How it works

1. `infracost/actions/setup` installs the CLI and authenticates with the Infracost Cloud Pricing API using only `INFRACOST_API_KEY`
2. `infracost breakdown` / `infracost diff` parses Terraform HCL — **no Terraform plan, no Azure credentials, no real backend**
3. CLI sends resource metadata (SKU, region, size) → receives monthly price estimates
4. Results → Actions log + Infracost Cloud dashboard + PR comment

---

## GitHub Actions workflows

| Workflow | File | Trigger |
|----------|------|---------|
| Infracost Baseline | [infracost-baseline.yml](.github/workflows/infracost-baseline.yml) | Merge to `main` |
| Infracost PR Cost Diff | [infracost-pr.yml](.github/workflows/infracost-pr.yml) | PR for `feature/` to `main` |

**Baseline** — runs `infracost breakdown`, prints cost table to Actions log, uploads artifact + to Infracost Cloud. This repo's `main` baseline = **$445/month**. [View runs →](https://github.com/naasirosman-mhra/infracost-dummy/actions/workflows/infracost-baseline.yml)

**PR diff** — [view runs →](https://github.com/naasirosman-mhra/infracost-dummy/actions/workflows/infracost-pr.yml)
1. Checks out `main` into `/tmp/base` → generates baseline JSON
2. Generates diff JSON from PR branch
3. Posts diff comment to PR + uploads to Infracost Cloud
4. **Fails CI** if any guardrail or policy is violated

`feature/bigger-vm` result: **+$2,322/month (+522%)** → exceeded $250 threshold → PR marked **Blocked**. [View run →](https://github.com/naasirosman-mhra/infracost-dummy/actions/runs/24565417869)

---

## Infracost Cloud dashboard

### Branches tab
`main` — **$445/month**, 12 failing policies:
![Infracost Cloud — Branches tab showing $445/month baseline and 12 failing policies](image.png)

### Pull requests tab
![Infracost Cloud — Pull requests tab showing +$2,322 cost increase](image-1.png)

---

## Pricing

| Tier | Hosted by | What you get | Cost |
|------|-----------|-------------|------|
| **CLI + GitHub Action** | Your CI runner | Cost breakdown, diff, PR comments | Free, open source |
| **Infracost Cloud SaaS** | Infracost (app.infracost.io) | Dashboard, guardrails, policies, PR governance | Paid, per seat |
| **Infracost Cloud self-hosted** | You | Same as SaaS, data stays in your environment | Paid, enterprise licence |

Both cloud options are paid — self-hosted is not a free alternative. Pricing = per unique PR author/month. See [infracost.io/pricing](https://infracost.io/pricing).

**Verdict**: Not worth it. Most features can be replicated free with the Infracost CLI + [Checkov](https://www.checkov.io/) + a small `jq` threshold script.

| Feature | Free alternative | Effort |
|---------|-----------------|--------|
| Cost breakdown in CI | Infracost CLI — `infracost breakdown` | None — already in this repo |
| PR cost diff comment | Infracost CLI — `infracost comment github` | None — already in this repo |
| Guardrails | CLI JSON output + `jq` threshold check | Low — ~5 lines of bash |
| FinOps policies | Checkov — built-in Azure rules | Low — one workflow step |
| Tagging policies | Checkov or OPA/Conftest | Low — one workflow step |
| PR governance dashboard | No direct equivalent | High |
| Cross-repo cost visibility | No direct equivalent | High |

![alt text](image-3.png)

---
