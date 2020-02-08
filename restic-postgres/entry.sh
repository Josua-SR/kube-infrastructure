#!/bin/sh

# environment:
: ${VAULT_ADDR:=http://vault.svc:8200/}
: ${VAULT_ROLE:=example}
: ${VAULT_SECRET:=secret/restic}
: ${VAULT_SECRET_REPO_KEY:=repo}
: ${VAULT_SECRET_PASSWORD_KEY:=password}
: ${DB_HOST:=localhost}
: ${DB_PORT:=5432}
: ${DB_USER:=postgres}
: ${DB_SECRET:=secret/postgres}
: ${DB_SECRET_PASSWORD_KEY:=password}

# dump helper
do_dumpall() {
	env \
		PGHOST="$DB_HOST" \
		PGPORT=$DB_PORT \
		PGUSER="$DB_USER" \
		PGPASSWORD="$DB_PASSWORD" \
		pg_dumpall

	return $?
}

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

# format secrets
printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET" "$VAULT_SECRET_REPO_KEY" > restic-repo.tpl
printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET" "$VAULT_SECRET_PASSWORD_KEY" > restic-password.tpl
printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$DB_SECRET" "$DB_SECRET_PASSWORD_KEY" > db-password.tpl

consul-template -template=restic-repo.tpl:restic-repo -once
consul-template -template=restic-password.tpl:restic-password -once
consul-template -template=db-password.tpl:db-password -once

# read selected secrets to environment
RESTIC_REPO="$(cat restic-repo)"
DB_PASSWORD="$(cat db-password)"

# main
set -o pipefail
do_dumpall | pv | restic \
	--repo "$RESTIC_REPO" \
	--password-file restic-password \
	backup \
	--stdin \
	--stdin-filename all.sql \
	$*


exit $?
