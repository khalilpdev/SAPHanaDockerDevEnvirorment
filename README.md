# SAP HANA + SAP Business One – Docker Development Environment

> **Stack:** SAP HANA Express 2.0 · SAP Business One 10.00.300 FP 2508 · openSUSE Leap 15.5  
> **Purpose:** Lightweight local development environment running entirely in Docker containers  
> **Host OS:** Windows 10/11 with Docker Desktop (or any Linux/macOS host running Docker Engine)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Prerequisites](#2-prerequisites)
3. [Host Kernel Tuning (required by HANA)](#3-host-kernel-tuning-required-by-hana)
4. [Quick Start](#4-quick-start)
5. [Repository Structure](#5-repository-structure)
6. [Service Reference](#6-service-reference)
7. [Connecting with SAP HANA Client (Windows)](#7-connecting-with-sap-hana-client-windows)
8. [SAP Business One Client (Windows)](#8-sap-business-one-client-windows)
9. [Resource Guidelines](#9-resource-guidelines)
10. [Useful Commands](#10-useful-commands)
11. [Troubleshooting](#11-troubleshooting)
12. [Security Notes](#12-security-notes)

---

## 1. Architecture Overview

```
┌─────────────────────── Docker Host (Windows PC) ──────────────────────────┐
│                                                                            │
│  ┌────────────────────┐          ┌──────────────────────────────────────┐ │
│  │  hxehost           │          │  b1server                            │ │
│  │  SAP HANA Express  │◄─────────│  SAP Business One 10.00.300 FP 2508  │ │
│  │  2.00.075          │  sap_net │  openSUSE Leap 15.5                  │ │
│  │                    │          │                                      │ │
│  │  SQL  :39013/39017 │          │  SLD      :30000                     │ │
│  │  HTTPS:49013       │          │  License  :40000                     │ │
│  │  Web  :8090        │          │  Svc Layer:50000/50001               │ │
│  └────────────────────┘          └──────────────────────────────────────┘ │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  Windows (host)                                                      │ │
│  │  • SAP HANA Client  →  localhost:39017                               │ │
│  │  • SAP B1 Client    →  localhost:30000  (SLD)                        │ │
│  │  • Service Layer    →  http://localhost:50000/b1s/v1/                │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Prerequisites

| Requirement | Minimum | Notes |
|---|---|---|
| Docker Desktop | 4.x | Enable WSL 2 backend on Windows |
| RAM | 20 GB available | HANA needs ≥16 GB, B1 server ≥2 GB |
| Disk | 60 GB free | HANA data + B1 binaries |
| CPU | 4 cores | HANA requires at least 2 |
| SAP S-User | required | To download B1 installer from SAP Service Marketplace |

---

## 3. Host Kernel Tuning (required by HANA)

SAP HANA requires specific Linux kernel parameters. On **Windows with Docker Desktop (WSL 2)**, set them in `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
memory=20GB
processors=4
swap=0
```

Then create (or edit) `/etc/sysctl.conf` inside WSL 2:

```bash
# Open a WSL 2 terminal and run:
wsl -u root -- bash -c "
cat >> /etc/sysctl.conf <<EOF
vm.max_map_count=2147483647
fs.file-max=20000000
kernel.pid_max=4194304
net.ipv4.ip_local_port_range=40000 60999
kernel.shmmni=524288
kernel.shmall=8388608
EOF
sysctl -p
"
```

On a **Linux host**, apply the same values to `/etc/sysctl.conf` and run `sudo sysctl -p`.

---

## 4. Quick Start

### Step 1 – Clone and configure

```bash
git clone https://github.com/khalilpdev/SAPHanaDockerDevEnvirorment.git
cd SAPHanaDockerDevEnvirorment

# Copy the example environment file and edit passwords
cp .env.example .env
# Edit .env with your preferred passwords
```

### Step 2 – Add the B1 installation media

Download **SAP Business One 10.00.300 FP 2508 for SAP HANA – Linux x86_64** from
[SAP Service Marketplace](https://me.sap.com/) and place it in:

```
./b1/media/B1_10.0_FP2508_FOR_HANA_LINUX_X86_64.tar.gz
```

See [`b1/media/README.md`](b1/media/README.md) for detailed download instructions.

### Step 3 – Update the HANA password file

```bash
# Replace the default password in hana/passwords.json with the value
# you set for HANA_MASTER_PASSWORD in .env
nano hana/passwords.json
```

### Step 4 – Build and start

```bash
# Build both images (takes 10–30 min on first run)
docker compose build

# Start all services in the background
docker compose up -d

# Follow the logs
docker compose logs -f
```

### Step 5 – Verify

```bash
# Check service health
docker compose ps

# Test HANA SQL port
docker exec hxehost /bin/bash -c "echo > /dev/tcp/localhost/39017 && echo 'HANA SQL port OK'"

# Test B1 Service Layer
curl http://localhost:50000/b1s/v1/\$metadata
```

---

## 5. Repository Structure

```
.
├── docker-compose.yml          # Main orchestration file
├── .env.example                # Environment variables template
├── .gitignore
│
├── hana/
│   ├── Dockerfile              # Extends saplabs/hanaexpress:2.00.075
│   ├── passwords.json          # HANA first-start credentials (edit before use)
│   └── init.sql                # Post-start SQL tuning for dev
│
└── b1/
    ├── Dockerfile              # openSUSE Leap 15.5 + B1 10.00.300 FP 2508
    ├── media/
    │   └── README.md           # Instructions to download B1 installer
    └── scripts/
        ├── install-b1.sh       # Silent B1 installer (runs during docker build)
        ├── setup.sh            # Post-install setup (runs on first container start)
        └── entrypoint.sh       # Container entrypoint – starts B1 services
```

---

## 6. Service Reference

### SAP HANA Express (`hxehost`)

| Item | Value |
|---|---|
| Image | `saplabs/hanaexpress:2.00.075.00.20240628.1` |
| Container name | `hxehost` |
| System DB SQL port | `39013` |
| Tenant HXE SQL port | `39017` ← **use this for connections** |
| HTTPS port | `49013` |
| Web tools | `http://localhost:8090` |
| Default user | `SYSTEM` |
| Default password | value from `HANA_MASTER_PASSWORD` in `.env` |
| Default tenant | `HXE` |

### SAP Business One Server (`b1server`)

| Item | Value |
|---|---|
| Image | `sap-b1-server-dev:10.00.300-fp2508` (built locally) |
| Container name | `b1server` |
| SLD port | `30000` |
| License server port | `40000` |
| Service Layer HTTP | `http://localhost:50000/b1s/v1/` |
| Service Layer HTTPS | `https://localhost:50001/b1s/v1/` |
| Site user | `manager` |
| Site password | value from `B1_SITE_PASSWORD` in `.env` |

---

## 7. Connecting with SAP HANA Client (Windows)

1. Download and install **SAP HANA Client 2.x** for Windows from SAP Service Marketplace.
2. Open **SAP HANA Studio** or **HDBSQL** and create a connection:
   - Host: `localhost`
   - Port: `39017`
   - User: `SYSTEM`
   - Password: your `HANA_MASTER_PASSWORD`

Using **hdbsql** from the command line:

```cmd
hdbsql -n localhost:39017 -u SYSTEM -p HXEHana1 "SELECT * FROM DUMMY"
```

Using **Python / hdbcli**:

```python
from hdbcli import dbapi

conn = dbapi.connect(
    address="localhost",
    port=39017,
    user="SYSTEM",
    password="HXEHana1"
)
cursor = conn.cursor()
cursor.execute("SELECT * FROM DUMMY")
print(cursor.fetchall())
```

---

## 8. SAP Business One Client (Windows)

1. Download and install the **SAP Business One Client** for Windows (version 10.00.300 FP 2508).
2. During the first connection wizard, set:
   - **Server**: `localhost`
   - **SLD Port**: `30000`
3. Log in with your B1 site user credentials.

---

## 9. Resource Guidelines

SAP HANA is resource-intensive. The values below are the **absolute minimums**
for a single-developer environment with a small company database.

| Container | RAM (reserved) | RAM (limit) | CPU |
|---|---|---|---|
| `hxehost` | 8 GB | 16 GB | 2–4 |
| `b1server` | 2 GB | 4 GB | 1–2 |
| **Total** | **10 GB** | **20 GB** | **3–6** |

If your machine has less than 20 GB of RAM, reduce the limits in
`docker-compose.yml` and ensure HANA's `global_allocation_limit` in
`hana/init.sql` matches your reduced memory budget.

---

## 10. Useful Commands

```bash
# Start everything
docker compose up -d

# Stop everything (keep data)
docker compose stop

# Destroy everything (⚠ deletes volumes = all HANA + B1 data)
docker compose down -v

# Rebuild the B1 image after editing scripts
docker compose build b1server

# Open a shell inside HANA
docker exec -it hxehost /bin/bash

# Open a shell inside B1 server
docker exec -it b1server /bin/bash

# View HANA startup logs
docker compose logs -f hxehost

# Run an HDBSQL query inside the HANA container
docker exec -it hxehost hdbsql -n localhost:39017 -u SYSTEM -p HXEHana1 "SELECT * FROM DUMMY"
```

---

## 11. Troubleshooting

### HANA container exits immediately

- Check kernel parameters: `sysctl vm.max_map_count` must be ≥ 2147483647.
- Make sure the Docker host has at least 16 GB RAM available.
- Check logs: `docker compose logs hxehost`.

### `HANA_MASTER_PASSWORD` does not meet complexity requirements

HANA requires: ≥8 characters, at least one uppercase, one lowercase, one digit.
The default `HXEHana1` satisfies this. If you change it, verify complexity.

### B1 installer not found

Make sure the archive filename in `./b1/media/` exactly matches the value of
`B1_INSTALLER_ARCHIVE` in your `.env` file.

### Service Layer returns 503

B1 depends on HANA being fully started. The `depends_on: condition: service_healthy`
in `docker-compose.yml` waits for the HANA health-check to pass, but HANA may
still be initializing its tenant database. Wait 2–3 more minutes and retry.

---

## 12. Security Notes

> ⚠️ **This environment is for development only. Do not expose it to the internet.**

- The default passwords (`HXEHana1`, `B1Admin1!`) are well-known. Change them
  in `.env` and `hana/passwords.json` before building.
- `hana/passwords.json` is tracked in git with the default dev password.
  If you change the password, make sure **not** to commit the updated file to
  a public repository — add it to `.gitignore` if needed.
- The B1 container runs as a non-root `b1adm` user.
- Exposed ports are bound to `localhost` (127.0.0.1) in the port mappings above;
  adjust `docker-compose.yml` if you need LAN access.

---

## License

This repository contains only configuration files and scripts.
SAP HANA, SAP Business One, and all related software are proprietary products
of SAP SE and are subject to their respective license agreements.
You must have valid SAP licenses to use this environment.
