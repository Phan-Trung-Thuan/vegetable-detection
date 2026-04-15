# Docker Deployment Guide for Vegetable Detection

This directory contains Docker configurations for deploying the vegetable detection system across different platforms and use cases.

## 📋 Available Dockerfiles

### **GPU Deployment (NVIDIA CUDA)**

#### `Dockerfile` - Production GPU Image
- **Best for**: Production deployment on NVIDIA GPUs
- **Base**: PyTorch CUDA 12.8 with cuDNN
- **GPU Support**: Full CUDA, TensorRT optimization
- **Use case**: Data centers, cloud GPU instances

```bash
docker build -f docker/Dockerfile -t veggie-detection:gpu .
docker run --gpus all \
    -v $(pwd)/data:/data \
    -v $(pwd)/weights:/workspace/weights \
    -v $(pwd)/runs:/workspace/runs \
    veggie-detection:gpu \
    detect predict model=yolov11s.pt source=/data/image.jpg
```

---

### **CPU Deployment**

#### `Dockerfile-cpu` - CPU-Only Image
- **Best for**: Deployments without GPU (cost-effective)
- **Base**: Ubuntu 22.04 with PyTorch CPU
- **Size**: Smaller than GPU images
- **Use case**: Laptops, servers without GPU, edge devices with limited resources

```bash
docker build -f docker/Dockerfile-cpu -t veggie-detection:cpu .
docker run -v $(pwd)/data:/data veggie-detection:cpu \
    detect predict model=yolov11s.pt source=/data/image.jpg
```

---

### **Edge/Embedded Deployment**

#### `Dockerfile-jetson-jetpack5` - NVIDIA Jetson (JetPack 5)
- **Best for**: NVIDIA Jetson devices (Nano, Xavier, Orin)
- **Optimized for**: JetPack 5.x systems
- **Performance**: Optimized inference on edge hardware
- **Use case**: Robotics, autonomous systems, IoT

```bash
docker build -f docker/Dockerfile-jetson-jetpack5 -t veggie-detection:jetson .
docker run --runtime nvidia \
    -v $(pwd)/data:/data \
    veggie-detection:jetson \
    detect predict model=yolov11s.pt source=/data/image.jpg
```

#### `Dockerfile-jetson-jetpack4` - NVIDIA Jetson (JetPack 4)
- **Best for**: Older NVIDIA Jetson devices
- **Legacy support**: JetPack 4.x systems

#### `Dockerfile-jetson-jetpack6` - NVIDIA Jetson (JetPack 6)
- **Best for**: Latest NVIDIA Jetson devices
- **Latest support**: JetPack 6.x systems

#### `Dockerfile-arm64` - ARM 64-bit Architecture
- **Best for**: ARM-based single-board computers
- **Platforms**: Raspberry Pi 4 (64-bit), other ARM64 systems
- **No GPU**: Standard inference only

```bash
docker build -f docker/Dockerfile-arm64 -t veggie-detection:arm64 .
docker run -v $(pwd)/data:/data veggie-detection:arm64 \
    detect predict model=yolov11s.pt source=/data/image.jpg
```

#### `Dockerfile-nvidia-arm64` - ARM64 with NVIDIA GPU Support
- **Best for**: ARM-based systems with NVIDIA GPU (e.g., Jetson Orin)
- **GPU Support**: NVIDIA drivers on ARM architecture

---

### **Development & Notebook**

#### `Dockerfile-jupyter` - Jupyter Notebook Environment
- **Best for**: Interactive development and experimentation
- **Features**: Jupyter Lab, all dependencies, visualization tools
- **Use case**: Training, prototyping, data exploration

```bash
docker build -f docker/Dockerfile-jupyter -t veggie-detection:jupyter .
docker run --gpus all -p 8888:8888 \
    -v $(pwd)/data:/data \
    -v $(pwd)/notebooks:/workspace/notebooks \
    veggie-detection:jupyter
# Access: http://localhost:8888
```

#### `Dockerfile-python` - Basic Python Environment
- **Best for**: Lightweight development environment
- **Minimal**: Python + ultralytics only
- **Use case**: Custom script development, testing

