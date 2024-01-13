FROM nimlang/nim:2.0.2

LABEL version="1.0.0"
LABEL org.opencontainers.image.authors="social.ethosa@gmail.com"

RUN export PATH=$PATH:/root/.nimble/bin

# install happyx
RUN nimble install happyx@#head -y -d
