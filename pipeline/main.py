import os
import sys
import time
import shutil
import queue
import threading
import logging
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

sys.path.insert(0, os.path.dirname(__file__))

from qc import check_quality
from segment import remove_background, alpha_to_white
from depth import estimate_depth
from heightmap import process_heightmap
from notifier import send_message, send_photo

BASE_DIR   = r"C:\CNC-Pipeline"
INCOMING   = os.path.join(BASE_DIR, "incoming")
OUTPUT     = os.path.join(BASE_DIR, "output")
REJECTED   = os.path.join(BASE_DIR, "rejected")
PROCESSING = os.path.join(BASE_DIR, "processing")

job_queue: queue.Queue = queue.Queue()
SUPPORTED = (".jpg", ".jpeg", ".png")


def _wait_for_file(path, stable_secs=2, timeout=30):
    """Wait until file size stops changing (Syncthing finishes writing)."""
    deadline = time.time() + timeout
    prev_size = -1
    stable_count = 0
    while time.time() < deadline:
        try:
            size = os.path.getsize(path)
        except OSError:
            time.sleep(0.5)
            continue
        if size == prev_size:
            stable_count += 1
            if stable_count >= stable_secs * 2:
                return True
        else:
            stable_count = 0
        prev_size = size
        time.sleep(0.5)
    return False


class PhotoHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return
        if not event.src_path.lower().endswith(SUPPORTED):
            return
        if _wait_for_file(event.src_path):
            job_queue.put(event.src_path)
            logging.info(f"Queued: {event.src_path}")
        else:
            logging.warning(f"File unstable after 30s, skipped: {event.src_path}")


def worker():
    while True:
        filepath = job_queue.get()
        try:
            _process(filepath)
        except Exception as e:
            logging.error(f"Pipeline error [{filepath}]: {e}", exc_info=True)
            send_message(f"⚠️ Помилка:\n{os.path.basename(filepath)}\n\n{e}")
        finally:
            job_queue.task_done()


def _process(filepath):
    filename = os.path.basename(filepath)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    project_id = f"{timestamp}_{os.path.splitext(filename)[0]}"

    # Move to processing immediately — prevents re-processing if watchdog re-fires
    processing_path = os.path.join(PROCESSING, filename)
    try:
        shutil.move(filepath, processing_path)
    except Exception as e:
        logging.error(f"Cannot move to processing: {e}")
        return
    filepath = processing_path

    logging.info(f"Start: {filename}")
    send_message(f"⏳ Отримано: {filename}")

    # 1. Quality check
    ok, issues = check_quality(filepath)
    if not ok:
        shutil.move(filepath, os.path.join(REJECTED, filename))
        send_message("❌ Погане фото відхилено:\n" + "\n".join(f"• {i}" for i in issues))
        logging.warning(f"Rejected: {filename} — {issues}")
        return

    # 2. Setup project folder
    project_dir = os.path.join(OUTPUT, project_id)
    os.makedirs(project_dir, exist_ok=True)

    original = os.path.join(project_dir, "original.jpg")
    shutil.copy(filepath, original)

    # 3. Remove background
    send_message("🔍 Виділення об'єкта...")
    segmented_png = os.path.join(project_dir, "segmented.png")
    remove_background(original, segmented_png)

    segmented_jpg = os.path.join(project_dir, "segmented_white.jpg")
    alpha_to_white(segmented_png, segmented_jpg)

    # 4. MiDaS depth estimation
    send_message("🧠 AI-аналіз глибини (MiDaS)...")
    depth_raw = os.path.join(project_dir, "depth_raw.png")
    estimate_depth(segmented_jpg, depth_raw)

    # 5. Heightmap
    heightmap_path = os.path.join(project_dir, "heightmap.png")
    process_heightmap(depth_raw, heightmap_path)

    # 6. Notify
    logging.info(f"Done: {project_id}")
    send_photo(
        heightmap_path,
        f"✅ Рельєф готовий!\n\n"
        f"📁 output\\{project_id}\\\n"
        f"Файл для ArtCAM: heightmap.png",
    )


if __name__ == "__main__":
    logging.basicConfig(
        filename=os.path.join(BASE_DIR, "logs", "pipeline.log"),
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )
    logging.info("=== CNC Pipeline started ===")
    send_message("🚀 CNC Pipeline запущено\nОчікую фото в папці Syncthing...")

    worker_thread = threading.Thread(target=worker, daemon=True)
    worker_thread.start()

    observer = Observer()
    observer.schedule(PhotoHandler(), INCOMING, recursive=False)
    observer.start()

    print(f"CNC Pipeline запущено.")
    print(f"Очікування фото: {INCOMING}")
    print("Ctrl+C для зупинки")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\nЗупинка...")

    observer.join()
