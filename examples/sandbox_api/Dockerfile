FROM nimlang/nim:2.0.2

RUN export PATH=$PATH:/root/.nimble/bin

# clone repo
RUN git clone https://github.com/HapticX/happyx

WORKDIR /happyx/

# install happyx
RUN nimble install -y -d

WORKDIR /happyx/examples/sandbox_api/src

ARG HOST="127.0.0.1"
ARG PORT=5123

# Compile and start server
RUN nim c -d:production -d:release -d:happyxDebug --opt:speed --threads:on -d:port=$PORT -d:host=$HOST main.nim

EXPOSE $PORT
ENTRYPOINT ["./main"]
