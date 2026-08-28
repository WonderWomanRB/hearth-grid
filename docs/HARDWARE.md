# Hardware Inventory

Current physical inventory for hearth-grid, including specs, IP assignments, and notes for rebuilds.

## Compute Nodes

### Node A: Core Server (Proxmox Host)

| Property | Value |
|----------|-------|
| **Role** | Hypervisor, HA host, game/voice servers, utilities |
| **Hardware** | Repurposed PC (specs TBD — existing hardware) |
| **CPU** | (Model and core count) |
| **RAM** | (Amount) |
| **Storage** | SSD for VMs/containers; additional disk for backups |
| **Virtualization** | VT-x enabled, IOMMU enabled (if using passthrough) |
| **Proxmox Version** | (to be pinned once decided) |
| **Network** | Static IP: `192.168.x.10` (subnet TBD — see network diagram) |
| **Hostname** | `node-a` or similar |
| **Notes** | USB passthrough for Z-Wave and Matter/Thread radios |

---

### Node B: GPU / AI Workload Node

| Property | Value |
|----------|-------|
| **Role** | Local AI inference, training, internal API |
| **Hardware** | Dedicated compute machine with discrete GPU |
| **CPU** | (Model and core count) |
| **RAM** | (Amount — likely 32 GB+ for AI workloads) |
| **GPU** | (Model, memory, e.g., NVIDIA RTX 4070 Ti, 12 GB VRAM) |
| **Storage** | SSD for container images, models, cache |
| **OS** | TBD — see [DECISIONS.md](DECISIONS.md) (Proxmox or bare-metal Linux) |
| **Virtualization** | (if Proxmox: VT-x + IOMMU required; if bare-metal: N/A) |
| **Network** | Static IP: `192.168.x.30` (subnet TBD) |
| **Hostname** | `node-b-gpu` or similar |
| **Notes** | GPU driver version pinned for stability; NVIDIA Container Toolkit pinned |

---

## Home Assistant VM (on Node A)

| Property | Value |
|----------|-------|
| **OS** | Home Assistant OS (latest stable, version pinned in Proxmox backup) |
| **vCPU** | 2 (adjustable based on load) |
| **RAM** | 3–4 GB (adjustable based on device count) |
| **Storage** | 20–30 GB virtual disk (sized for add-ons, configs, backup snapshots) |
| **Network** | Static IP: `192.168.x.20` (subnet TBD) |
| **Hostname** | `homeassistant` or `ha-core` |
| **Add-ons** | Z-Wave JS, Matter, Tuya, Govee integrations (specific versions TBD) |
| **Backup** | Daily Proxmox snapshot + offsite backup target (details TBD) |

---

## Network-Attached RF Devices

### Z-Wave Radio

| Property | Value |
|----------|-------|
| **Type** | USB stick or network-attached bridge |
| **Model** | (Specific model TBD — e.g., Aeotec Gen5, Zooz ZST39) |
| **Attachment** | USB passthrough to HA VM (if USB stick) or network bridge (if remote) |
| **Power** | (USB powered or plugged in) |
| **Coverage** | (RF range notes; if remote, location in home for optimal coverage) |
| **Network IP** | (if network-attached bridge, e.g., `192.168.x.25`) |
| **Backup** | Z-Wave network key stored in HA backup (not in git) |

---

### Matter / Thread Border Router

| Property | Value |
|----------|-------|
| **Type** | Border router capable device (e.g., Thread border router antenna) |
| **Model** | (Specific model TBD) |
| **Attachment** | Wired Ethernet or Wi-Fi connected to trusted network |
| **Power** | (Powered or PoE) |
| **Location** | (Central location for RF coverage, e.g., living room, kitchen) |
| **Network IP** | (if bridging, e.g., `192.168.x.26`) |
| **Accessible by HA** | Via network interface or USB (TBD) |
| **Backup** | Matter/Thread commissioning keys stored in HA backup |

---

## Display Terminals

### Primary Portal: 4K "Home Status & Control"

| Property | Value |
|----------|-------|
| **Location** | Near Dreamwall in living room (or primary common area) |
| **Purpose** | Comprehensive home status, full control, main HA dashboard |
| **Hardware** | (Platform TBD — see [DECISIONS.md](DECISIONS.md); e.g., Android tablet, small PC, or commercial panel) |
| **Screen Size** | 4K preferred; likely 15"–27" |
| **Network** | Static IP: `192.168.x.50` (or DHCP reservation) |
| **Display Software** | (TBD: Fully Kiosk, browser kiosk, or dedicated HA panel) |
| **Power** | Plugged in (always-on) |
| **Dashboard** | Primary comprehensive view; link in [/home-assistant/dashboards/](../home-assistant/dashboards/) |

