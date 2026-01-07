job "github_runner" {
    datacenters = ["olympus"]
    type        = "batch"
    region      = "us-east-1"

    parameterized {
        payload = "forbidden"
        meta_required = ["GH_REPO_URL"]
    }

    constraint {
        attribute = "${node.class}"
        value     = "linux"
    }

    vault {}

    group "runners" {
        task "runner" {
            driver = "docker"

            # fetch secrets from Vault KV secret engine
            template {
                env = true
                destination = "secret/vault.env"
                data = <<EOF
                    ACCESS_TOKEN = "{{with secret "kv/data/github"}}{{index .Data.data.blackpaw_token }}{{end}}"
                EOF
            }

            env {
                EPHEMERAL           = "true"
                DISABLE_AUTO_UPDATE = "true"
                RUNNER_NAME_PREFIX  = "olympus"
                ORG_NAME            = "blackpaw-studio"
                RUNNER_WORKDIR      = "/tmp/runner/work"
                RUNNER_SCOPE        = "org"
                LABELS              = "linux-x86,${NOMAD_NODE_NAME}"
            }

            config {
                image = "myoung34/github-runner:2.321.0-ubuntu-jammy"
                
                privileged  = true
                userns_mode = "host"

                # Allow DooD (Docker outside of Docker)
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock",
                ]
            }
        }
    }
}