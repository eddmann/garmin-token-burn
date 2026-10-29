# Build environment for the Token Burn app and watch face. Bakes the Connect IQ SDK and
# the synthesised Forerunner 255 device files into the image, then builds
# the repository mounted at /work.
#
#   make build/docker
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip make python3 openssl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# Bake the toolchain with a copy of the build files; the repository is
# mounted over /work at run time.
COPY Makefile ./
COPY scripts ./scripts
RUN make deps TOOLCHAIN=/opt/ciq KEY=/opt/ciq/developer_key.der

CMD ["make", "build/all", "TOOLCHAIN=/opt/ciq", "KEY=/opt/ciq/developer_key.der"]
