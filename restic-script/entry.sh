#!/bin/sh -e

# environment:
: ${VAULT_ADDR:=http://vault.svc:8200/}
: ${VAULT_ROLE:=example}
: ${VAULT_SECRET:=secret/restic}
: ${VAULT_SECRET_REPO_KEY:=repo}
: ${VAULT_SECRET_PASSWORD_KEY:=password}

# internal environment
VAULT_TOKEN="$HOME/.vault-token"

# authenticate to Vault
cat > agent.hcl << EOF
exit_after_auth = true
pid_file = "$HOME/vault.pid"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "$VAULT_ROLE"
        }
    }

    sink "file" {
        config = {
            path = "$VAULT_TOKEN"
        }
    }
}
EOF
vault agent -config=agent.hcl

# format secret
printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET" "$VAULT_SECRET_REPO_KEY" > restic-repo.tpl
printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET" "$VAULT_SECRET_PASSWORD_KEY" > restic-password.tpl

consul-template -template=restic-repo.tpl:restic-repo -once
consul-template -template=restic-password.tpl:restic-password -once

# read repo to environment
RESTIC_REPO="$(cat restic-repo)"

# main
s=0
restic \
	--repo "$RESTIC_REPO" \
	--password-file restic-password \
	$* || s=$?

exit $s
