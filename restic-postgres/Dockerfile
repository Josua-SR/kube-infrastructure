FROM vault:1.3.2 AS vault-bin
FROM hashicorp/consul-template:0.24.0-alpine AS consul-bin
FROM restic/restic:0.9.6 AS restic-bin

FROM postgres:12.2-alpine
RUN apk add --no-cache pv
COPY --from=vault-bin /bin/vault /bin/
COPY --from=consul-bin /bin/consul-template /bin/
COPY --from=restic-bin /usr/bin/restic /bin/

COPY entry.sh /
ENTRYPOINT ["/bin/sh", "/entry.sh"]
