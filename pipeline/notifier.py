import requests
import yaml
import os
import time
import logging

_BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(_BASE, "config.yaml")


def _cfg():
    with open(CONFIG_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f)


def send_message(text):
    for attempt in range(3):
        try:
            cfg = _cfg()
            requests.post(
                f"https://api.telegram.org/bot{cfg['telegram']['token']}/sendMessage",
                data={"chat_id": cfg["telegram"]["chat_id"], "text": text},
                timeout=10,
            )
            return
        except Exception as e:
            if attempt < 2:
                time.sleep(2 ** attempt)
            else:
                logging.warning(f"Telegram sendMessage failed after 3 tries: {e}")


def send_photo(image_path, caption=""):
    for attempt in range(3):
        try:
            cfg = _cfg()
            with open(image_path, "rb") as f:
                requests.post(
                    f"https://api.telegram.org/bot{cfg['telegram']['token']}/sendPhoto",
                    data={"chat_id": cfg["telegram"]["chat_id"], "caption": caption},
                    files={"photo": f},
                    timeout=30,
                )
            return
        except Exception as e:
            if attempt < 2:
                time.sleep(2 ** attempt)
            else:
                logging.warning(f"Telegram sendPhoto failed after 3 tries: {e}")