---

### Laundry Gate Terminal

| Property | Value |
|----------|-------|
| **Location** | Laundry room |
| **Purpose** | Gate/access control focused; intentionally limited view |
| **Hardware** | (Platform TBD; likely smaller than primary, e.g., 7"–10" tablet or panel) |
| **Screen Size** | 7"–10" screen |
| **Network** | Static IP: `192.168.x.51` (or DHCP reservation) |
| **Display Software** | (TBD) |
| **Power** | Plugged in or battery-backed |
| **Dashboard** | Restricted gate control view; link in [/home-assistant/dashboards/](../home-assistant/dashboards/) |
| **Notes** | Should NOT show full house status; gate logic only |

---

### Office Terminals (scalable)

| Property | Value |
|----------|-------|
| **Location** | Office 1, Office 2, etc. (as added) |
| **Purpose** | Room-scoped view + optional whole-home status subset |
| **Hardware** | (Platform TBD; form factor per office space) |
| **Screen Size** | (TBD per office) |
| **Network** | Static IPs: `192.168.x.52`, `192.168.x.53`, etc. (or DHCP reservations) |
| **Display Software** | (TBD) |
| **Power** | (Plugged in or battery-backed) |
| **Dashboard** | Room-scoped view; link in [/home-assistant/dashboards/](../home-assistant/dashboards/) |
| **Notes** | Can be added incrementally; see [docs/runbooks/add-new-terminal.md](runbooks/add-new-terminal.md) |

---

## Network Infrastructure

| Device | Purpose | IP / DHCP | Notes |
|--------|---------|----------|-------|
| Router / Switch | Network backbone | N/A (local) | (Model, VLAN capability, PoE support TBD) |
| DNS / DHCP | Internal DNS, IP management | `192.168.x.1` (assumed gateway) | Can be Proxmox-hosted or router-native |
| Reverse Proxy | Internal hostname resolution | `192.168.x.11` (TBD) | (Optional; Nginx or HAProxy in container) |
| Monitoring / Dashboard | System health, metrics | `192.168.x.12` (TBD) | (Optional; Grafana + Prometheus or similar) |

---

## Smart Devices (Sample, Expandable)

| Device Type | Count | Integration | Notes |
|-------------|-------|-------------|-------|
| Tuya Smart Plugs | ? | Tuya (local key) | Local API only; local keys stored in secrets.yaml |
| Tuya Bulbs/Lights | ? | Tuya (local key) | Same as above |
| Govee Smart Devices | ? | Govee (LAN or cloud) | LAN API preferred where supported |
| Z-Wave Sensors | ? | Z-Wave JS | (TBD: thermostats, motion, door/window, etc.) |
| Z-Wave Locks | ? | Z-Wave JS | (TBD: specific models, backup codes) |
| Matter Devices | ? | Matter integration | (TBD as ecosystem grows) |
| Other | ? | (TBD) | (Wi-Fi, Zigbee, proprietary, etc.) |

---

## Storage & Backup Infrastructure

| Component | Capacity | Purpose | Notes |
|-----------|----------|---------|-------|
| Node A: VM/Container SSD | (TBD, e.g., 500 GB) | Fast storage for Proxmox VMs, containers | Sizing based on HA OS, game worlds, container images |
| Node A: Backup Disk | (TBD, e.g., 1–2 TB) | Proxmox snapshots, HA backups | Separate from primary SSD for redundancy |
| Node B: Container SSD | (TBD, e.g., 250–500 GB) | AI models, container images, cache | Sized for model library (varies widely) |
| Offsite Backup | (TBD) | Disaster recovery | Details TBD in [DECISIONS.md](DECISIONS.md) |

---

## Template for Adding New Hardware

When adding a new node, terminal, or device:

```markdown
### [Device Type]: [Name/Location]

| Property | Value |
|----------|-------|
| **Role** | (What does it do?) |
| **Hardware** | (Specific model, specs) |
| **Network** | Static IP: `192.168.x.XX` or DHCP reservation |
| **Integration** | (How does it talk to HA or other services?) |
| **Backup** | (Is state backed up? How?) |
| **Notes** | (Any special config, quirks, or setup steps?) |
```

Update this file and [docs/network-diagram.txt](network-diagram.txt) whenever hardware changes, and reference the runbook for that device type (e.g., [docs/runbooks/add-new-terminal.md](runbooks/add-new-terminal.md)).

---

**Last updated**: (to be filled as hardware is added)
