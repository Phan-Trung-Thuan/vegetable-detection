from ultralytics import YOLO

MODEL_PATH = 'yolov10n.pt'
IMAGE_PATH = 'VnVeggie/test/images/IMG_20220916_062758_jpg.rf.363a5eeed2f8cd276dc2211c97fc1c17.jpg'
if __name__ == '__main__':
    model = YOLO(MODEL_PATH)

    # Validate results on runs\detect\val
    results = model.val(data='VnVeggie/data.yaml', imgsz=640, batch=16, workers=4, visualize=True)

    print(results)

    # Predict and visualize on runs\detect\predict
    model.predict(IMAGE_PATH, save=True, imgsz=640, conf=0.5, visualize=True)