ARG CBO_IMAGE_URL=armdocker.rnd.ericsson.se/proj-ldc/common_base_os_release/sles
# CBO PRA version
ARG CBO_VERSION
FROM ${CBO_IMAGE_URL}:${CBO_VERSION} as cbo_base
ARG CBO_VERSION
ARG GITEA_VERSION

############################################################################################################

FROM cbo_base as build_env
ARG ARM_URL="https://arm.sero.gic.ericsson.se/artifactory/proj-ldc-repo-rpm-local"
ARG CBO_REPO="$ARM_URL/common_base_os/sles/$CBO_VERSION"
ARG GO_SDK_REPO="$ARM_URL/adp-dev/go-sdk/$CBO_VERSION"
ARG DEV_REPO="$ARM_URL/adp-dev/adp-build-env/$CBO_VERSION"
RUN zypper addrepo --gpgcheck-strict -f $CBO_REPO COMMON_BASE_OS_SLES_REPO  \
    && zypper addrepo --gpgcheck-strict -f $GO_SDK_REPO GO_SDK_REPO \
    && zypper addrepo --gpgcheck-strict -f $DEV_REPO ADP_DEV_BUILD_ENV_REPO \
    && zypper --gpg-auto-import-keys refresh -f \
    && zypper install -l -y go1.22* gcc
############################################################################################################

# # Build stage
# FROM docker.io/library/golang:1.22-alpine3.19 AS build-env

# ARG GOPROXY
# ENV GOPROXY ${GOPROXY:-direct}

ARG TAGS="sqlite sqlite_unlock_notify"
ENV TAGS "bindata timetzdata $TAGS"
ARG CGO_EXTRA_CFLAGS

#Build deps
RUN zypper install -l -y git nodejs npm make \
    && zypper clean --all \
    && zypper rr COMMON_BASE_OS_SLES_REPO GO_SDK_REPO ADP_DEV_BUILD_ENV_REPO

# Setup repo
COPY . /src/code.gitea.io/gitea
WORKDIR /src/code.gitea.io/gitea

# Checkout version if set
RUN if [ -n "${GITEA_VERSION}" ]; then git checkout "${GITEA_VERSION}"; fi \
 && make clean-all build

# Begin env-to-ini build
RUN go build contrib/environment-to-ini/environment-to-ini.go

# Copy local files
COPY docker/rootless /tmp/local

# Set permissions
RUN chmod 755 /tmp/local/usr/local/bin/docker-entrypoint.sh \
              /tmp/local/usr/local/bin/docker-setup.sh \
              /tmp/local/usr/local/bin/gitea \
              /src/code.gitea.io/gitea/gitea \
              /src/code.gitea.io/gitea/environment-to-ini
RUN chmod 644 /src/code.gitea.io/gitea/contrib/autocompletion/bash_autocomplete

############################################################################################################

FROM cbo_base

ARG GITEA_CONTAINER_NAME=eric-lcm-git-repository-gitea
ARG COMMIT
ARG BUILD_DATE
ARG APP_VERSION
ARG RSTATE
ARG IMAGE_PRODUCT_NUMBER
ARG IMAGE_PRODUCT_TITLE
LABEL \
    org.opencontainers.image.title=$IMAGE_PRODUCT_TITLE \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.vendor=Ericsson \
    org.opencontainers.image.version=$APP_VERSION \
    com.ericsson.product-revision=$RSTATE \
    com.ericsson.product-number=$IMAGE_PRODUCT_NUMBER \
    com.ericsson.product-3pp-name="gitea" \
    com.ericsson.product-3pp-version=${GITEA_VERSION}

EXPOSE 2222 3000

############################################################################################################
ARG ARM_URL="https://arm.sero.gic.ericsson.se/artifactory/proj-ldc-repo-rpm-local"
ARG CBO_REPO="$ARM_URL/common_base_os/sles/$CBO_VERSION"
ARG GO_SDK_REPO="$ARM_URL/adp-dev/go-sdk/$CBO_VERSION"
ARG DEV_REPO="$ARM_URL/adp-dev/adp-build-env/$CBO_VERSION"
RUN zypper addrepo --gpgcheck-strict -f $CBO_REPO COMMON_BASE_OS_SLES_REPO  \
    && zypper addrepo --gpgcheck-strict -f $GO_SDK_REPO GO_SDK_REPO \
    && zypper addrepo --gpgcheck-strict -f $DEV_REPO ADP_DEV_BUILD_ENV_REPO \
    && zypper --gpg-auto-import-keys refresh -f \
    && zypper install -l -y bash shadow ca-certificates gettext-tools git curl gpg wget\
    && zypper clean --all \
    && zypper rr COMMON_BASE_OS_SLES_REPO GO_SDK_REPO ADP_DEV_BUILD_ENV_REPO
############################################################################################################

RUN groupadd \
    --system --gid 1000 \
    git && \
    useradd \
    --system --no-create-home \
    -d /var/lib/gitea/git \
    -s /bin/bash \
    -u 1000 \
    -G git \
    git

RUN mkdir -p /var/lib/gitea /etc/gitea
RUN chown git:git /var/lib/gitea /etc/gitea

COPY --from=build_env /tmp/local /
COPY --from=build_env /src/code.gitea.io/gitea/gitea /app/gitea/gitea
COPY --from=build_env /src/code.gitea.io/gitea/environment-to-ini /usr/local/bin/environment-to-ini
COPY --from=build_env /src/code.gitea.io/gitea/contrib/autocompletion/bash_autocomplete /etc/profile.d/gitea_bash_autocomplete.sh

# git:git
USER 1000:1000
ENV GITEA_WORK_DIR /var/lib/gitea
ENV GITEA_CUSTOM /var/lib/gitea/custom
ENV GITEA_TEMP /tmp/gitea
ENV TMPDIR /tmp/gitea

# TODO add to docs the ability to define the ini to load (useful to test and revert a config)
ENV GITEA_APP_INI /etc/gitea/app.ini
ENV HOME "/var/lib/gitea/git"
VOLUME ["/var/lib/gitea", "/etc/gitea"]
WORKDIR /var/lib/gitea

# Install Ericsson CLM RootCA and Intermediate certificates
USER root:root
ENV TMPDIR /tmp
RUN wget http://pki.ericsson.se/CertData/EGADIssuingCA3.crt -P /usr/local/share/ca-certificates   \
    && wget http://pki.ericsson.se/CertData/EGADRootCA.crt -P /usr/local/share/ca-certificates    \
    && update-ca-certificates
ENV TMPDIR /tmp/gitea
USER 1000:1000

ENTRYPOINT ["/usr/bin/docker-init", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD []

############################################################################################################

