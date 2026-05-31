# -*- coding: utf-8 -*-
"""Interactive setup wizard for CNC Pipeline (Stack 2)."""

import os
import sys
import subprocess
import shutil
import requests

BASE_DIR = r"C:\CNC-Pipeline"
CONFIG_PATH = os.path.join(BASE_DIR, "config.yaml")

DIRS = ["incoming", "output", "rejected", "processing", "logs", "pipeline"]


def header():
    print()
    print("=" * 52)
    print("   CNC Pipeline — Майстер налаштування")
    print("   Stack 2: MiDaS AI + Syncthing + Telegram")
    print("=" * 52)
    print()


def step(n, total, text):
    print(f"\n[{n}/{total}] {text}")
    print("-" * 40)


def create_dirs():
    step(1, 5, "Створення папок")
    for d in DIRS:
        path = os.path.join(BASE_DIR, d)
        os.makedirs(path, exist_ok=True)
        print(f"  ✓ {path}")


def install_packages():
    step(2, 5, "Встановлення Python-пакетів")
    print("  Це може зайняти 5–15 хвилин.")
    print("  MiDaS завантажить модель ~200 MB при першому запуску пайплайна.\n")

    req_path = os.path.join(BASE_DIR, "pipeline", "requirements.txt")

    cmds = [
        ([sys.executable, "-m", "pip", "install", "--upgrade", "pip", "-q"], "pip upgrade"),
        ([sys.executable, "-m", "pip", "install", "-r", req_path, "-q"], "основні пакети"),
        (
            [
                sys.executable, "-m", "pip", "install",
                "torch", "torchvision",
                "--index-url", "https://download.pytorch.org/whl/cpu",
                "-q",
            ],
            "PyTorch CPU (~200 MB)",
        ),
    ]

    for cmd, label in cmds:
        print(f"  Встановлення: {label}...")
        result = subprocess.run(cmd, capture_output=True)
        if result.returncode == 0:
            print(f"  ✓ {label}")
        else:
            print(f"  ⚠ {label} — помилка (продовжуємо)")
            if result.stderr:
                print(f"    {result.stderr.decode(errors='ignore')[-200:]}")


def setup_telegram():
    step(3, 5, "Налаштування Telegram-бота")
    print("  Що потрібно зробити ОДИН РАЗ:")
    print()
    print("  1. Відкрий Telegram")
    print("  2. Знайди @BotFather")
    print("  3. Відправ /newbot")
    print("  4. Дай боту будь-яке ім'я і username (наприклад: cnc_workshop_bot)")
    print("  5. Скопіюй токен (виглядає як: 7123456789:AAF...)")
    print()

    while True:
        token = input("  Вставте токен: ").strip()
        if ":" in token and len(token) > 30:
            break
        print("  ❌ Схоже, це не токен. Спробуй ще раз.")

    print()
    print("  Тепер:")
    print("  1. Знайди свого бота в Telegram")
    print("  2. Відправ йому будь-яке повідомлення (наприклад: привіт)")
    input("  Натисни Enter коли відправив повідомлення боту...")

    chat_id = _detect_chat_id(token)
    return token, chat_id


def _detect_chat_id(token):
    url = f"https://api.telegram.org/bot{token}/getUpdates"
    try:
        r = requests.get(url, timeout=10)
        data = r.json()
        if data.get("result"):
            chat_id = data["result"][-1]["message"]["chat"]["id"]
            print(f"\n  ✓ Chat ID визначено автоматично: {chat_id}")
            return chat_id
    except Exception as e:
        print(f"\n  ⚠ Не вдалося визначити chat_id: {e}")

    print(f"  Відкрий: https://api.telegram.org/bot{token}/getUpdates")
    return int(input("  Введи chat_id вручну: ").strip())


def write_config(token, chat_id):
    step(4, 5, "Збереження конфігурації")
    config = f"""telegram:
  token: "{token}"
  chat_id: {chat_id}

paths:
  base:       "C:/CNC-Pipeline"
  incoming:   "C:/CNC-Pipeline/incoming"
  output:     "C:/CNC-Pipeline/output"
  rejected:   "C:/CNC-Pipeline/rejected"
  processing: "C:/CNC-Pipeline/processing"
  logs:       "C:/CNC-Pipeline/logs"

quality:
  min_blur_score: 80
  min_brightness: 30
  max_brightness: 245

heightmap:
  size: [512, 512]
  blur_kernel: 3
  invert: true
"""
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        f.write(config)
    print(f"  ✓ Збережено: {CONFIG_PATH}")


def create_shortcuts():
    step(5, 5, "Ярлик на робочому столі")

    # start.bat already in BASE_DIR (copied by install.bat)
    start_bat = os.path.join(BASE_DIR, "start.bat")

    desktop = os.path.join(os.path.expanduser("~"), "Desktop")
    shortcut_path = os.path.join(desktop, "CNC Pipeline.lnk")

    ps = (
        f"$ws = New-Object -ComObject WScript.Shell; "
        f"$sc = $ws.CreateShortcut('{shortcut_path}'); "
        f"$sc.TargetPath = '{start_bat}'; "
        f"$sc.WorkingDirectory = '{BASE_DIR}'; "
        f"$sc.Description = 'CNC Pipeline Stack 2'; "
        f"$sc.Save()"
    )
    result = subprocess.run(["powershell", "-NoProfile", "-Command", ps], capture_output=True)
    if result.returncode == 0:
        print(f"  ✓ Ярлик: {shortcut_path}")
    else:
        print(f"  ⚠ Ярлик не створено — запускай вручну: {start_bat}")


def send_test_message(token, chat_id):
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    try:
        r = requests.post(
            url,
            data={
                "chat_id": chat_id,
                "text": (
                    "🚀 CNC Pipeline встановлено!\n\n"
                    "Що далі:\n"
                    "1. Встанови Syncthing на ПК та Redmi\n"
                    "   syncthing.net\n"
                    "2. Синхронізуй папку:\n"
                    "   C:\\CNC-Pipeline\\incoming\n"
                    "3. Запусти «CNC Pipeline» з робочого столу\n"
                    "4. Зроби тестове фото — рельєф прийде сюди ✅"
                ),
            },
            timeout=10,
        )
        if r.status_code == 200:
            print("\n  ✓ Тестове повідомлення відправлено в Telegram!")
        else:
            print(f"\n  ⚠ Telegram відповів: {r.text}")
    except Exception as e:
        print(f"\n  ⚠ Telegram недоступний: {e}")


def done():
    print()
    print("=" * 52)
    print("  ✅ ВСТАНОВЛЕННЯ ЗАВЕРШЕНО!")
    print("=" * 52)
    print()
    print("  Наступні кроки:")
    print()
    print("  1. Встанови Syncthing на ПК та Redmi:")
    print("     https://syncthing.net")
    print("     Папка синхронізації: C:\\CNC-Pipeline\\incoming")
    print()
    print("  2. На Redmi встанови Open Camera (F-Droid)")
    print("     Зафіксуй фокус і експозицію")
    print()
    print("  3. Запусти CNC Pipeline:")
    print("     Двічі клацни «CNC Pipeline» на робочому столі")
    print()
    print("  4. Зроби тестове фото — рельєф прийде в Telegram")
    print()


if __name__ == "__main__":
    header()
    create_dirs()
    install_packages()
    token, chat_id = setup_telegram()
    write_config(token, chat_id)
    create_shortcuts()
    send_test_message(token, chat_id)
    done()
    input("Натисни Enter для виходу...")
