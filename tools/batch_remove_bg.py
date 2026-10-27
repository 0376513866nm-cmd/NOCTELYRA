"""
Công cụ xóa phông / tách nền ảnh hàng loạt (Batch Background Remover)
Hỗ trợ cả giao diện đồ họa (GUI) lẫn dòng lệnh (CLI).
Sử dụng AI 'rembg' (U2-Net) với cơ chế session reuse để tối ưu tốc độ.
"""

import os
import sys
import threading
import time
from pathlib import Path

# Cấu hình UTF-8 cho console Windows
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Các định dạng ảnh hỗ trợ
SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}


def process_image(input_path: Path, output_path: Path, session=None) -> bool:
    try:
        from PIL import Image
        from rembg import remove

        with Image.open(input_path) as img:
            # Tách nền bằng rembg
            output = remove(img, session=session)
            output.save(output_path, "PNG")
        return True
    except Exception as e:
        print(f"Lỗi khi xử lý {input_path.name}: {e}", file=sys.stderr)
        return False


def run_batch(input_dir: str, output_dir: str, model_name: str = "u2net", progress_callback=None) -> int:
    from rembg import new_session

    in_path = Path(input_dir)
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    files = [f for f in sorted(in_path.iterdir()) if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS]
    total = len(files)
    if total == 0:
        if progress_callback:
            progress_callback(0, 0, "Không tìm thấy file ảnh nào trong thư mục!")
        return 0

    if progress_callback:
        progress_callback(0, total, f"Đang tải model {model_name}...")

    # Khởi tạo session 1 lần dùng chung cho toàn bộ danh sách để tối ưu tốc độ
    session = new_session(model_name)
    success_count = 0

    for idx, f in enumerate(files, 1):
        target_file = out_path / f"{f.stem}.png"
        if progress_callback:
            progress_callback(idx, total, f"[{idx}/{total}] Đang xử lý: {f.name}")

        ok = process_image(f, target_file, session=session)
        if ok:
            success_count += 1

    if progress_callback:
        progress_callback(total, total, f"Hoàn thành! Đã tách nền {success_count}/{total} ảnh thành công.")

    return success_count


