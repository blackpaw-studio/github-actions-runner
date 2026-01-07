# Policy for the GitHub Actions webhook server to dispatch runner jobs
#
# Create the policy:
#   nomad acl policy apply github-runner-dispatch nomad-jobs/github-runner-policy.hcl
#
# Create a token with this policy:
#   nomad acl token create -name="github-webhook-server" -policy="github-runner-dispatch"
#
# Store the resulting SecretID in Vault at kv/data/github as "nomad_token"

namespace "default" {
  capabilities = ["dispatch-job", "read-job"]

  # Restrict to only the github_runner job
  variables {
    path "jobs/github_runner" {
      capabilities = ["read"]
    }
  }
}
