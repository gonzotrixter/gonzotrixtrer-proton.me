import requests
import yaml
import os
import logging

CONFIG_PATH = "C:/CNC-Pipeline/config.yaml"


def _cfg():
    with open(CONFIG_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f)


def send_message(text):
    try:
        cfg = _cfg()
        token = cfg["telegram"]["token"]
        chat_id = cfg["telegram"]["chat_id"]
        requests.post(
            f"https://api.telegram.org/bot{token}/sendMessage",
            data={"chat_id": chat_id, "text": text},
            timeout=10,
        )
    except Exception as e:
        logging.warning(f"Telegram sendMessage failed: {e}")


def send_photo(image_path, caption=""):
    try:
        cfg = _cfg()
        token = cfg["telegram"]["token"]
        chat_id = cfg["telegram"]["chat_id"]
        with open(image_path, "rb") as f:
            requests.post(
                f"https://api.telegram.org/bot{token}/sendPhoto",
                data={"chat_id": chat_id, "caption": caption},
                files={"photo": f},
                timeout=30,
            )
    except Exception as e:
        logging.warning(f"Telegram sendPhoto failed: {e}")
