# build based on https://hub.docker.com/r/instrumentisto/nmap/

FROM alpine:3.7 as builder

ARG NMAP_VERSION=7.70

# Install dependencies
RUN apk add --update \
            ca-certificates \
            libpcap \
            libgcc libstdc++ \
            libressl2.6-libcrypto libressl2.6-libssl \
    && update-ca-certificates

# Compile and install Nmap from sources
RUN apk add \
        libpcap-dev libressl-dev lua-dev linux-headers \
        autoconf g++ libtool make \
        curl \
 && curl -fL -o /tmp/nmap.tar.bz2 \
         https://nmap.org/dist/nmap-${NMAP_VERSION}.tar.bz2 \
 && tar -xjf /tmp/nmap.tar.bz2 -C /tmp \
 && cd /tmp/nmap-${NMAP_VERSION} \
 && ./configure \
        --prefix=/usr-nmap \
        --sysconfdir=/etc \
        --mandir=/usr/share/man \
        --infodir=/usr/share/info \
        --without-zenmap \
        --without-nmap-update \
        --with-openssl=/usr/lib \
        --with-liblua=/usr/include \
 && make \
 && make install


FROM python:3.7-alpine3.7

RUN apk add --no-cache \
            ca-certificates \
            libpcap \
            libstdc++ \
            libressl2.6-libcrypto libressl2.6-libssl
RUN update-ca-certificates

RUN pip install python-libnmap && rm -rf /root/.cache

COPY --from=builder /usr-nmap /usr

VOLUME /input
VOLUME /output

ADD entrypoint.py /

ENTRYPOINT ["python", "-u", "/entrypoint.py"]
