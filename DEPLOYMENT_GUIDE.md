# Docker Deployment Guide

Complete guide for deploying the vegetable detection system using Docker.

## 📋 Prerequisites

### Required
- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Install Docker Compose](https://docs.docker.com/compose/install/)
- **Disk Space**: ~5-10 GB for images
- **RAM**: 4GB minimum (8GB+ recommended)

### Optional (for GPU support)
- **NVIDIA GPU**: Any modern NVIDIA GPU
- **NVIDIA Docker**: [Install nvidia-docker](https://github.com/NVIDIA/nvidia-docker)
- **CUDA Toolkit**: 12.5+ (automatically handled by Docker)

## 🚀 Quick Start

### Option 1: Using Deployment Script (Recommended)

#### On Linux/Mac:
```bash
# Make script executable
chmod +x deploy_docker.sh

# Build GPU image
./deploy_docker.sh build gpu

# Run inference
./deploy_docker.sh run gpu inference ./data/image.jpg

# Start Jupyter for development
./deploy_docker.sh jupyter
```

#### On Windows:
```bash
# Build GPU image
deploy_docker.bat build gpu

# Run inference
deploy_docker.bat run gpu inference

# Start Jupyter
deploy_docker.bat jupyter
```

### Option 2: Using Docker Compose (Best for Multiple Services)

```bash
# Start all services (GPU inference, Jupyter, CPU inference)
docker-compose up -d

# View running services
docker-compose ps

# View logs
docker-compose logs -f gpu-inference

# Stop all services
docker-compose down
```

### Option 3: Manual Docker Commands

```bash
# Build image
docker build -f docker/Dockerfile -t veggie-detection:gpu .

# Run inference
docker run --gpus all \
    -v $(pwd)/data:/data \
    -v $(pwd)/runs:/output \
    veggie-detection:gpu \
    detect predict model=yolov11s.pt source=/data save=True

# Run with Jupyter
docker run --gpus all -p 8888:8888 \
    -v $(pwd):/workspace \
    veggie-detection:gpu \
    jupyter lab --ip=0.0.0.0 --allow-root
```

---

## 🏗️ Deployment Scenarios

### Scenario 1: Development (Jupyter Notebook)

**Use Case**: Experimenting with models, training, evaluation

```bash
# Option A: Using script
./deploy_docker.sh jupyter

# Option B: Using docker-compose
docker-compose up -d jupyter

# Option C: Manual command
docker run --gpus all -p 8888:8888 \
    -v $(pwd)/data:/data \
    -v $(pwd)/notebooks:/workspace/notebooks \
    veggie-detection:jupyter
```

**Access**: http://localhost:8888

**What you can do**:
- Load and visualize images
- Train models interactively
- Test inference
- Create analysis notebooks

---

### Scenario 2: Training on GPU

**Use Case**: Training models on large datasets

```bash
# Using script
./deploy_docker.sh train gpu 100 32
# Trains for 100 epochs with batch size 32

# Using docker-compose
docker-compose run --rm gpu-inference detect train \
    model=yolov11s.yaml data=/data/data.yaml \
    epochs=100 batch=32 device=0

# Manual command
docker run --gpus all \
    -v $(pwd)/data:/data \
    -v $(pwd)/weights:/workspace/weights \
    -v $(pwd)/runs:/workspace/runs \
    veggie-detection:gpu \
    detect train model=yolov11s.yaml data=/data/data.yaml \
        epochs=100 batch=32 device=0
```

**Important**:
- Ensure `data/data.yaml` exists with your dataset configuration
- Mount both input data and output directories
- Use persistent volumes for checkpoints

---

### Scenario 3: Inference (Production)

**Use Case**: Running predictions on images/videos

#### GPU Deployment:
```bash
# Quick inference
./deploy_docker.sh run gpu inference ./my_image.jpg

# Batch processing
docker run --gpus all \
    -v $(pwd)/images:/data \
    -v $(pwd)/results:/output \
    veggie-detection:gpu \
    detect predict model=yolov11s.pt source=/data \
        save=True project=/output
```

#### CPU Deployment (Cost-effective):
```bash
# Build CPU image first
./deploy_docker.sh build cpu

# Run inference
./deploy_docker.sh run cpu inference ./my_image.jpg

# Or manually
docker run \
    -v $(pwd)/images:/input \
    -v $(pwd)/results:/output \
    veggie-detection:cpu \
    detect predict model=yolov11s.pt source=/input \
        save=True project=/output
```

---

### Scenario 4: Edge Devices (Jetson/ARM)

**Use Case**: Deploying on NVIDIA Jetson or ARM devices

#### NVIDIA Jetson:
```bash
# Build Jetson image
./deploy_docker.sh build jetson

# Run inference
docker run --runtime nvidia \
    -v $(pwd)/data:/data \
    veggie-detection:jetson \
    detect predict model=yolov11s.pt source=/data
```

#### ARM64 (Raspberry Pi 4):
```bash
# Build ARM image
docker build -f docker/Dockerfile-arm64 -t veggie:arm64 .

# Run inference
docker run -v $(pwd)/data:/data veggie:arm64 \
    detect predict model=yolov11s.pt source=/data
```

---

### Scenario 5: Model Export

**Use Case**: Converting models to deployment-friendly formats

```bash
# Export to ONNX
./deploy_docker.sh export onnx

# Export to TensorRT
docker run --gpus all \
    -v $(pwd)/weights:/weights \
    veggie-detection:export \
    yolo detect export model=/weights/best.pt format=engine

# Export to TFLite (mobile)
docker run \
    -v $(pwd)/weights:/weights \
    veggie-detection:export \
    yolo detect export model=/weights/best.pt format=tflite imgsz=320

# Export multiple formats
docker run --gpus all \
    -v $(pwd)/weights:/weights \
    veggie-detection:export \
    yolo detect export model=/weights/best.pt format=onnx,engine,openvino,tflite
```

---

## 📊 Using Docker Compose

### Basic Workflow

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View specific service logs
docker-compose logs gpu-inference

# Stop all services
docker-compose down

# Remove volumes (clean up)
docker-compose down -v
```

### Services Included

1. **gpu-inference**: GPU-accelerated inference
2. **cpu-inference**: CPU inference (lightweight)
3. **jupyter**: Interactive development environment
4. **export**: Model export tools

### Customizing Services

Edit `docker-compose.yml` to:
- Change port mappings
- Adjust resource limits
- Add environment variables
- Include additional services (PostgreSQL, MLflow, etc.)

---

## 🔧 Configuration

### Using Environment Variables

Create `.env` file from template:

```bash
cp .env.example .env
# Edit .env with your settings
```

Common settings:
```bash
# Model and inference
MODEL=yolov11s.pt
CONFIDENCE=0.5
IMAGE_SIZE=640
BATCH_SIZE=32

# Paths (relative to project root)
DATA_PATH=./data
WEIGHTS_PATH=./weights
OUTPUT_PATH=./runs

# GPU settings
CUDA_VISIBLE_DEVICES=0
NVIDIA_DRIVER_CAPABILITIES=compute,utility
```

### Mount Volumes

**Data volumes** for docker run:
```bash
-v /path/to/images:/data              # Input data
-v /path/to/output:/output            # Results
-v /path/to/weights:/weights          # Models
-v /path/to/notebooks:/notebooks      # Jupyter files
```

---

## 🎯 Common Tasks

### Task 1: Batch Inference on 1000 Images

```bash
docker run --gpus all \
    -v /large/image/directory:/input \
    -v $(pwd)/results:/output \
    veggie-detection:gpu \
    detect predict model=yolov11s.pt source=/input \
        save=True save_txt=True project=/output
```

**Time estimate**: ~30-60 seconds (depending on GPU)

### Task 2: Video Processing

```bash
docker run --gpus all \
    -v $(pwd)/videos:/input \
    -v $(pwd)/results:/output \
    veggie-detection:gpu \
    detect predict model=yolov11s.pt \
        source=/input/video.mp4 \
        save=True project=/output
```

### Task 3: Real-time Webcam Inference

```bash
# Requires special setup - not straightforward in container
# Better to use host machine with:
# yolo detect predict model=yolov11s.pt source=0
```

### Task 4: Training with Data Validation

```bash
docker run --gpus all \
    -v $(pwd)/data:/data \
    -v $(pwd)/weights:/workspace/weights \
    -v $(pwd)/runs:/workspace/runs \
    veggie-detection:gpu \
    detect train model=yolov11s.yaml \
        data=/data/data.yaml \
        epochs=100 batch=32 \
        patience=20 val=True
```

### Task 5: Multi-GPU Training

```bash
docker run --gpus all \
    -v $(pwd)/data:/data \
    -v $(pwd)/weights:/workspace/weights \
    -v $(pwd)/runs:/workspace/runs \
    veggie-detection:gpu \
    detect train model=yolov11s.yaml \
        data=/data/data.yaml \
        epochs=100 batch=64 \
        device=0,1  # Use GPUs 0 and 1
```

---

## 📈 Performance Tips

### Maximize Inference Speed

1. **GPU**: Use batch processing
   ```bash
   docker run --gpus all ... \
       detect predict source=/images batch=32
   ```

2. **CPU**: Reduce image size
   ```bash
   docker run ... \
       detect predict source=/images imgsz=416
   ```

3. **Memory**: Use model export
   ```bash
   # ONNX is faster than PyTorch
   docker run ... yolo export format=onnx
   ```

### Reduce Memory Usage

```bash
# Use half-precision (FP16)
docker run ... detect predict half=True

# Reduce image size
docker run ... detect predict imgsz=416

# Use lighter model
docker run ... detect predict model=yolov11n.pt
```

### Optimize for Edge Devices

```bash
# Export to TFLite on device with size=320
docker run ... yolo detect export \
    model=best.pt format=tflite imgsz=320

# Or use distilled model
docker run ... detect predict \
    model=yolov11s-GhostECA-distill.pt
```

---

## 🐛 Troubleshooting

### GPU Not Detected

```bash
# Verify GPU support
docker run --rm --gpus all nvidia/cuda:12.5.0-base-ubuntu22.04 nvidia-smi

# If failed, check Docker daemon config
cat /etc/docker/daemon.json

# Should contain:
# {
#   "runtimes": {
#     "nvidia": {...}
#   }
# }
```

### Out of Memory Error

```bash
# Solution 1: Reduce batch size
docker run ... detect train batch=16

# Solution 2: Reduce image size
docker run ... detect train imgsz=416

# Solution 3: Enable mixed precision
docker run ... detect train amp=True
```

### Permission Denied Writing Volumes

```bash
# Run with user permissions
docker run --user $(id -u):$(id -g) ... veggie-detection:gpu

# Or make directories writable
chmod 777 ./runs ./weights
```

### Image Size Too Large

```bash
# Use CPU-only image
docker build -f docker/Dockerfile-cpu -t veggie:small .

# Or use minimal Python image
docker build -f docker/Dockerfile-python -t veggie:minimal .
```

---

## 📚 Resources

- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Docker Guide](https://github.com/NVIDIA/nvidia-docker)
- [Ultralytics Docs](https://docs.ultralytics.com)
- [Jetson Docker Documentation](https://docs.nvidia.com/deeplearning/jetson/jetson-container-runtime-guide/)

---

## ✅ Verification Checklist

- [ ] Docker installed: `docker --version`
- [ ] Docker Compose installed: `docker-compose --version`
- [ ] GPU support working: `docker run --rm --gpus all nvidia/cuda:12.5.0-base-ubuntu22.04 nvidia-smi`
- [ ] Image built successfully: `docker images | grep veggie`
- [ ] Data directory exists: `ls -la data/`
- [ ] Output directory writable: `touch runs/.test && rm runs/.test`
- [ ] First inference runs: `./deploy_docker.sh run gpu inference`

---

<div align="center">

**Docker deployment configured successfully! 🚀**

For questions or issues, see [GitHub Issues](https://github.com/Phan-Trung-Thuan/vegetable-detection/issues)

</div>
