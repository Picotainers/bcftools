# syntax=docker/dockerfile:1

FROM debian:bookworm-slim AS builder

ARG BCFTOOLS_VERSION=1.23
ARG BCFTOOLS_URL=https://github.com/samtools/bcftools/releases/download/1.23/bcftools-1.23.tar.bz2
ARG BCFTOOLS_SHA256=5acde0ac38f7981da1b89d8851a1a425d1c275e1eb76581925c04ca4252c0778

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bzip2 ca-certificates curl gcc make \
        zlib1g-dev libbz2-dev liblzma-dev libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN curl -fsSL "$BCFTOOLS_URL" -o bcftools.tar.bz2 \
    && echo "$BCFTOOLS_SHA256  bcftools.tar.bz2" | sha256sum -c - \
    && tar -xjf bcftools.tar.bz2

WORKDIR /src/bcftools-1.23
RUN ./configure --disable-libgsl --prefix=/opt/bcftools \
    && make -j2 \
    && make install

# Collect runtime libs needed by bcftools executables.
RUN mkdir -p /tmp/runtime-libs \
    && ldd /opt/bcftools/bin/bcftools | awk '/=> \/|^\// {for(i=1;i<=NF;i++) if ($i ~ /^\//) print $i}' \
    | sort -u | xargs -r -I{} cp -v --parents "{}" /tmp/runtime-libs || true

FROM gcr.io/distroless/base-debian12

COPY --from=builder /opt/bcftools/bin/bcftools /usr/local/bin/bcftools
COPY --from=builder /opt/bcftools/libexec/bcftools /opt/bcftools/libexec/bcftools
COPY --from=builder /tmp/runtime-libs/ /

ENV BCFTOOLS_PLUGINS=/opt/bcftools/libexec/bcftools
WORKDIR /data
ENTRYPOINT ["/usr/local/bin/bcftools"]
