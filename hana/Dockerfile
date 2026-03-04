# =============================================================================
# SAP HANA Express 2.0 - Dockerfile
# Base image: saplabs/hanaexpress (official SAP image on Docker Hub)
#
# This Dockerfile extends the official HANA Express image with a custom
# password configuration and minimum tuning for a development environment.
# =============================================================================
FROM saplabs/hanaexpress:2.00.075.00.20240628.1

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------
LABEL maintainer="dev-team" \
      description="SAP HANA Express 2.0 – development instance (minimum config)" \
      version="2.00.075"

# ---------------------------------------------------------------------------
# Switch to root to apply OS-level settings
# ---------------------------------------------------------------------------
USER root

# Kernel / OS prerequisites recommended by SAP for HANA:
#   vm.max_map_count  >= 2147483647
#   fs.file-max       >= 20000000
#   kernel.pid_max    >= 4194304
# These are best set on the Docker HOST via /etc/sysctl.conf or at container
# start with --sysctl flags (see docker-compose.yml).  We document them here.
#
# Disable transparent huge pages (THP) at container start – handled by the
# entrypoint script below because we cannot change kernel settings from
# inside an unprivileged container without the --privileged flag.

# Copy the custom password file used during first start
COPY --chown=hxeadm:sapsys passwords.json /run/secrets/passwords.json

# Copy optional post-start SQL init script
COPY --chown=hxeadm:sapsys init.sql /hana/shared/init.sql

# ---------------------------------------------------------------------------
# Switch back to the hxeadm user required by the base image
# ---------------------------------------------------------------------------
USER hxeadm

# ---------------------------------------------------------------------------
# Expose HANA ports
# System DB SQL   : 39013
# Tenant HXE SQL  : 39017
# Internal ports  : 39041-39045
# SAP Host Agent  : 1128, 1129
# HTTP (web tools): 8090
# HTTPS           : 49013
# Statistics DB   : 59013, 59014
# ---------------------------------------------------------------------------
EXPOSE 39013 39017 39041 39042 39043 39044 39045 \
       1128 1129 \
       8090 49013 \
       59013 59014
