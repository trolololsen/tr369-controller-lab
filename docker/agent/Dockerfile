FROM ubuntu:24.04

RUN apt update && apt install -y \
    git \
    build-essential \
    autoconf \
    libtool \
    pkg-config \
    libssl-dev \
    libcurl4-openssl-dev \
    libwebsockets-dev \
    uuid-dev \
    protobuf-compiler \
    libmosquitto-dev \
    libsqlite3-dev \
    ca-certificates

WORKDIR /opt

RUN git clone https://github.com/BroadbandForum/obuspa.git

WORKDIR /opt/obuspa

RUN autoreconf --install
RUN pkg-config --modversion sqlite3
RUN ./configure CFLAGS="-Wno-error"
RUN make

RUN mkdir -p /config
RUN mkdir -p /usr/local/var/obuspa

CMD ["./obuspa", "-r", "/config/agent.conf"]
