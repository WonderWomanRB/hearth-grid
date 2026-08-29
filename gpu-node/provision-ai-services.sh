#!/usr/bin/env bash
set -euo pipefail

echo "[gpu-node] Creating data directories..."
mkdir -p data/ollama
mkdir -p data/yolo

echo "[gpu-node] Starting AI services with docker-compose..."
docker compose up -d

echo "[gpu-node] Waiting for containers to stabilize..."
sleep 10

echo "[gpu-node] Checking Ollama..."
curl -s http://localhost:11434/api/tags || echo "Ollama not responding yet"

echo "[gpu-node] Checking YOLO API..."
curl -s http://localhost:8000/health || echo "YOLO API not responding yet"

echo "[gpu-node] Done. Verify GPU usage with: nvidia-smi"
