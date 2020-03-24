#!/bin/sh

# environment:
: ${VAULT_ADDR:=http://vault.svc:8200/}
: ${VAULT_ROLE:=example}
: ${VAULT_SECRET_NAME_DRONE_GITHUB_CLIENT_SECRET:=}
: ${VAULT_SECRET_KEY_DRONE_GITHUB_CLIENT_SECRET:=}
: ${VAULT_SECRET_NAME_DRONE_RPC_SECRET:=}
: ${VAULT_SECRET_KEY_DRONE_RPC_SECRET:=}
: ${VAULT_SECRET_NAME_AWS_ACCESS_KEY_ID:=}
: ${VAULT_SECRET_KEY_AWS_ACCESS_KEY_ID:=}
: ${VAULT_SECRET_NAME_AWS_SECRET_ACCESS_KEY:=}
: ${VAULT_SECRET_KEY_AWS_SECRET_ACCESS_KEY:=}

# internal environment
VAULT_TOKEN="$HOME/.vault-token"
cd $HOME

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

if [ -n "${VAULT_SECRET_NAME_DRONE_GITHUB_CLIENT_SECRET}" ]; then
	printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET_NAME_DRONE_GITHUB_CLIENT_SECRET" "$VAULT_SECRET_KEY_DRONE_GITHUB_CLIENT_SECRET" > secret.tpl
	consul-template -template=secret.tpl:secret -once
	export DRONE_GITHUB_CLIENT_SECRET=$(cat secret)
fi

if [ -n "${VAULT_SECRET_NAME_DRONE_RPC_SECRET}" ]; then
	printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET_NAME_DRONE_RPC_SECRET" "$VAULT_SECRET_KEY_DRONE_RPC_SECRET" > secret.tpl
	consul-template -template=secret.tpl:secret -once
	export DRONE_RPC_SECRET=$(cat secret)
fi

if [ -n "${VAULT_SECRET_NAME_DRONE_DATABASE_DATASOURCE}" ]; then
	printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET_NAME_DRONE_DATABASE_DATASOURCE" "$VAULT_SECRET_KEY_DRONE_DATABASE_DATASOURCE" > secret.tpl
	consul-template -template=secret.tpl:secret -once
	export DRONE_DATABASE_DATASOURCE=$(cat secret)
fi

if [ -n "${VAULT_SECRET_NAME_DRONE_DATABASE_SECRET}" ]; then
	printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET_NAME_DRONE_DATABASE_SECRET" "$VAULT_SECRET_KEY_DRONE_DATABASE_SECRET" > secret.tpl
	consul-template -template=secret.tpl:secret -once
	export DRONE_DATABASE_SECRET=$(cat secret)
fi

if [ -n "${VAULT_SECRET_NAME_AWS_ACCESS_KEY_ID}" ]; then
	printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET_NAME_AWS_ACCESS_KEY_ID" "$VAULT_SECRET_KEY_AWS_ACCESS_KEY_ID" > secret.tpl
	consul-template -template=secret.tpl:secret -once
	export AWS_ACCESS_KEY_ID=$(cat secret)
fi

if [ -n "${VAULT_SECRET_NAME_AWS_SECRET_ACCESS_KEY}" ]; then
	printf '{{- with secret "%s" }}{{ .Data.%s }}{{- end }}' "$VAULT_SECRET_NAME_AWS_SECRET_ACCESS_KEY" "$VAULT_SECRET_KEY_AWS_SECRET_ACCESS_KEY" > secret.tpl
	consul-template -template=secret.tpl:secret -once
	export AWS_SECRET_ACCESS_KEY=$(cat secret)
fi

rm -f secret secret.tpl

cd /
/bin/drone-server $*
exit $?