```bash
docker build -f docker/Dockerfile-python -t veggie-detection:python .
docker run -v $(pwd)/data:/data veggie-detection:python python script.py
```

---

### **Model Export & Conversion**

#### `Dockerfile-export` - Model Export Tools
- **Best for**: Converting models to different formats (ONNX, TensorRT, OpenVINO, TFLite)
- **Includes**: All export dependencies
- **Use case**: Model optimization, cross-platform deployment

```bash
docker build -f docker/Dockerfile-export -t veggie-detection:export .
docker run -v $(pwd)/weights:/weights veggie-detection:export \
    yolo detect export model=/weights/best.pt format=onnx imgsz=640
```

#### `Dockerfile-python-export` - Python + Export Tools
- **Best for**: Custom export scripts with full Python environment
- **Use case**: Advanced export workflows

---

### **Production Server**

#### `Dockerfile-runner` - Lightweight Production Runner
- **Best for**: Production inference servers
- **Minimal footprint**: Optimized for deployment
- **Use case**: REST API, batch inference services

```bash
docker build -f docker/Dockerfile-runner -t veggie-detection:runner .
docker run --gpus all -p 8000:8000 \
    -v $(pwd)/weights:/weights \
    veggie-detection:runner
```

#### `Dockerfile-conda` - Conda-Based Environment
- **Best for**: Environments requiring conda for package management
- **Package management**: Full conda ecosystem
- **Use case**: Complex dependencies, reproducible environments

```bash
docker build -f docker/Dockerfile-conda -t veggie-detection:conda .
docker run -v $(pwd)/data:/data veggie-detection:conda \
    yolo detect predict model=yolov11s.pt source=/data/image.jpg
```

---

## 🚀 Quick Start

### Building Images

```bash
cd vegetable-detection

# GPU (default, recommended for production)
docker build -f docker/Dockerfile -t veggie:gpu .

# CPU only
docker build -f docker/Dockerfile-cpu -t veggie:cpu .

# Jetson
docker build -f docker/Dockerfile-jetson-jetpack5 -t veggie:jetson .

# Jupyter (development)
docker build -f docker/Dockerfile-jupyter -t veggie:jupyter .
```

### Running Containers

```bash
# Inference on GPU
docker run --gpus all -v $(pwd)/data:/data veggie:gpu \
    detect predict model=yolov11s.pt source=/data/image.jpg save=True

# Training on GPU
docker run --gpus all -v $(pwd)/data:/data veggie:gpu \
    detect train model=yolov11s.yaml data=/data/data.yaml epochs=100 batch=32

# Jupyter (interactive)
docker run --gpus all -p 8888:8888 veggie:jupyter

# CPU inference
docker run -v $(pwd)/data:/data veggie:cpu \
    detect predict model=yolov11s.pt source=/data/image.jpg
```

---

## 📦 Using Docker Compose

See `docker-compose.yml` for **multi-container orchestration** with:
- GPU inference service
- Jupyter development environment
- Data volume management
- Easy service coordination

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

---

## 🔧 Common Usage Patterns

### Pattern 1: Batch Inference
```bash
docker run --gpus all \
    -v /path/to/images:/data \
    -v /path/to/output:/output \
    veggie:gpu \
    detect predict model=yolov11s.pt source=/data save=True project=/output
```

### Pattern 2: Video Processing
```bash
docker run --gpus all \
    -v /path/to/video.mp4:/data/video.mp4 \
    -v /path/to/output:/output \
    veggie:gpu \
    detect predict model=yolov11s.pt source=/data/video.mp4 save=True project=/output
```

### Pattern 3: Model Training
```bash
docker run --gpus all \
    -v $(pwd)/data:/data \
    -v $(pwd)/weights:/workspace/weights \
    veggie:gpu \
    detect train model=yolov11s.yaml data=/data/data.yaml epochs=100 device=0,1
```

### Pattern 4: Model Export
```bash
docker run --gpus all \
    -v $(pwd)/weights:/weights \
    veggie:export \
    yolo detect export model=/weights/best.pt format=onnx,engine imgsz=640
```

