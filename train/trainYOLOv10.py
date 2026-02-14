# Python 3.14.2
"""
Pip install: 
1. pip install opencv-python
2.1 (If GPU): pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126
2.2 (If CPU): pip install torch torchvision
3. pip install pyyaml
4. pip install matplotlib
5. pip install polars
6. pip install scipy
7. pip install requests
8. pip install thop
"""

import sys
sys.path.append("/kaggle/working/vegetable-detection")

from ultralytics import YOLO
import torch

if __name__ == '__main__':
    if torch.cuda.is_available():
        print("GPU is available")
    else:
        print("CPU only")

    # Load yaml model configuration file
    model = YOLO("yolov10n.yaml").load("yolov10n.pt") 

    # Set dataset yaml path here
    dataset_path = "/kaggle/input/vnveggie/data.yaml" 

    # Train the model (Config workers according to CPU/GPU capability/can cause crashes if set too high)
    # Link params: https://docs.ultralytics.com/modes/train/
    model.train(data=dataset_path, epochs=200, lr0=0.01, momentum=0.9, patience=40, optimizer="SGD", imgsz=640, batch=16, workers=4 , name="yolov10n_vnveggie", amp=False)
