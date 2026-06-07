# Deploying lua-training slides

The slides site is built into a Docker image, pushed to Google Artifact
Registry, and served by Cloud Run. A push to `main` triggers
`.github/workflows/deploy.yml` which does the build → push → deploy.

The custom domain `https://lua.ristkari.dev/` points at the Cloud Run
service via a Cloudflare CNAME (DNS-only).

This file documents the **one-time setup** you do once per project, not what
runs on every push.

## Prerequisites

- `gcloud` CLI authenticated as an account with Owner (or sufficient roles) on
  the `ristkari-dev` project.
- `gh` CLI authenticated against `ristkari-dev/lua-training` for setting
  repo secrets (or set them in the GitHub UI).
- Cloudflare access for the `ristkari.dev` zone.

## Step 1 — bootstrap GCP

```bash
./deploy/setup.sh
```

Idempotent / re-runnable. It enables the required APIs, creates Artifact
Registry repo `lua-training` in `europe-north1`, creates service account
`github-deploy-lua@ristkari-dev.iam.gserviceaccount.com` with
`artifactregistry.writer` + `run.admin` + `iam.serviceAccountUser`, creates the
shared `github-actions` WIF pool (if missing) and a repo-scoped OIDC provider
`github-lua-training`, binds the repo to impersonate the SA, and prints the
three values to set as GitHub repo secrets.

## Step 2 — set GitHub repo secrets

```bash
gh secret set GCP_PROJECT_ID                 -b "ristkari-dev"
gh secret set GCP_WORKLOAD_IDENTITY_PROVIDER -b "<value-from-setup-output>"
gh secret set GCP_SERVICE_ACCOUNT_EMAIL      -b "github-deploy-lua@ristkari-dev.iam.gserviceaccount.com"
```

Or set them in the GitHub UI: **Settings → Secrets and variables → Actions**.

## Step 3 — first-time service materialisation

The deploy workflow uses `gcloud run services replace deploy/cloudrun.yaml`,
which works only if the service already exists. Create it once with a
placeholder image:

```bash
gcloud run deploy lua-training-slides \
    --image=gcr.io/cloudrun/hello \
    --region=europe-north1 \
    --project=ristkari-dev \
    --platform=managed \
    --allow-unauthenticated \
    --port=8080
```

The first push to `main` then replaces it with the real image.

## Step 4 — map the custom domain

```bash
gcloud beta run domain-mappings create \
    --service=lua-training-slides \
    --domain=lua.ristkari.dev \
    --region=europe-north1 \
    --project=ristkari-dev
```

Output includes a CNAME target like `ghs.googlehosted.com.`.

## Step 5 — Cloudflare DNS

Add a CNAME in the Cloudflare dashboard for `ristkari.dev`:

| Type  | Name | Target                 | Proxy status              |
|-------|------|------------------------|---------------------------|
| CNAME | lua  | `ghs.googlehosted.com` | **DNS only** (gray cloud) |

Leave it gray — Cloudflare proxying (orange cloud) breaks Cloud Run's managed
TLS at the mapped hostname.

Verify:

```bash
dig lua.ristkari.dev CNAME +short
gcloud beta run domain-mappings describe \
    --domain=lua.ristkari.dev \
    --region=europe-north1 \
    --project=ristkari-dev
```

`READY=True` and HTTPS serving follow once Google provisions the managed
certificate (a few minutes after DNS propagates).

## Verifying a deploy

```bash
gh run watch                                   # watch the deploy workflow
curl -sS -I https://lua.ristkari.dev/          # expect HTTP/2 200, text/html
```

Service URL without the custom domain:

```bash
gcloud run services describe lua-training-slides \
    --region=europe-north1 --project=ristkari-dev \
    --format='value(status.url)'
```

## Rolling back

```bash
gcloud run revisions list --service=lua-training-slides \
    --region=europe-north1 --project=ristkari-dev
gcloud run services update-traffic lua-training-slides \
    --to-revisions=lua-training-slides-<previous-revision>=100 \
    --region=europe-north1 --project=ristkari-dev
```
