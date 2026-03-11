FROM ubuntu:22.04

RUN apt update && apt install -y \
git build-essential autoconf libtool pkg-config \
libssl-dev libcurl4-openssl-dev \
libwebsockets-dev uuid-dev \
protobuf-compiler \
libmosquitto-dev \
ca-certificates

RUN git clone https://github.com/BroadbandForum/obuspa-test-controller.git

WORKDIR /obuspa-test-controller

RUN autoreconf --install
RUN ./configure
RUN make

RUN mkdir /config

CMD ./obuspa-controller -c /config/controller.conf