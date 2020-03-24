# pin versions (configurable)
ARG VAULT_RELEASE=1.3.4
ARG CONSUL_RELEASE=0.24.1
ARG DRONE_IMAGE=drone/drone:1.6.5

# build tools
FROM golang:1.12-alpine AS build
ARG VAULT_RELEASE
ARG CONSUL_RELEASE

RUN apk add gcc git musl-dev
RUN env GO111MODULE=on go get github.com/hashicorp/vault@v${VAULT_RELEASE}
RUN env GO111MODULE=on go get github.com/hashicorp/consul-template@v${CONSUL_RELEASE}

FROM ${DRONE_IMAGE} AS run
COPY --from=build /go/bin/vault /bin/
COPY --from=build /go/bin/consul-template /bin/

RUN apk add net-tools strace curl wget

COPY init.sh /
ENTRYPOINT ["/bin/sh", "/init.sh"]
