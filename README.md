# Infracost POC — Summary

## What is Infracost?

Infracost is an open-source tool that reads Terraform HCL and produces a cloud cost estimate before any infrastructure is provisioned. This POC demonstrates the full workflow on a dummy Azure Terraform project: a baseline cost estimate is generated automatically every time Terraform files are merged to `main`, and a cost *diff* comment is posted to every pull request so engineers can see exactly how much a proposed change will increase or decrease the monthly bill — without ever running `terraform apply` or holding Azure credentials. All prices shown are public list prices from the Infracost Cloud Pricing API; organisations with Enterprise Agreement or CSP rates will see different actual charges.

---

## How it works

1. A GitHub Actions runner checks out the repository.
2. The `infracost/actions/setup` action installs the Infracost CLI and authenticates it with the Infracost Cloud Pricing API using only the `INFRACOST_API_KEY` secret.
3. `infracost breakdown` (or `infracost diff`) parses the Terraform HCL files in the runner's workspace — **no Terraform plan, no Azure credentials, no `terraform init` against a real backend**.
4. The CLI sends resource metadata (SKU names, regions, sizes) to the Infracost Cloud Pricing API and receives monthly price estimates in return.
5. Results are rendered as a table in the Actions log, uploaded to Infracost Cloud for the dashboard, and (on PRs) posted as a comment on the pull request.

---

## Demo script

### 1 — Watch the baseline workflow on `main`
- The push to `main` triggers **Infracost Baseline** (`.github/workflows/infracost-baseline.yml`).
- Open **Actions → Infracost Baseline → latest run** and expand the *Print cost breakdown table* step to see the full monthly cost table.
- The run is also uploaded to **Infracost Cloud** — open [app.infracost.io](https://app.infracost.io) to see the dashboard for this repo.

### 2 — Open a PR from `feature/bigger-vm` → `main`
- The PR contains: VM upsized D4s_v5 → D16s_v5, managed disk grown 512 GB → 2,048 GB, a second D16s_v5 worker VM added, and the SQL database upgraded S3 → P2.

### 3 — View the Infracost PR comment
- The **Infracost PR Cost Diff** workflow (`.github/workflows/infracost-pr.yml`) runs automatically.
- Within ~60 seconds a comment appears on the PR showing the baseline vs new monthly cost and a `+` / `-` diff per resource line.
- The diff is also visible in Infracost Cloud under the PR's entry.

---

## Pricing

The **Infracost CLI**, **GitHub Action**, and **self-hosted** use are free and open source (MIT licence). **Infracost Cloud** — the SaaS dashboard, team policies, PR comments at scale, and budget guardrails — is a paid product priced per seat, based on unique PR authors per month. Current pricing is published at [infracost.io/pricing](https://infracost.io/pricing); do not rely on any figures in this document as they may have changed.

---

## Next steps

- **Enable Infracost Cloud features**: connect the repo in the Infracost Cloud dashboard to unlock org-wide cost visibility, pull-request history, and trend charts.
- **Add tagging policies**: configure Infracost to fail the workflow if resources are missing required tags (e.g. `Owner`, `CostCentre`).
- **Set budget guardrails**: use `infracost comment` with `--threshold` flags or Infracost Cloud policies to block merges that exceed a defined cost increase percentage.
- **Gate PRs on cost thresholds**: integrate `infracost diff` exit codes into branch protection rules so that PRs with a cost increase above a set limit require manual approval.
