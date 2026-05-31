import cv2
import numpy as np


def check_quality(image_path):
    img = cv2.imread(image_path)
    if img is None:
        return False, ["не вдалося відкрити файл"]

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape

    issues = []

    blur_score = cv2.Laplacian(gray, cv2.CV_64F).var()
    if blur_score < 80:
        issues.append(f"розмите фото (різкість: {blur_score:.0f}, мінімум: 80)")

    mean_brightness = float(gray.mean())
    if mean_brightness < 30:
        issues.append(f"занадто темне (яскравість: {mean_brightness:.0f})")
    if mean_brightness > 245:
        issues.append(f"пересвіт (яскравість: {mean_brightness:.0f})")

    # Check if object is clipped at edges (bright border pixels)
    border = np.concatenate([
        gray[0, :], gray[-1, :], gray[:, 0], gray[:, -1]
    ])
    if border.mean() < 10:
        issues.append("чорні краї — можливо об'єкт обрізаний")

    return len(issues) == 0, issues
