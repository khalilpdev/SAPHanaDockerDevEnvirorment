# =============================================================================
# SAP Business One 10.00.300 FP 2508 – Server Dockerfile
# Base OS : openSUSE Leap 15.5  (closest open-source equivalent to SLES 15
#           which SAP officially supports for B1)
#
# IMPORTANT – SAP installation media
# ---------------------------------------------------------------------------
# SAP Business One installation packages are NOT freely redistributable.
# You must download the Linux installer from SAP Service Marketplace using
# your S-User credentials and place the archive in ./media/ before building:
#
#   ./b1/media/B1_10.0_FP2508_FOR_HANA_LINUX_X86_64.tar.gz
#
# The archive is extracted during the build and the server components are
# installed using the silent (non-interactive) installer shipped by SAP.
# =============================================================================
FROM opensuse/leap:15.5

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------
LABEL maintainer="dev-team" \
      description="SAP Business One 10.00.300 FP 2508 Server (HANA edition)" \
      b1.version="10.00.300" \
      b1.fp="2508" \
      os.base="openSUSE Leap 15.5"

# ---------------------------------------------------------------------------
# Build arguments (can be overridden with --build-arg)
# ---------------------------------------------------------------------------
ARG B1_INSTALLER_ARCHIVE=B1_10.0_FP2508_FOR_HANA_LINUX_X86_64.tar.gz
ARG B1_INSTALL_DIR=/opt/sap/b1

# ---------------------------------------------------------------------------
# Environment variables
# ---------------------------------------------------------------------------
ENV B1_INSTALL_DIR=${B1_INSTALL_DIR} \
    SAP_TMP=/tmp/sap-install \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ---------------------------------------------------------------------------
# 1. Install OS prerequisites
#    SAP B1 on Linux requires the packages listed in the B1 admin guide
# ---------------------------------------------------------------------------
RUN zypper --non-interactive refresh && \
    zypper --non-interactive install --no-recommends \
        # Core runtime libraries
        glibc \
        libstdc++6 \
        libuuid1 \
        libgcc_s1 \
        libXext6 \
        libXrender1 \
        libXtst6 \
        libXi6 \
        # Networking / SSL
        openssl \
        ca-certificates \
        # Java runtime (required by B1 SLD & Integration Framework)
        java-17-openjdk-headless \
        # Utilities
        curl \
        unzip \
        tar \
        gzip \
        hostname \
        procps \
        net-tools \
        sudo \
        # Locale
        glibc-locale \
    && zypper clean --all \
    && localedef -i en_US -f UTF-8 en_US.UTF-8

# ---------------------------------------------------------------------------
# 2. Create the b1adm OS user (mirrors the SAP standard account)
# ---------------------------------------------------------------------------
RUN groupadd -g 2000 sapsys && \
    useradd  -u 2000 -g sapsys -m -s /bin/bash -d /home/b1adm b1adm && \
    echo "b1adm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/b1adm && \
    chmod 0440 /etc/sudoers.d/b1adm

# ---------------------------------------------------------------------------
# 3. Create installation working directory
# ---------------------------------------------------------------------------
RUN mkdir -p ${SAP_TMP} ${B1_INSTALL_DIR}

# ---------------------------------------------------------------------------
# 4. Copy the SAP B1 installation media into the image
#    (file must exist in ./b1/media/ on the build host)
# ---------------------------------------------------------------------------
COPY media/${B1_INSTALLER_ARCHIVE} ${SAP_TMP}/

# ---------------------------------------------------------------------------
# 5. Copy helper scripts
# ---------------------------------------------------------------------------
COPY scripts/install-b1.sh  ${SAP_TMP}/install-b1.sh
COPY scripts/setup.sh       ${SAP_TMP}/setup.sh
COPY scripts/entrypoint.sh  /entrypoint.sh

RUN chmod +x ${SAP_TMP}/install-b1.sh \
              ${SAP_TMP}/setup.sh \
              /entrypoint.sh

# ---------------------------------------------------------------------------
# 6. Run the silent B1 installer
# ---------------------------------------------------------------------------
RUN cd ${SAP_TMP} && \
    tar -xzf ${B1_INSTALLER_ARCHIVE} && \
    bash ${SAP_TMP}/install-b1.sh && \
    # Clean up installation media to keep image size small
    rm -rf ${SAP_TMP}

# ---------------------------------------------------------------------------
# 7. Persist B1 data directories
# ---------------------------------------------------------------------------
VOLUME ["${B1_INSTALL_DIR}/conf", "${B1_INSTALL_DIR}/log", "/var/log/sap"]

# ---------------------------------------------------------------------------
# 8. Expose SAP B1 ports
# SLD (System Landscape Directory) : 30000
# License Manager                  : 40000
# Service Layer HTTP                : 50000
# Service Layer HTTPS               : 50001
# Message Server                   : 39900
# ---------------------------------------------------------------------------
EXPOSE 30000 40000 50000 50001 39900

# ---------------------------------------------------------------------------
# 9. Switch to b1adm for runtime (non-root principle)
# ---------------------------------------------------------------------------
USER b1adm
WORKDIR /home/b1adm

ENTRYPOINT ["/entrypoint.sh"]
