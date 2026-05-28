FROM alpine:latest

RUN apk add --no-cache \
    bash \
    curl \
    docker-cli \
    docker-compose \
    iproute2 \
    iptables \
    iputils \
    bind-tools \
    jq \
    coreutils \
    util-linux

COPY .. /chaos

WORKDIR /chaos

ENTRYPOINT ["/chaos/run.sh"]
