import cv2
import numpy as np
import yaml
import os

_BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(_BASE, "config.yaml")

_DEFAULTS = {"heightmap": {"size": [512, 512], "blur_kernel": 3, "invert": True}}


def _load_config():
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, encoding="utf-8") as f:
            return yaml.safe_load(f)
    return _DEFAULTS


def process_heightmap(depth_path, output_path):
    config = _load_config()
    size = tuple(config["heightmap"]["size"])
    blur_k = config["heightmap"]["blur_kernel"]
    invert = config["heightmap"]["invert"]

    depth = cv2.imread(depth_path, cv2.IMREAD_GRAYSCALE)

    # MiDaS: closer = higher value → invert so raised surface = white
    if invert:
        depth = 255 - depth

    depth = cv2.normalize(depth, None, 0, 255, cv2.NORM_MINMAX)
    depth = cv2.resize(depth, size, interpolation=cv2.INTER_LANCZOS4)

    if blur_k > 1:
        k = blur_k if blur_k % 2 == 1 else blur_k + 1
        depth = cv2.GaussianBlur(depth, (k, k), 0)

    cv2.imwrite(output_path, depth)
