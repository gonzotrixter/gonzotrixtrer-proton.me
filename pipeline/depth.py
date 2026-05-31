import cv2
import numpy as np
import torch

_model = None
_transform = None


def _load_model():
    global _model, _transform
    if _model is not None:
        return
    midas = torch.hub.load("intel-isl/MiDaS", "MiDaS_small", trust_repo=True)
    midas.eval()
    transforms = torch.hub.load("intel-isl/MiDaS", "transforms", trust_repo=True)
    _model = midas
    _transform = transforms.small_transform


def estimate_depth(input_path, output_path):
    _load_model()

    img = cv2.imread(input_path)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    input_batch = _transform(img_rgb)

    with torch.no_grad():
        prediction = _model(input_batch)
        prediction = torch.nn.functional.interpolate(
            prediction.unsqueeze(1),
            size=img_rgb.shape[:2],
            mode="bicubic",
            align_corners=False,
        ).squeeze()

    depth = prediction.cpu().numpy()

    depth_min, depth_max = depth.min(), depth.max()
    if depth_max - depth_min > 0:
        depth = (depth - depth_min) / (depth_max - depth_min) * 255
    depth = depth.astype(np.uint8)

    cv2.imwrite(output_path, depth)
