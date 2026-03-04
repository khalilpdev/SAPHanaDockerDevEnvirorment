#!/usr/bin/env bash
# =============================================================================
# install-b1.sh
# Silent installation of SAP Business One 10.00.300 FP 2508 (HANA edition)
# for Linux.
#
# This script is executed INSIDE the Docker build context (RUN step).
# It expects the installer archive to have been extracted under $SAP_TMP.
#
# Reference: SAP Note 2058694 – SAP Business One Server on Linux
# =============================================================================

set -euo pipefail

SAP_TMP="${SAP_TMP:-/tmp/sap-install}"
B1_INSTALL_DIR="${B1_INSTALL_DIR:-/opt/sap/b1}"

# ---------------------------------------------------------------------------
# Locate the extracted installer directory
# SAP packages the installer as a folder whose name varies between FP releases.
# We look for the server installation script generically.
# ---------------------------------------------------------------------------
INSTALLER_DIR=$(find "${SAP_TMP}" -maxdepth 2 -name "install.sh" -printf '%h\n' | head -1)

if [[ -z "${INSTALLER_DIR}" ]]; then
    echo "[ERROR] Could not find install.sh inside ${SAP_TMP}."
    echo "        Make sure the correct archive is placed in ./b1/media/."
    exit 1
fi

echo "[INFO]  Found B1 installer at: ${INSTALLER_DIR}"
cd "${INSTALLER_DIR}"

# ---------------------------------------------------------------------------
# Generate the silent installation response file
# Adjust the values here to match your environment.
# The file is written with strict permissions so that only the current user
# can read it, and it is deleted immediately after the installer exits.
# ---------------------------------------------------------------------------
RESPONSE_FILE=$(mktemp /tmp/b1_silent_XXXXXX.properties)
chmod 600 "${RESPONSE_FILE}"

cat > "${RESPONSE_FILE}" <<EOF
# SAP Business One Silent Installation Properties
# -----------------------------------------------

# Installation mode: install | upgrade
InstallMode=install

# Target installation directory
InstallDir=${B1_INSTALL_DIR}

# Accept SAP EULA (required for silent install)
AcceptEULA=true

# Components to install
# SERVER      – B1 Server Tools (SLD, License, DI Server)
# SERVICELAYER – B1 Service Layer (REST API)
# Minimal set for development: SERVER + SERVICELAYER
Components=SERVER,SERVICELAYER

# SAP HANA database connection
DBType=HANA
DBServer=hxehost
DBPort=39017
DBUser=SYSTEM
DBPassword=${B1_HANA_PASSWORD:-HXEHana1}

# B1 System Landscape Directory (SLD)
SLDHostName=b1server
SLDPort=30000

# License server
LicenseServer=b1server
LicensePort=40000

# Service Layer
ServiceLayerHTTPPort=50000
ServiceLayerHTTPSPort=50001

# Administrator credentials for the B1 Common DB (SBO-COMMON)
B1SiteUser=manager
B1SitePassword=${B1_SITE_PASSWORD:-B1Admin1!}

# Log level: 0=Error, 1=Warning, 2=Info, 3=Debug
LogLevel=1

# Installer log path
LogPath=/var/log/sap/b1_install.log
EOF

# ---------------------------------------------------------------------------
# Run the installer
# ---------------------------------------------------------------------------
echo "[INFO]  Starting SAP Business One silent installation …"
bash ./install.sh --silent "${RESPONSE_FILE}"
INSTALL_EXIT=$?

# Delete the response file immediately after the installer exits
rm -f "${RESPONSE_FILE}"

if [[ ${INSTALL_EXIT} -ne 0 ]]; then
    echo "[ERROR] SAP Business One installer exited with code ${INSTALL_EXIT}."
    exit ${INSTALL_EXIT}
fi

echo "[INFO]  SAP Business One installation completed."
