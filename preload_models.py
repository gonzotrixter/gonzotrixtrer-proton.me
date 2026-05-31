# Pre-downloads MiDaS model to local cache so pipeline starts instantly.
import sys

print("Завантаження AI-моделі MiDaS (~200 MB)...")
print("Це відбувається один раз. Будь ласка, зачекайте...\n")

try:
    import torch
    model = torch.hub.load("intel-isl/MiDaS", "MiDaS_small", trust_repo=True)
    model.eval()
    print("✓ Модель MiDaS завантажена і готова до роботи.")
except Exception as e:
    print(f"⚠ Попередження: модель не завантажилась зараз ({e})")
    print("  Вона завантажиться автоматично при першому запуску пайплайна.")
    sys.exit(0)
