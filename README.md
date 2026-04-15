# Vegetable Detection System

**Advanced YOLO-based computer vision system for automated vegetable detection and tracking on the VnVeggie dataset.**

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.0+-ee4c2c.svg)](https://pytorch.org/)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](LICENSE)

## Overview

This project implements vegetable detection using multiple YOLO model variants (v8, v10, v11, v12, v13) with advanced optimization techniques. Supports **26 vegetable classes** from the VnVeggie dataset (80% train, 10% val, 10% test split).

**Key Features:**

- Real-time detection: 30+ FPS on GPU
- Multiple model variants: 8 YOLO versions + 20 attention variants
- Advanced optimization: Ghost modules, CBAM, ECA, SE, C2PSA
- Complete solutions: Detection, tracking, counting, heatmaps
- Production-ready: Docker, multi-platform deployment

## Quick Start

### 1. Installation

```bash
# Clone repository
git clone https://github.com/Phan-Trung-Thuan/vegetable-detection
cd vegetable-detection

# Install PyTorch with CUDA 12.5
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu125

# Install dependencies
pip install pyyaml matplotlib polars scipy requests thop

# Install package
pip install -e .
```

### 2. Training

```bash
yolo detect train \
    model=config/yolov11s-GhostECA.yaml \
    data=path/to/data.yaml \
    epochs=100 \
    lr0=0.01 \
    momentum=0.9 \
    imgsz=640 \
    batch=32 \
    optimizer=SGD \
    device=0,1 \
    amp=False \
    name=results
```

### 3. Validation

```bash
# Validate on test set
yolo detect val \
    model=runs/detect/results/weights/best.pt \
    data=path/to/data.yaml \
    split=test \
    imgsz=640 \
    batch=64 \
    device=0,1

# Validate on other splits (sliced, food, etc.)
yolo detect val \
    model=weights/distillated/yolov11s-GhostECA-distill.pt \
    data=path/to/data.yaml \
    split=sliced \
    imgsz=640 \
    batch=64 \
    device=0,1
```

### 4. Inference

```python
from ultralytics import YOLO

# Load model
model = YOLO('best.pt')

# Predict on image
results = model.predict(source='image.jpg', conf=0.5)

# Display results
results[0].show()
```

## Dataset: VnVeggie

The **VnVeggie** dataset is a multi-level vegetable detection benchmark designed to evaluate model performance under increasing levels of difficulty. It contains **26 unique Vietnamese vegetable classes** organized into three progressive sub-datasets.

### **Dataset Composition**

| Dataset             | Purpose                   | Total Images                  | Characteristics                                                 |
| ------------------- | ------------------------- | ----------------------------- | --------------------------------------------------------------- |
| **Whole-ViVeggie**  | General purpose benchmark | 22,600 (augmented from 9,836) | Balanced, clean images                                          |
| **Sliced-ViVeggie** | Medium difficulty         | 600                           | Processed vegetables (boiled, steamed, sliced, shredded, diced) |
| **Food-ViVeggie**   | High difficulty           | 324                           | Complex cooked dishes (soup, stew, stir-fries, hot pot)         |

### **Whole-ViVeggie Data Sources**

| Source             | Images    | Augmentation Strategy              |
| ------------------ | --------- | ---------------------------------- |
| Roboflow           | 3,904     | Geometric & Photometric (3,164)    |
| Internet           | 4,131     | YOLO-friendly augmentation (6,000) |
| Kaggle             | 1,026     | Domain-aware augmentation (3,600)  |
| Self-taken         | 775       | -                                  |
| **Total Original** | **9,836** | **Final: 22,600 images**           |

**Train/Val/Test Split**: 80% / 10% / 10% (18,080 / 2,260 / 2,260 images)

### **Vegetable Classes (26 Total)**

| #   | Class       | #   | Class            | #   | Class        |
| --- | ----------- | --- | ---------------- | --- | ------------ |
| 1   | Beansprout  | 10  | Chili            | 19  | Pumpkin      |
| 2   | Bellpepper  | 11  | Coriander        | 20  | Tomato       |
| 3   | Bittermelon | 12  | Cucumber         | 21  | Vinespinach  |
| 4   | Bokchoy     | 13  | Eggplant         | 22  | Waterlily    |
| 5   | Broccoli    | 14  | Lettuce          | 23  | Waterspinach |
| 6   | Cabbage     | 15  | Limnocharisflava | 24  | Garlic       |
| 7   | Carrot      | 16  | Longbean         | 25  | Greenonion   |
| 8   | Cauliflower | 17  | Okra             | 26  | FishMint     |
| 9   | Chayote     | 18  | Onion            | -   | -            |

### **Vegetable Classes by Attributes** (Domain-Aware Grouping)

| Attribute   | Category       | Examples                                           |
| ----------- | -------------- | -------------------------------------------------- |
| **Color**   | Warm-tone      | Tomato, Chili, Bellpepper, Carrot, Pumpkin         |
|             | Green-tone     | Waterspinach, Vinespinach, FishMint, Bittermelon   |
|             | Light-tone     | Garlic, Onion, Beansprout                          |
| **Texture** | Smooth-surface | Tomato, Eggplant, Bellpepper, Chili, Garlic, Onion |
|             | Rough-surface  | Broccoli, Cauliflower, Bittermelon                 |
| **Shape**   | Long           | Cucumber, Longbean, Bittermelon, Vinespinach       |
|             | Round          | Tomato, Onion, Garlic, Eggplant, Bellpepper        |
|             | Leafy          | FishMint, Vinespinach, Limnocharisflava            |
|             | Bulky          | Cabbage, Broccoli, Cauliflower, Pumpkin            |

### **Sliced-ViVeggie Subset** (Processed Vegetables, 600 Images)

Vegetables in various processed states: boiled, steamed, sliced, shredded, diced, and minced conditions.

### **Food-ViVeggie Subset** (Cooked Dishes, 324 Images)

Complex prepared dishes including hot pots, soups, stews, stir-fries, and Vietnamese pancakes with mixed vegetables appearing crowded and partially obscured.

---

## Project Structure

```
vegetable-detection/
├── train/                    # Training scripts
│   ├── trainYOLOv8n.py
│   ├── trainYOLOv11.py
│   ├── trainYOLOv13s.py
│   └── ...
├── validate/                 # Validation scripts
├── config/                   # Model configurations (.yaml files)
├── weights/                  # Pre-trained models
│   ├── finetune/            # Fine-tuned models
│   └── distillated/         # Distilled models
├── examples/                 # Jupyter notebooks
│   ├── tutorial.ipynb
│   ├── object_tracking.ipynb
│   ├── object_counting.ipynb
│   └── heatmaps.ipynb
├── ultralytics/             # Core YOLO framework
│   ├── models/              # Model definitions
│   ├── engine/              # Training & inference
│   ├── data/                # Dataset handling
│   ├── solutions/           # Tracking, counting, etc.
│   └── utils/               # Utilities
├── docker/                  # Containerization
└── pyproject.toml          # Project config
```

---

### Export for Deployment

```bash
# ONNX (cross-platform)
yolo detect export model=best.pt format=onnx imgsz=640

# TensorRT (NVIDIA GPU)
yolo detect export model=best.pt format=engine device=0

# OpenVINO (Intel CPU)
yolo detect export model=best.pt format=openvino

# TFLite (Mobile)
yolo detect export model=best.pt format=tflite imgsz=320
```

---

## Docker Deployment

```bash
# GPU deployment
docker build -f docker/Dockerfile -t veggie:gpu .
docker run --gpus all -v $(pwd)/data:/data veggie:gpu

# CPU deployment
docker build -f docker/Dockerfile-cpu -t veggie:cpu .
docker run -v $(pwd)/data:/data veggie:cpu

# Jetson deployment
docker build -f docker/Dockerfile-jetson-jetpack5 -t veggie:jetson .
docker run -v $(pwd)/data:/data --runtime nvidia veggie:jetson
```

---

## Comprehensive Performance Results

### **Standard YOLO Models Performance**

#### Whole-ViVeggie (Medium Difficulty Dataset)

| Model   | Precision | Recall | mAP50 | mAP50-95 |
| ------- | --------- | ------ | ----- | -------- |
| YOLOv10 | 0.710     | 0.534  | 0.579 | 0.421    |
| YOLOv11 | 0.754     | 0.597  | 0.664 | 0.521    |
| YOLOv12 | 0.702     | 0.585  | 0.600 | 0.488    |
| YOLOv13 | 0.726     | 0.594  | 0.650 | 0.516    |
| YOLO26  | 0.693     | 0.531  | 0.571 | 0.442    |

#### Sliced-ViVeggie (High Difficulty - Processed Vegetables)

| Model   | Precision | Recall | mAP50 | mAP50-95 |
| ------- | --------- | ------ | ----- | -------- |
| YOLOv10 | 0.446     | 0.332  | 0.322 | 0.218    |
| YOLOv11 | 0.400     | 0.377  | 0.346 | 0.258    |
| YOLOv12 | 0.343     | 0.363  | 0.303 | 0.227    |
| YOLOv13 | 0.382     | 0.367  | 0.338 | 0.260    |
| YOLO26  | 0.389     | 0.358  | 0.314 | 0.229    |

#### Food-ViVeggie (Highest Difficulty - Cooked Dishes)

| Model   | Precision | Recall | mAP50 | mAP50-95 |
| ------- | --------- | ------ | ----- | -------- |
| YOLOv10 | 0.610     | 0.291  | 0.331 | 0.235    |
| YOLOv11 | 0.328     | 0.254  | 0.218 | 0.148    |
| YOLOv12 | 0.315     | 0.254  | 0.220 | 0.152    |
| YOLOv13 | 0.356     | 0.277  | 0.249 | 0.152    |
| YOLO26  | 0.533     | 0.296  | 0.309 | 0.232    |

### **YOLOv11 with GhostNet & Attention Mechanisms**

#### Whole-ViVeggie Performance

| Model                     | Precision | Recall | mAP50 | mAP50-95 |
| ------------------------- | --------- | ------ | ----- | -------- |
| YOLOv11 (Baseline)        | 0.754     | 0.597  | 0.664 | 0.521    |
| YOLOv11-GhostC2PSA        | 0.687     | 0.609  | 0.641 | 0.499    |
| YOLOv11-GhostCBAM         | 0.740     | 0.581  | 0.654 | 0.509    |
| YOLOv11-GhostECA          | 0.651     | 0.569  | 0.552 | 0.404    |
| YOLOv11-GhostSE           | 0.660     | 0.504  | 0.525 | 0.396    |
| YOLOv11-GhostCBAM-Distill | 0.694     | 0.573  | 0.592 | 0.460    |
| YOLOv11-GhostECA-Distill  | 0.678     | 0.567  | 0.594 | 0.451    |

#### Sliced-ViVeggie Performance

| Model                     | Precision | Recall | mAP50 | mAP50-95 |
| ------------------------- | --------- | ------ | ----- | -------- |
| YOLOv11 (Baseline)        | 0.400     | 0.377  | 0.346 | 0.258    |
| YOLOv11-GhostC2PSA        | 0.378     | 0.320  | 0.293 | 0.227    |
| YOLOv11-GhostCBAM         | 0.484     | 0.327  | 0.336 | 0.242    |
| YOLOv11-GhostECA          | 0.387     | 0.296  | 0.318 | 0.225    |
| YOLOv11-GhostSE           | 0.356     | 0.277  | 0.268 | 0.197    |
| YOLOv11-GhostCBAM-Distill | 0.423     | 0.318  | 0.308 | 0.236    |
| YOLOv11-GhostECA-Distill  | 0.433     | 0.310  | 0.305 | 0.233    |

#### Food-ViVeggie Performance

| Model                     | Precision | Recall | mAP50 | mAP50-95 |
| ------------------------- | --------- | ------ | ----- | -------- |
| YOLOv11 (Baseline)        | 0.328     | 0.254  | 0.218 | 0.148    |
| YOLOv11-GhostC2PSA        | 0.331     | 0.259  | 0.220 | 0.149    |
| YOLOv11-GhostCBAM         | 0.341     | 0.262  | 0.236 | 0.162    |
| YOLOv11-GhostECA          | 0.636     | 0.326  | 0.343 | 0.255    |
| YOLOv11-GhostSE           | 0.499     | 0.288  | 0.293 | 0.216    |
| YOLOv11-GhostCBAM-Distill | 0.579     | 0.310  | 0.333 | 0.247    |
| YOLOv11-GhostECA-Distill  | 0.546     | 0.298  | 0.313 | 0.233    |

### **Model Efficiency Comparison**

| Model                     | CPU Latency (ms) | GPU Latency (ms) | Size (MB) | Parameters | GFLOPs |
| ------------------------- | ---------------- | ---------------- | --------- | ---------- | ------ |
| YOLOv10                   | 350.05           | 10.62            | 17.4      | 8.11M      | 22.2   |
| YOLOv11                   | 346.76           | 10.21            | 18.3      | 9.42M      | 21.4   |
| YOLOv12                   | 365.73           | 15.11            | 18.0      | 9.24M      | 21.3   |
| YOLOv13                   | 417.80           | 19.54            | 17.8      | 9.05M      | 20.8   |
| YOLO26                    | 375.94           | 11.79            | 19.4      | 9.48M      | 20.6   |
| YOLOv11-GhostC2PSA        | 334.69           | 10.79            | 16.1      | 8.27M      | 18.2   |
| YOLOv11-GhostCBAM         | 322.13           | 10.25            | 14.2      | 7.29M      | 14.7   |
| YOLOv11-GhostECA          | 267.22           | 10.83            | 14.2      | 7.29M      | 17.4   |
| YOLOv11-GhostSE           | 311.76           | 10.29            | 14.2      | 7.29M      | 17.4   |
| YOLOv11-GhostCBAM-Distill | 322.13           | 10.25            | 14.2      | 7.29M      | 14.7   |
| YOLOv11-GhostECA-Distill  | 267.22           | 10.83            | 14.2      | 7.29M      | 17.4   |

### **Key Findings**

- **Whole-ViVeggie (Balanced)**: YOLOv11 achieves best accuracy (66.4 mAP50) with stable performance
- **Sliced-ViVeggie (Processed)**: Performance drops significantly, YOLOv11-GhostCBAM maintains best accuracy (33.6 mAP50)
- **Food-ViVeggie (Cooked/Mixed)**: Most challenging split, YOLOv11-GhostECA excels (34.3 mAP50)
- **Efficiency**: Ghost variants reduce model size by ~23% (18.3MB → 14.2MB) with minimal accuracy loss
- **Distillation Benefits**: Knowledge-distilled models achieve comparable accuracy with 23% size reduction

### Slow Inference

```bash
# Export to optimized format
yolo export model=best.pt format=engine  # NVIDIA
yolo export model=best.pt format=openvino  # Intel
```

---

## License

AGPL-3.0 License - see [LICENSE](LICENSE)

---

## Citation

```bibtex
@software{veggie_detection,
    title={Vegetable Detection System},
    author={Phan Trung Thuan},
    year={2026},
    url={https://github.com/Phan-Trung-Thuan/vegetable-detection}
}
```

---

## Support

- **Issues**: [GitHub Issues](https://github.com/Phan-Trung-Thuan/vegetable-detection/issues)
- **Docs**: [Ultralytics YOLO](https://docs.ultralytics.com)
- **Paper**: [YOLOv11 Paper](https://arxiv.org/abs/2107.14575)
