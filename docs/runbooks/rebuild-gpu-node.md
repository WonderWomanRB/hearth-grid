# Rebuild GPU Node (Node B)

**Purpose**: Set up Node B with GPU passthrough to VM for AI inference (Ollama + YOLO)  
**Time**: ~1 hour (Proxmox setup + VM creation + GPU passthrough + driver installation)  
**Difficulty**: Hard (GPU passthrough is finicky; requires BIOS config, kernel tuning, driver matching)

## Quick Start

1. Proxmox VE installed on Node B (see [rebuild-proxmox-node.md](rebuild-proxmox-node.md))
2. BIOS: Enable IOMMU (VT-d for Intel, AMD-Vi for AMD)
3. Create Ubuntu 22.04 LTS VM with GPU passthrough
4. Inside VM: Install NVIDIA drivers (or AMD equivalent) + CUDA + Docker
5. Deploy docker-compose with Ollama and YOLO containers

---

## Prerequisites

**Hardware**:
- Node B already running Proxmox VE (see [rebuild-proxmox-node.md](rebuild-proxmox-node.md))
- Discrete GPU (NVIDIA or AMD)
  - **Recommended**: NVIDIA RTX 4070 Ti, RTX 3080 Ti, or better
  - **Minimum**: NVIDIA GTX 1660 Ti or equivalent (6+ GB VRAM)
  - **AMD**: Radeon RX 6000 series or better
- GPU physically installed in PCIe slot
- Adequate power supply for GPU (check GPU TDP)

**BIOS Settings** (already done in provision-proxmox.sh, but verify):
- ✅ VT-x (Intel) or AMD-V enabled
- ✅ IOMMU (VT-d or AMD-Vi) enabled
- ✅ ACS (Access Control Services) enabled (if available)
- ✅ Resizable BAR disabled (optional; can help with performance)

**Network**:
- Static IP assigned (192.168.1.30 for Node B)
- SSH access to Proxmox host working

---

## Step 1: Verify IOMMU on Proxmox Host

### SSH into Node B (Proxmox host):

```bash
ssh root@192.168.1.30

# Check IOMMU status
dmesg | grep -i "IOMMU\|IOMMU enabled"

# Expected output (Intel):
# [    0.000000] DMAR: IOMMU enabled.

# Expected output (AMD):
# [    0.000000] AMD-Vi: IOMMU enabled

# If nothing appears, go back to BIOS and enable IOMMU
```

### Verify IOMMU Groups:

```bash
# List IOMMU groups and devices
for g in $(find /sys/kernel/iommu_groups -type d -name "devices" | sort -V); do
    echo "IOMMU Group $(basename $(dirname $g)):"
    lspci -nns $(lspci -D | grep "$(ls $g)" | awk '{print $1}')
done

# Look for your GPU in the output
# Example: "NVIDIA Corporation GA102 [GeForce RTX 3080 Ti] ... [10de:2206]"
```

### Find GPU PCI ID:

```bash
# List all GPUs
lspci | grep -i "nvidia\|amd"

# Example output:
# 0a:00.0 VGA compatible controller: NVIDIA Corporation GA102 [GeForce RTX 3080 Ti]
# 0a:00.1 Audio device: NVIDIA Corporation GA102 High Definition Audio Controller

# Note both IDs (0a:00.0 for GPU, 0a:00.1 for audio/HDMI)
# You'll need these for passthrough
```

---

## Step 2: Create GPU VM in Proxmox

### Access Proxmox Web UI:

1. Open `https://192.168.1.30:8006`
2. Login with root credentials
3. Click **Create VM** (top-right)

### VM Configuration:

#### **General Tab**:
```
VM ID: 200
Name: ai-inference
Node: node-b-gpu
```
Click **Next**

#### **OS Tab**:
```
Guest OS Type: Linux
Version: 5.x or 6.x kernel
(Can leave as generic Linux)
```
Click **Next**

#### **System Tab**:
```
Graphics Device: None (we'll use passthrough)
Machine Type: q35
BIOS: OVMF (UEFI)
EFI Storage: local
```
Click **Next**

#### **Disk Tab**:
```
Storage: local-lvm
Disk size: 50 (GB; plenty for AI models)
Discard: Enabled
```
Click **Next**

#### **CPU Tab**:
```
Cores: 8 (half of Node B CPU if available; more is better for AI)
Type: host
Socket: 1
```
Click **Next**

