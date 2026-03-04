#!/usr/bin/env bash
# =============================================================================
# setup.sh
# Post-installation setup for SAP Business One on the Docker container.
# Run once after the first successful start.
# =============================================================================

set -euo pipefail

B1_INSTALL_DIR="${B1_INSTALL_DIR:-/opt/sap/b1}"
HANA_HOST="${B1_HANA_HOST:-hxehost}"
HANA_PORT="${B1_HANA_PORT:-39017}"
HANA_USER="${B1_HANA_USER:-SYSTEM}"
HANA_PASSWORD="${B1_HANA_PASSWORD:-HXEHana1}"

echo "[INFO]  Running post-installation setup …"

# ---------------------------------------------------------------------------
# 1. Wait for SAP HANA to accept connections (retry up to 5 minutes)
# ---------------------------------------------------------------------------
echo "[INFO]  Waiting for SAP HANA at ${HANA_HOST}:${HANA_PORT} …"
MAX_RETRIES=30
RETRY_INTERVAL=10
for i in $(seq 1 ${MAX_RETRIES}); do
    if timeout 5 bash -c "echo > /dev/tcp/${HANA_HOST}/${HANA_PORT}" 2>/dev/null; then
        echo "[INFO]  SAP HANA is reachable."
        break
    fi
    echo "[WAIT]  Attempt ${i}/${MAX_RETRIES} – HANA not ready yet, retrying in ${RETRY_INTERVAL}s …"
    sleep ${RETRY_INTERVAL}
    if [[ ${i} -eq ${MAX_RETRIES} ]]; then
        echo "[ERROR] SAP HANA is not reachable after $((MAX_RETRIES * RETRY_INTERVAL))s."
        echo "        Please check:"
        echo "          - The 'hxehost' container is running:  docker compose ps hxehost"
        echo "          - HANA startup logs:                   docker compose logs hxehost"
        echo "          - Kernel parameters are set correctly (see README section 3)"
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# 2. Verify B1 services are running
# ---------------------------------------------------------------------------
echo "[INFO]  Checking B1 services …"
B1_SERVICES=("B1ServerToolsService" "B1ServiceLayerService")
for svc in "${B1_SERVICES[@]}"; do
    if systemctl is-active --quiet "${svc}" 2>/dev/null; then
        echo "[OK]    ${svc} is running."
    else
        echo "[WARN]  ${svc} may not be managed by systemd in Docker – skipping."
    fi
done

echo "[INFO]  Setup complete."