---

## 📊 Dockerfile Comparison

| Dockerfile | Base Image | GPU | Size | Use Case |
|-----------|-----------|-----|------|----------|
| Dockerfile | PyTorch CUDA | ✅ | ~4.5GB | Production GPU |
| Dockerfile-cpu | Ubuntu | ❌ | ~2GB | CPU Inference |
| Dockerfile-jetson-* | Jetson JetPack | ✅ | ~3GB | Jetson Devices |
| Dockerfile-arm64 | Ubuntu ARM | ❌ | ~1.5GB | Raspberry Pi |
| Dockerfile-jupyter | Jupyter + PyTorch | ✅ | ~5GB | Development |
| Dockerfile-python | Python | ❌ | ~1GB | Minimal |
| Dockerfile-export | Export Tools | ✅ | ~4GB | Model Export |
| Dockerfile-runner | Lightweight | ✅ | ~3GB | Production |
| Dockerfile-conda | Conda + PyTorch | ✅ | ~4GB | Conda Users |

---

## 🎯 Platform Selection Guide

### **I need GPU inference**
→ Use `Dockerfile`

### **I need CPU-only deployment**
→ Use `Dockerfile-cpu`

### **I'm using NVIDIA Jetson**
→ Use `Dockerfile-jetson-jetpack5` (or jetpack4/6)

### **I'm using Raspberry Pi or ARM board**
→ Use `Dockerfile-arm64`

### **I want to experiment/develop**
→ Use `Dockerfile-jupyter`

### **I need to export models**
→ Use `Dockerfile-export`

### **I want minimal image size**
→ Use `Dockerfile-python`

### **I need production inference server**
→ Use `Dockerfile-runner`

---

## 📝 Volume Mounting Best Practices

```bash
# Essential volumes:
-v /path/to/data:/data              # Input images/videos
-v /path/to/output:/output          # Output predictions
-v /path/to/weights:/weights        # Model checkpoints

# Development volumes:
-v /path/to/code:/workspace         # Source code (dev)
-v /path/to/notebooks:/notebooks    # Jupyter notebooks
-v /path/to/logs:/workspace/runs    # Training logs
```

---

## 🔍 Troubleshooting

### GPU not detected in container
```bash
# Check Docker is configured for GPU
docker run --rm --gpus all nvidia/cuda:12.5.0-base-ubuntu22.04 nvidia-smi

# Ensure you have nvidia-docker or proper Docker daemon config
```

### Permission issues with volumes
```bash
# Run with user permissions
docker run --user $(id -u):$(id -g) \
    -v /path/to/data:/data veggie:gpu detect predict ...
```

### Out of memory
```bash
# Reduce batch size
docker run --gpus all veggie:gpu detect train batch=16 imgsz=416

# Or limit memory
docker run --gpus all -m 8g veggie:gpu detect predict ...
```

### Image size too large
```bash
# Use smaller base image
docker build -f Dockerfile-cpu -t veggie:small .
docker build -f Dockerfile-python -t veggie:minimal .
```

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Docker Documentation](https://github.com/NVIDIA/nvidia-docker)
- [Ultralytics Documentation](https://docs.ultralytics.com)
- [Jetson Docker Guide](https://github.com/dusty-nv/jetson-containers)

---

## 💡 Tips for Production

1. **Security**: Don't mount sensitive data without read-only flags
2. **Logging**: Capture container logs for monitoring
3. **Resource limits**: Set memory and CPU limits
4. **Health checks**: Implement health check endpoints
5. **Tags**: Use semantic versioning for images
6. **Registry**: Push images to Docker Hub or private registry

```bash
# Example with tags and registries
docker tag veggie:gpu myregistry.azurecr.io/veggie:v1.0.0-gpu
docker push myregistry.azurecr.io/veggie:v1.0.0-gpu
```

---

<div align="center">

**Choose the right Dockerfile for your deployment platform!**

For questions, see our [GitHub Issues](https://github.com/Phan-Trung-Thuan/vegetable-detection/issues)

</div>