# ==========================================
# Giao diện đồ họa (GUI) bằng Tkinter
# ==========================================
def launch_gui():
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk

    root = tk.Tk()
    root.title("Batch Background Remover - Tách Nền Ảnh Hàng Loạt")
    root.geometry("620x460")
    root.minsize(540, 400)

    # Style
    style = ttk.Style(root)
    style.theme_use("clam")

    input_var = tk.StringVar()
    output_var = tk.StringVar()
    model_var = tk.StringVar(value="u2net")
    status_var = tk.StringVar(value="Sẵn sàng.")
    is_running = [False]

    def browse_input():
        d = filedialog.askdirectory(title="Chọn thư mục chứa ảnh cần xóa nền")
        if d:
            input_var.set(d)
            if not output_var.get():
                output_var.set(os.path.join(d, "transparent_output"))

    def browse_output():
        d = filedialog.askdirectory(title="Chọn thư mục lưu ảnh kết quả")
        if d:
            output_var.set(d)

    def start_processing():
        in_dir = input_var.get().strip()
        out_dir = output_var.get().strip()

        if not in_dir or not os.path.isdir(in_dir):
            messagebox.showwarning("Cảnh báo", "Vui lòng chọn thư mục chứa ảnh hợp lệ!")
            return

        if not out_dir:
            out_dir = os.path.join(in_dir, "transparent_output")
            output_var.set(out_dir)

        if is_running[0]:
            return

        is_running[0] = True
        btn_start.config(state="disabled")
        btn_browse_in.config(state="disabled")
        btn_browse_out.config(state="disabled")
        progress_bar["value"] = 0

        def update_ui(current, total, msg):
            def _update():
                status_var.set(msg)
                if total > 0:
                    pct = (current / total) * 100
                    progress_bar["value"] = pct
                    lbl_pct.config(text=f"{int(pct)}% ({current}/{total})")
            root.after(0, _update)

        def worker():
            try:
                run_batch(in_dir, out_dir, model_var.get(), progress_callback=update_ui)
                root.after(0, lambda: messagebox.showinfo("Thành công", f"Đã hoàn thành! Ảnh đã được lưu tại:\n{out_dir}"))
            except Exception as ex:
                root.after(0, lambda: messagebox.showerror("Lỗi", f"Có lỗi xảy ra: {ex}"))
            finally:
                def _reset():
                    is_running[0] = False
                    btn_start.config(state="normal")
                    btn_browse_in.config(state="normal")
                    btn_browse_out.config(state="normal")
                root.after(0, _reset)

        thread = threading.Thread(target=worker, daemon=True)
        thread.start()

    # Layout UI
    main_frame = ttk.Frame(root, padding="15")
    main_frame.pack(fill="both", expand=True)

    # Title
    lbl_title = ttk.Label(main_frame, text="🎨 CÔNG CỤ TÁCH NỀN ẢNH HÀNG LOẠT (AI REMBG)", font=("Arial", 12, "bold"))
    lbl_title.pack(anchor="w", pady=(0, 15))

    # Input Dir
    frame_in = ttk.LabelFrame(main_frame, text=" 1. Thư mục ảnh nguồn ", padding="10")
    frame_in.pack(fill="x", pady=5)
    entry_in = ttk.Entry(frame_in, textvariable=input_var)
    entry_in.pack(side="left", fill="x", expand=True, padx=(0, 8))
    btn_browse_in = ttk.Button(frame_in, text="Chọn Thư Mục...", command=browse_input)
    btn_browse_in.pack(side="right")

    # Output Dir
    frame_out = ttk.LabelFrame(main_frame, text=" 2. Thư mục lưu kết quả ", padding="10")
    frame_out.pack(fill="x", pady=5)
    entry_out = ttk.Entry(frame_out, textvariable=output_var)
    entry_out.pack(side="left", fill="x", expand=True, padx=(0, 8))
    btn_browse_out = ttk.Button(frame_out, text="Thay Đổi...", command=browse_output)
    btn_browse_out.pack(side="right")

    # Options (Model)
    frame_opts = ttk.Frame(main_frame, padding="5")
    frame_opts.pack(fill="x", pady=5)
    ttk.Label(frame_opts, text="Mô hình AI:").pack(side="left", padx=(0, 10))
    combo_model = ttk.Combobox(frame_opts, textvariable=model_var, values=["u2net", "u2netp", "isnet-general-use"], state="readonly", width=18)
    combo_model.pack(side="left")
    ttk.Label(frame_opts, text="(u2net: chất lượng cao nhất | u2netp: siêu nhanh)", foreground="#666666").pack(side="left", padx=10)

    # Progress
    frame_prog = ttk.LabelFrame(main_frame, text=" Tiến độ ", padding="10")
    frame_prog.pack(fill="x", pady=10)

    progress_bar = ttk.Progressbar(frame_prog, orient="horizontal", mode="determinate")
    progress_bar.pack(fill="x", pady=(0, 5))

    frame_prog_text = ttk.Frame(frame_prog)
    frame_prog_text.pack(fill="x")
    lbl_status = ttk.Label(frame_prog_text, textvariable=status_var, wraplength=450)
    lbl_status.pack(side="left")
    lbl_pct = ttk.Label(frame_prog_text, text="0%", font=("Arial", 9, "bold"))
    lbl_pct.pack(side="right")

    # Action Button
    btn_start = ttk.Button(main_frame, text="🚀 BẮT ĐẦU TÁCH NỀN HÀNG LOẠT", command=start_processing)
    btn_start.pack(fill="x", ipady=6, pady=10)

    root.mainloop()


# ==========================================
# Chạy trực tiếp từ dòng lệnh (CLI)
# ==========================================
def main():
    if len(sys.argv) > 1:
        if sys.argv[1] in ("--help", "-h"):
            print("Cách sử dụng:")
            print("  1. Mở giao diện cửa sổ (GUI):")
            print("     python batch_remove_bg.py")
            print("  2. Chạy qua dòng lệnh (CLI):")
            print("     python batch_remove_bg.py <thư_mục_nguồn> [thư_mục_kết_quả] [tên_model]")
            print("     Ví dụ: python batch_remove_bg.py \"C:\\Images\" \"C:\\Images\\transparent\" u2net")
            return

        if sys.argv[1] not in ("--gui", "-g"):
            input_directory = sys.argv[1]
            output_directory = sys.argv[2] if len(sys.argv) > 2 else os.path.join(input_directory, "transparent_output")
            model = sys.argv[3] if len(sys.argv) > 3 else "u2net"

            print(f"=== BATCH BACKGROUND REMOVER (CLI) ===")
            print(f"Nguồn: {input_directory}")
            print(f"Đích : {output_directory}")
            print(f"Model: {model}")

            def cli_progress(current, total, msg):
                print(f"\r{msg}", end="", flush=True)

            res = run_batch(input_directory, output_directory, model, progress_callback=cli_progress)
            print(f"\nĐã hoàn thành {res} ảnh.")
            return

    launch_gui()


if __name__ == "__main__":
    main()
