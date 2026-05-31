from rembg import remove
from PIL import Image
import numpy as np
import cv2


def remove_background(input_path, output_path):
    with open(input_path, "rb") as f:
        output_data = remove(f.read())
    with open(output_path, "wb") as f:
        f.write(output_data)


def alpha_to_white(input_path, output_path):
    """Convert transparent PNG to white background JPG for MiDaS input."""
    img = Image.open(input_path).convert("RGBA")
    background = Image.new("RGBA", img.size, (255, 255, 255, 255))
    background.paste(img, mask=img.split()[3])
    background.convert("RGB").save(output_path, "JPEG", quality=95)
