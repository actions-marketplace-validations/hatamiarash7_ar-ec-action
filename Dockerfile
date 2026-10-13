# syntax=docker/dockerfile:1

ARG DEBIAN_TAG=stable-slim

FROM debian:${DEBIAN_TAG} AS downloader

# Release assets live at https://git.arvancloud.ir/arvancloud/cli/-/releases
# Checksums come from the "arvan-cli-<version>-checksums.txt" release asset.
ARG ARVAN_CLI_VERSION=0.4.0
ARG ARVAN_CLI_SHA256_AMD64=33f633ee7471ca0d733fb5a25cca66dac7542eddbb584d28ac19e6ab16ca8e80
ARG ARVAN_CLI_SHA256_ARM64=c943766c6a0a3ad4ea676db94b9ab32333794c67762943fcae83c4750d095752

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

RUN set -euo pipefail; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
    amd64) sha256="${ARVAN_CLI_SHA256_AMD64}" ;; \
    arm64) sha256="${ARVAN_CLI_SHA256_ARM64}" ;; \
    *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    archive="arvan-cli-${ARVAN_CLI_VERSION}-linux-${arch}.tar.gz"; \
    curl --fail --silent --show-error --location --retry 3 --retry-delay 2 \
    -o "/tmp/${archive}" \
    "https://git.arvancloud.ir/arvancloud/cli/-/releases/v${ARVAN_CLI_VERSION}/downloads/${archive}"; \
    echo "${sha256}  /tmp/${archive}" | sha256sum --check --strict -; \
    tar -xzf "/tmp/${archive}" -C /tmp \
    "arvan-cli-${ARVAN_CLI_VERSION}-linux-${arch}/arvan"; \
    install -m 0755 "/tmp/arvan-cli-${ARVAN_CLI_VERSION}-linux-${arch}/arvan" /usr/local/bin/arvan; \
    arvan version

FROM debian:${DEBIAN_TAG}

ARG ARVAN_CLI_VERSION=0.4.0
# Keep in sync with the releases listed in CHANGELOG.md.
ARG ACTION_VERSION=1.0.3

LABEL maintainer="Arash Hatami <hatamiarash7@gmail.com>" \
    org.opencontainers.image.title="ArvanCloud Edge Computing Action" \
    org.opencontainers.image.description="Deploy new changes to ArvanCloud Edge Computing" \
    org.opencontainers.image.version="${ACTION_VERSION}" \
    org.opencontainers.image.authors="hatamiarash7" \
    org.opencontainers.image.vendor="hatamiarash7" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source="https://github.com/hatamiarash7/ar-ec-action" \
    ir.arvancloud.cli.version="${ARVAN_CLI_VERSION}"

# ca-certificates is required for the CLI to talk to the ArvanCloud API.
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=downloader /usr/local/bin/arvan /usr/local/bin/arvan
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