#### **Memory Tab**:
```
Memory (MB): 32768 (32 GB; more is better)
Minimum memory (MB): 16384
```
Click **Next**

#### **Network Tab**:
```
Bridge: vmbr0
Model: VirtIO
Firewall: Enabled
```
Click **Next**

#### **Confirm Tab**:
Review settings and click **Finish**

VM is created but not started yet.

---

## Step 3: Install Ubuntu 22.04 LTS in VM

### Download Ubuntu ISO:

```bash
# On Proxmox host (or your PC)
cd /var/lib/vz/template/iso
wget https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso
```

### Attach ISO to VM:

1. Proxmox web UI → **ai-inference** VM → **Hardware** tab
2. Click **Add** → **CD/DVD Drive**
3. Select the Ubuntu ISO
4. Click **Add**

### Start VM and Install:

1. Proxmox → **ai-inference** → Click **Start**
2. Click **Console** tab
3. Follow Ubuntu installer:
   ```
   [Press ENTER for graphical installer or use text mode]
   
   Welcome to Ubuntu Server
   [Choose your language and continue]
   
   Network:
     Use DHCP or static IP (192.168.1.31)
   
   Storage:
     Use entire disk (/dev/vda)
   
   Profile Setup:
     Name: AI Node
     Server name: ai-node
     Username: ubuntu
     Password: [strong password]
   
   SSH:
     Install OpenSSH server: YES
     Import SSH identity: (optional)
   
   [Wait for installation to complete ~5-10 min]
   System reboots automatically
   ```

### After Ubuntu boots:

```bash
# VM is ready when you see login prompt
# SSH from Proxmox host:
ssh ubuntu@192.168.1.31

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install essential tools
sudo apt-get install -y curl wget vim git htop net-tools python3-pip python3-venv
```

---

## Step 4: Pass Through GPU to VM

### Add GPU to VM via Proxmox Web UI:

1. Proxmox → **ai-inference** VM → **Hardware** tab
2. Click **Add** → **PCI Device**
3. Select your GPU (e.g., "0a:00.0 - NVIDIA GA102")
4. **Important**: Check "All Functions" and "ROM-Bar" checkboxes
5. Click **Add**

### If audio/HDMI also needed:

1. Click **Add** → **PCI Device** again
2. Select GPU audio device (e.g., "0a:00.1 - NVIDIA Audio")
3. Click **Add**

### Shutdown and restart VM:

```bash
# In Proxmox web UI
ai-inference VM → Shutdown → confirm
Wait 30 seconds
Click Start
```

### Verify GPU is passed through:

```bash
# SSH into VM
ssh ubuntu@192.168.1.31

# Check if GPU is visible
lspci | grep -i nvidia

# Expected output:
# 0000:00:05.0 VGA compatible controller: NVIDIA Corporation GA102 ...
```

If GPU not visible, troubleshoot:
- Check Proxmox host: `dmesg | tail -20` for passthrough errors
- Verify IOMMU groups (see Step 1)
- Ensure VM shutdown before modifying passthrough config

---

## Step 5: Install NVIDIA Drivers & CUDA

### Inside AI VM:

```bash
ssh ubuntu@192.168.1.31

# Add NVIDIA repository
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600

# Add NVIDIA GPG key
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub

# Add repository
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /"

# Update and install CUDA + drivers
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-1 nvidia-driver-535

# Note: Pin specific driver version for consistency
# driver-535 is stable and well-tested with CUDA 12.1
```

### Verify Installation:

```bash
# Check NVIDIA driver
nvidia-smi

# Expected output:
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 535.xx                 Driver Version: 535.xx                    |
# +-----------------------------------------------------------------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# | No   Name        Off | 00:05.0        Off |      N/A |

# Check CUDA
nvcc --version
# Expected: CUDA 12.1
```

**If GPU not detected**:
```bash
# Check kernel messages
dmesg | grep -i nvidia

# If IOMMU conflict:
sudo dmesg | grep "DMAR\|IOMMU" | tail -5

# Verify GPU passed through correctly
lspci -s 00:05.0 -vvv | grep "Region\|Memory"
```

---

## Step 6: Install Docker & NVIDIA Container Toolkit

### Install Docker:

```bash
# Remove old Docker (if exists)
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Install from official repo
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu
newgrp docker

# Verify Docker
docker --version
```

### Install NVIDIA Container Toolkit:

```bash
# Add NVIDIA container repo
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Restart Docker daemon
sudo systemctl restart docker

# Verify NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.1.1-runtime-ubuntu22.04 nvidia-smi

# Expected: nvidia-smi output from inside container
```

