FROM nimlang/nim:2.0.0-alpine as builder

USER root

RUN --mount=target=/var/lib/apk/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apk,type=cache,sharing=locked \
    rm -f /etc/apk/apk.conf.d/docker-clean && \
    apk update && apk upgrade && \
    apk add ca-certificates git curl xz openssh-client

RUN git clone --depth 1 --branch master https://github.com/HapticX/happyx.git && \
    rm -rf ./happyx/bindings && \
    rm -rf ./happyx/tests && \
    rm -rf ./happyx/.github

WORKDIR /happyx/

# install happyx
RUN nimble install -y -d

ARG HOST="0.0.0.0"
ARG PORT=5123

# Compile frontend
WORKDIR /happyx/examples/website/src
RUN nim js -d:danger --opt:size --hints:off --warnings:off -d:docker main.nim

# Compile backend
WORKDIR /happyx/examples/sandbox_api/src
RUN mkdir ./website && \
    mkdir ./website/public && \
    mkdir ./website/happyx && \
    mkdir ./website/happyx/public && \
    cp /happyx/examples/website/src/main.js ./website/ && \
    cp /happyx/examples/website/src/index.html ./website/ && \
    cp /happyx/examples/website/src/happyx/public/* ./website/public/ && \
    cp /happyx/examples/website/src/happyx/public/* ./website/happyx/public/

WORKDIR /happyx/examples/sandbox_api/src
RUN nim c -d:danger -l:"-flto" -t:"-flto" -d:happyxDebug --warnings:off --opt:size --threads:on -d:port="$PORT" -d:host=$HOST main.nim


# Runner
FROM nimlang/nim:2.0.0-alpine as release

RUN mkdir /happyx
WORKDIR /happyx/
COPY --from=builder /happyx/ ./
WORKDIR /happyx/examples/sandbox_api/src


# Start server
EXPOSE $PORT
ENTRYPOINT ["./main"]
