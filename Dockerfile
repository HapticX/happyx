FROM nimlang/nim:2.2.10

LABEL version="1.0.1"
LABEL org.opencontainers.image.authors="social.ethosa@gmail.com"

RUN export PATH=$PATH:/root/.nimble/bin

# install happyx
RUN nimble install happyx@#head -y -d