---

## Step 7: Deploy AI Containers

### Download docker-compose:

```bash
cd /home/ubuntu

# Download compose file
curl -O https://raw.githubusercontent.com/WonderWomanRB/hearth-grid/main/gpu-node/docker-compose.yaml

# Download provisioning script
curl -O https://raw.githubusercontent.com/WonderWomanRB/hearth-grid/main/gpu-node/provision-ai-services.sh
chmod +x provision-ai-services.sh

# Create data directories
mkdir -p data/ollama
mkdir -p data/yolo

# Start services
docker-compose up -d
```

### Verify Services:

```bash
# Check running containers
docker ps

# Expected: ollama and yolo-api containers running

# Check Ollama
curl http://localhost:11434/api/tags

# Expected: JSON response with available models

# Check YOLO API
curl http://localhost:8000/health

# Expected: {"status": "ok"}
```

---

## Step 8: Verify End-to-End

### Test Ollama:

```bash
# Pull a model (first time is large download)
docker exec ollama ollama pull mistral

# Query the model
curl http://localhost:11434/api/generate -X POST \
  -d '{"model":"mistral","prompt":"Hello, how are you?","stream":false}'

# Expected: JSON response with model output
```

### Test YOLO:

```bash
# Save a test image
curl https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/1200px-Cat03.jpg -o test.jpg

# Send to YOLO API
curl -X POST http://localhost:8000/detect \
  -F "file=@test.jpg"

# Expected: JSON with detected objects
```

### Test HA Integration:

```bash
# From HA VM, call YOLO API
curl http://192.168.1.31:8000/health

# Expected: {"status": "ok"}

# Call Ollama from HA
curl http://192.168.1.31:11434/api/tags

# Expected: Model list
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| "GPU not visible in VM" | Passthrough not configured or IOMMU groups conflict | Verify IOMMU enabled in BIOS; check Proxmox host dmesg |
| "nvidia-smi: command not found" | NVIDIA driver not installed | Install drivers: `sudo apt-get install cuda-toolkit-12-1 nvidia-driver-535` |
| "Docker GPU access denied" | NVIDIA Container Toolkit not installed | Install: `sudo apt-get install nvidia-container-toolkit` |
| "Ollama containers not starting" | Port conflict or GPU allocation issue | Check `docker logs ollama`; verify GPU availability |
| "YOLO inference very slow" | GPU not being used, falling back to CPU | Run `nvidia-smi` inside container; check CUDA availability |
| "Passthrough causes VM boot hang" | Incompatible GPU or firmware issue | Try updating GPU firmware; try different PCIe slot |

---

## Performance Tuning

### Increase VRAM Usage (if available):

Edit docker-compose.yaml and increase `OLLAMA_NUM_GPU` and model sizes.

### Monitor GPU Usage:

```bash
# Real-time GPU monitoring
watch -n 1 nvidia-smi

# Check which containers are using GPU
docker stats
```

### Model Selection:

- **Fast inference, lower quality**: Mistral 7B (4 GB VRAM)
- **Balanced**: Llama 2 13B (8 GB VRAM)
- **Best quality**: Llama 2 70B (40 GB VRAM, requires high-end GPU)

For YOLO: v8n (nano) fastest, v8m (medium) best accuracy.

---

## Next Steps

1. **HA Integration**: Configure HA to call Ollama and YOLO APIs (see [docs/INTEGRATION_STRATEGY.md](../../docs/INTEGRATION_STRATEGY.md))
2. **Automations**: Create HA automations that trigger AI workflows (see [docs/AI_CAPABILITIES.md](../../docs/AI_CAPABILITIES.md))
3. **Model Fine-tuning**: (Later) Train custom YOLO models on your cameras

---

## Files Referenced

- **Proxmox setup**: [rebuild-proxmox-node.md](rebuild-proxmox-node.md)
- **AI Docker Compose**: [/gpu-node/docker-compose.yaml](../../gpu-node/docker-compose.yaml)
- **Provisioning script**: [/gpu-node/provision-ai-services.sh](../../gpu-node/provision-ai-services.sh)
- **Integration guide**: [/docs/INTEGRATION_STRATEGY.md](../../docs/INTEGRATION_STRATEGY.md)
- **AI capabilities**: [/docs/AI_CAPABILITIES.md](../../docs/AI_CAPABILITIES.md)
