#!/usr/bin/env bash
# =============================================================================
# entrypoint.sh
# Docker ENTRYPOINT for the SAP Business One server container.
# Starts B1 server components in the foreground so Docker can manage them.
# =============================================================================

set -euo pipefail

B1_INSTALL_DIR="${B1_INSTALL_DIR:-/opt/sap/b1}"
SETUP_DONE_FLAG="/var/log/sap/.b1_setup_done"

# ---------------------------------------------------------------------------
# First-run setup
# ---------------------------------------------------------------------------
if [[ ! -f "${SETUP_DONE_FLAG}" ]]; then
    echo "[INFO]  First run detected – executing post-install setup …"
    bash "${B1_INSTALL_DIR}/scripts/setup.sh" && touch "${SETUP_DONE_FLAG}"
fi

# ---------------------------------------------------------------------------
# Start B1 Server Tools (SLD, License Manager, DI Server)
# ---------------------------------------------------------------------------
echo "[INFO]  Starting SAP Business One Server Tools …"
if [[ -x "${B1_INSTALL_DIR}/ServerTools/B1ServerToolsService.sh" ]]; then
    "${B1_INSTALL_DIR}/ServerTools/B1ServerToolsService.sh" start
else
    echo "[WARN]  B1ServerToolsService.sh not found – skipping."
fi

# ---------------------------------------------------------------------------
# Start B1 Service Layer
# ---------------------------------------------------------------------------
echo "[INFO]  Starting SAP Business One Service Layer …"
if [[ -x "${B1_INSTALL_DIR}/ServiceLayer/B1ServiceLayerService.sh" ]]; then
    "${B1_INSTALL_DIR}/ServiceLayer/B1ServiceLayerService.sh" start
else
    echo "[WARN]  B1ServiceLayerService.sh not found – skipping."
fi

# ---------------------------------------------------------------------------
# Keep container alive – tail logs so Docker sees a running process
# ---------------------------------------------------------------------------
echo "[INFO]  SAP Business One server is up.  Tailing logs …"
LOG_FILE="${B1_INSTALL_DIR}/log/b1server.log"
if [[ -f "${LOG_FILE}" ]]; then
    exec tail -f "${LOG_FILE}"
else
    # Fallback: keep container running with an idle loop
    exec tail -f /dev/null
fi
