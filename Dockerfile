# build based on https://hub.docker.com/r/instrumentisto/nmap/

FROM alpine:3.17 as builder

ARG NMAP_VERSION=7.93

# Install dependencies
RUN apk add --update \
            ca-certificates \
            libpcap \
            libgcc libstdc++ \
            libssl3

# Compile and install Nmap from sources
# FIXME: upgrade to latest alpine and remove `-k` from cURL
RUN apk add --update --no-cache --virtual .build-deps \
        libpcap-dev openssl-dev lua-dev linux-headers \
        autoconf g++ libtool make \
         curl \
    \
 && curl -fL -o /tmp/nmap.tar.bz2 \
        https://nmap.org/dist/nmap-${NMAP_VERSION}.tar.bz2 \
 && tar -xjf /tmp/nmap.tar.bz2 -C /tmp \
 && cd /tmp/nmap-${NMAP_VERSION}\
 && ./configure \
        --with-openssl=/usr/lib \
        --prefix=/usr-nmap \
        --sysconfdir=/etc \
        --mandir=/usr/share/man \
        --infodir=/usr/share/info \
        --without-zenmap \
        --without-nmap-update \
        --with-liblua=/usr/include \
 && make \
 && make install


FROM python:3.7-alpine3.17

RUN apk add --no-cache \
            ca-certificates \
            libpcap \
            libstdc++ \
            libssl3
RUN update-ca-certificates

RUN pip install python-libnmap \
        && rm -rf /root/.cache 
       

COPY --from=builder /usr-nmap /usr

VOLUME /input
VOLUME /output

ADD entrypoint.py /

ENTRYPOINT ["python", "-u", "/entrypoint.py"]
