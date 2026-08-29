# GPU Node Driver & Toolkit Notes
Node: B (GPU / AI Inference Node)
Purpose: Ensure reproducible GPU setup for Ollama + YOLO containers

---

## GPU Hardware
- Model: NVIDIA (insert exact model here, e.g., RTX 4070 Ti)
- VRAM: (insert amount, e.g., 12 GB)
- PCIe IDs:
  - GPU: `0000:xx:00.0`
  - Audio: `0000:xx:00.1`
- IOMMU: Enabled (VT-d / AMD-Vi)
- Passthrough: Configured via Proxmox (see rebuild-gpu-node.md)

---

## OS & Kernel
- OS: Ubuntu 22.04 LTS (inside VM)
- Kernel: 5.15.x or 6.x (Ubuntu default)
- Bootloader: OVMF (UEFI)
- Machine type: q35

---

## NVIDIA Driver Version (Pinned)
Pinned version: **535.xx**

Why pinned:
- Stable with CUDA 12.1
- Known compatibility with Ollama GPU backend
- Known compatibility with Ultralytics YOLO CUDA runtime
- Avoids breakage from automatic driver upgrades

Install command (from runbook):

```bash
sudo apt-get install -y cuda-toolkit-12-1 nvidia-driver-535
