"""TribeLens: classify traditional attire with the Teachable Machine model.

Usage:
    python predict.py path\to\image.jpg      (one image)
    python predict.py path\to\folder         (every image in a folder)
"""
import os
import sys

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")  # quieter TensorFlow logs

import numpy as np
from PIL import Image, ImageOps
from tensorflow.keras.models import load_model

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(HERE, "keras_model.h5")
LABELS_PATH = os.path.join(HERE, "labels.txt")
IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".bmp", ".webp")


def load_labels(path):
    labels = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                parts = line.split(" ", 1)
                name = parts[1] if len(parts) == 2 and parts[0].isdigit() else line
                labels.append(name.split()[0])  # keep only the tribe name
    return labels


def prepare(image_path):
    image = Image.open(image_path).convert("RGB")
    image = ImageOps.fit(image, (224, 224), Image.Resampling.LANCZOS)
    arr = (np.asarray(image).astype(np.float32) / 127.5) - 1
    return np.expand_dims(arr, axis=0)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    target = sys.argv[1]
    if os.path.isdir(target):
        images = [os.path.join(target, n) for n in sorted(os.listdir(target))
                  if n.lower().endswith(IMAGE_EXTS)]
    else:
        images = [target]
    if not images:
        print("No images found in", target)
        sys.exit(1)

    model = load_model(MODEL_PATH, compile=False)
    labels = load_labels(LABELS_PATH)

    for path in images:
        try:
            probs = model.predict(prepare(path), verbose=0)[0]
        except Exception as e:
            print(f"{os.path.basename(path)}: could not read image ({e})")
            continue
        best = int(np.argmax(probs))
        print(f"\n{os.path.basename(path)}")
        print(f"  Prediction: {labels[best]}  ({probs[best] * 100:.1f}%)")
        for i, p in enumerate(probs):
            print(f"    {labels[i]:<40} {p * 100:5.1f}%")


if __name__ == "__main__":
    main()
