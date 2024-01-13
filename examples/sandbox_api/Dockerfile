FROM nimlang/nim:2.0.2

RUN export PATH=$PATH:/root/.nimble/bin

# clone repo
RUN git clone https://github.com/HapticX/happyx

WORKDIR /happyx/

# install happyx
RUN nimble install -y -d

ARG HOST="0.0.0.0"
ARG PORT=5123

# Compile frontend
WORKDIR /happyx/examples/website/src
RUN nim js -d:danger --opt:size --hints:off --warnings:off main.nim

# Compile backend
WORKDIR /happyx/examples/sandbox_api/src
RUN mkdir ./website
RUN mkdir ./website/public
RUN mkdir ./website/happyx
RUN mkdir ./website/happyx/public
RUN cp /happyx/examples/website/src/main.js ./website/
RUN cp /happyx/examples/website/src/index.html ./website/
RUN cp /happyx/examples/website/src/happyx/public/* ./website/public/
RUN cp /happyx/examples/website/src/happyx/public/* ./website/happyx/public/

WORKDIR /happyx/examples/sandbox_api/src
RUN nim c -d:release -d:happyxDebug --warnings:off --opt:speed --threads:on -d:port="$PORT" -d:host=$HOST main.nim

# Start server
EXPOSE $PORT
ENTRYPOINT ["./main"]
