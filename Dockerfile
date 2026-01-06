FROM alpine AS builder

ARG LIBTORRENT_VERSION
ARG DELUGE_VERSION
ARG TARGETARCH

RUN set -eux; \
	apk add --no-cache \
		build-base cmake ninja git gettext \
		python3-dev py3-setuptools py3-wheel \
		boost-dev openssl-dev linux-headers curl \
		tar xz

WORKDIR /sources
RUN set -eux; \
	wget https://github.com/arvidn/libtorrent/releases/download/v${LIBTORRENT_VERSION}/libtorrent-rasterbar-${LIBTORRENT_VERSION}.tar.gz; \
    tar zxf libtorrent-rasterbar-${LIBTORRENT_VERSION}.tar.gz
WORKDIR /sources/libtorrent-rasterbar-${LIBTORRENT_VERSION}
RUN set -eux; \
	cmake -S . -B release -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -Dpython-bindings=ON; \
	ninja -C release -j$(nproc); \
	ninja -C release install

WORKDIR /sources/deluge
RUN set -eux; \
    git clone https://github.com/deluge-torrent/deluge.git .; \
    git checkout tags/deluge-${DELUGE_VERSION}; \
    python3 setup.py build; \
    python3 setup.py install --root=/install_root

RUN set -eux; \
    PY_PATH=$(python3 -c "import site; print(site.getsitepackages()[0])"); \
    mkdir -p /install_root${PY_PATH}; \
    cp -pr /usr/lib/python3*/site-packages/libtorrent* /install_root${PY_PATH}/; \
    \
    case "$TARGETARCH" in \
      amd64) S6_ARCH=x86_64 ;; arm64) S6_ARCH=aarch64 ;; \
      arm) S6_ARCH=armhf ;; ppc64le) S6_ARCH=powerpc64le ;; \
      s390x) S6_ARCH=s390x ;; *) S6_ARCH="$TARGETARCH" ;; \
    esac; \
    URL=https://github.com/just-containers/s6-overlay/releases/latest/download; \
    for pkg in noarch ${S6_ARCH} symlinks-noarch symlinks-arch; do \
        curl -fsSL -O "$URL/s6-overlay-${pkg}.tar.xz"; \
        tar -xJf s6-overlay-${pkg}.tar.xz -C /install_root; \
    done

FROM alpine

RUN set -eux; \
	apk add --no-cache \
    python3 py3-twisted py3-openssl py3-rencode py3-six py3-mako py3-chardet \
    boost-python3 boost-system libstdc++ openssl ca-certificates shadow xz tzdata

COPY --from=builder /install_root /

COPY rootfs/ /

ENV PUID=1000 \
    PGID=1000 \
    DELUGE_CONFIG_DIR=/config \
    DELUGE_DOWNLOAD_DIR=/downloads \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

EXPOSE 8112 58846

ENTRYPOINT ["/init"]
