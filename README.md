# GitHub Actions Runner Autoscaler for Nomad

Autoscaling GitHub Actions self-hosted runners on Nomad. Listens for `workflow_job.queued` webhooks and dispatches ephemeral runner jobs on-demand.

## Architecture

```
GitHub Webhook → Webhook Server (Nomad service) → Dispatches → Runner Job (Nomad batch)
```

## Prerequisites

- Nomad cluster with Vault integration
- Docker driver enabled on Nomad nodes
- GitHub org admin access

## Setup

### 1. Store Secrets in Vault

```bash
# Generate a webhook secret
openssl rand -hex 32

# Store secrets
vault kv put kv/github \
  blackpaw_token="<GITHUB_PAT>" \
  github_webhook_secret="<GENERATED_SECRET>" \
  nomad_token="<NOMAD_TOKEN>"
```

**GitHub PAT permissions** (fine-grained):
- Resource owner: your org
- Organization permissions → Self-hosted runners: Read and write

### 2. Create Nomad ACL Policy

```bash
nomad acl policy apply github-runner-dispatch nomad-jobs/github-runner-policy.hcl
nomad acl token create -name="github-webhook-server" -policy="github-runner-dispatch"
```

Store the resulting `SecretID` in Vault as `nomad_token`.

### 3. Deploy Nomad Jobs

```bash
# Register the runner job first (sits idle until dispatched)
nomad job run nomad-jobs/gha-runner.nomad

# Deploy the webhook server
nomad job run nomad-jobs/webhook-server.nomad
```

### 4. Configure GitHub Webhook

Go to: `https://github.com/organizations/<ORG>/settings/hooks/new`

| Field | Value |
|-------|-------|
| Payload URL | `https://<your-webhook-server-url>/` |
| Content type | `application/json` |
| Secret | Same value stored in Vault |
| Events | Select "Workflow jobs" only |

## Usage

In your workflow files, use:

```yaml
runs-on: [self-hosted, linux-x86]
```

The `self-hosted` label triggers the autoscaler. Additional labels are for routing.

## Files

| File | Purpose |
|------|---------|
| `nomad-jobs/webhook-server.nomad` | Webhook server (long-running service) |
| `nomad-jobs/gha-runner.nomad` | Runner job (parameterized batch) |
| `nomad-jobs/github-runner-policy.hcl` | Nomad ACL policy for dispatch |

## Docker Image

Built automatically on push to main via GitHub Actions:
```
ghcr.io/blackpaw-studio/github-actions-runner:latest
```

## References

- [GitHub: Autoscaling with self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/autoscaling-with-self-hosted-runners)
- [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner)
