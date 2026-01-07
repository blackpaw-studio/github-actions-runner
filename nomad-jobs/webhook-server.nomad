job "gh_webhook_server" {
    datacenters = ["olympus"]
    region      = "us-east-1"
    type        = "service"

    vault {}

    group "server" {
        count = 1
        network {
            port "http" {
                to = 8080
            }
        }
        service {
            name = "gh_webhook_server"
            port = "http"
            tags = [
                "logs.promtail=true",
                "caddy", "public",
            ]
        }
        task "app" {
            driver = "docker"

            # fetch secrets from Vault KV secret engine
            template {
                env         = true
                destination = "secret/gh-webhook-server.env"
                data        = <<EOF
                    NOMAD_TOKEN = "{{with secret "kv/data/github"}}{{index .Data.data "nomad_token"}}{{end}}"
                    GH_WEBHOOK_SECRET = "{{with secret "kv/data/github"}}{{index .Data.data "github_webhook_secret"}}{{end}}"
                EOF
            }

            env {
                PORT         = "8080"
                NOMAD_HOST   = "http://${NOMAD_IP_http}:4646"
                NOMAD_JOB_ID = "github_runner"
            }

            config {
                image = "ghcr.io/blackpaw-studio/github-actions-runner:latest"
                ports = [
                    "http",
                ]
            }
        }
    }
}