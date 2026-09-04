#!/usr/bin/env python3
import os
import sys
import glob
import sqlite3
import json
import re
import datetime
import argparse
import shutil
import math

def parse_args():
    parser = argparse.ArgumentParser(
        description="Menampilkan dan menghapus percakapan secara selektif berbasis nomor untuk antigravity, antigravity-cli, dan antigravity-ide."
    )
    parser.add_argument("-l", "--list", action="store_true", help="Hanya tampilkan daftar percakapan tanpa menghapus")
    parser.add_argument("--delete-all", action="store_true", help="Pilih SEMUA percakapan sekaligus untuk dihapus")
    parser.add_argument("-f", "--force", "-y", "--yes", action="store_true", help="Hapus tanpa konfirmasi interaktif")
    parser.add_argument("-n", "--dry-run", action="store_true", help="Simulasi tampilan target tanpa menghapus file")
    parser.add_argument("--core", action="store_true", help="Hanya operasikan pada ~/.gemini/antigravity")
    parser.add_argument("--cli", action="store_true", help="Hanya operasikan pada ~/.gemini/antigravity-cli")
    parser.add_argument("--ide", action="store_true", help="Hanya operasikan pada ~/.gemini/antigravity-ide")
    parser.add_argument("--all", action="store_true", help="Operasikan seluruhnya (default)")
    return parser.parse_args()

def collect_conversations(base_dir, target_core, target_cli, target_ide):
    items = []

    # 1. ANTIGRAVITY (CORE / HUB)
    if target_core:
        core_conv_dir = os.path.join(base_dir, "antigravity", "conversations")
        pb_file = os.path.join(base_dir, "antigravity", "agyhub_summaries_proto.pb")
        pb_titles = {}
        if os.path.exists(pb_file):
            try:
                with open(pb_file, "rb") as f:
                    content = f.read().decode("latin1", errors="ignore")
                    for m in re.finditer(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", content):
                        cid = m.group(1)
                        sub = content[m.end():m.end() + 250]
                        strings = re.findall(r"[\x20-\x7E]{5,80}", sub)
                        valid = [
                            s.strip(" '\"(")
                            for s in strings
                            if not s.startswith("file://")
                            and not s.startswith("git@")
                            and not re.match(r"^[0-9a-f\-]+$", s)
                            and not s.startswith("KAnggara")
                        ]
                        if valid and cid not in pb_titles:
                            pb_titles[cid] = valid[0]
            except Exception:
                pass

        if os.path.exists(core_conv_dir):
            for db in glob.glob(os.path.join(core_conv_dir, "*.db")):
                cid = os.path.basename(db).replace(".db", "")
                title = pb_titles.get(cid, "")
                if not title:
                    t_path = os.path.join(base_dir, "antigravity", "brain", cid, ".system_generated", "logs", "transcript.jsonl")
                    if os.path.exists(t_path):
                        try:
                            with open(t_path) as tf:
                                for line in tf:
                                    d = json.loads(line)
                                    if d.get("type") == "USER_INPUT":
                                        txt = re.sub(r"<[^>]+>", " ", d.get("content", ""))
                                        title = " ".join(txt.split())[:55]
                                        break
                        except Exception:
                            pass
                if not title:
                    title = "(Untitled)"
                items.append({
                    "app": "core",
                    "app_label": "core",
                    "id": cid,
                    "title": title,
                    "mtime": os.path.getmtime(db),
                    "db_file": db
                })

    # 2. ANTIGRAVITY-IDE
    if target_ide:
        ide_conv_dir = os.path.join(base_dir, "antigravity-ide", "conversations")
        if os.path.exists(ide_conv_dir):
            for db in glob.glob(os.path.join(ide_conv_dir, "*.db")):
                cid = os.path.basename(db).replace(".db", "")
                title = ""
                meta_path = os.path.join(base_dir, "antigravity-ide", "brain", cid, "implementation_plan.md.metadata.json")
                if os.path.exists(meta_path):
                    try:
                        with open(meta_path) as mf:
                            title = json.load(mf).get("summary", "")
                    except Exception:
                        pass
                if not title:
                    t_path = os.path.join(base_dir, "antigravity-ide", "brain", cid, ".system_generated", "logs", "transcript.jsonl")
                    if os.path.exists(t_path):
                        try:
                            with open(t_path) as tf:
                                for line in tf:
                                    d = json.loads(line)
                                    if d.get("type") == "USER_INPUT":
                                        txt = re.sub(r"<[^>]+>", " ", d.get("content", ""))
                                        txt = re.sub(r"@\[[^\]]+\]", " ", txt)
                                        title = " ".join(txt.split())[:55]
                                        break
                        except Exception:
                            pass
                if not title:
                    title = "(Untitled)"
                items.append({
                    "app": "ide",
                    "app_label": "ide ",
                    "id": cid,
                    "title": title,
                    "mtime": os.path.getmtime(db),
                    "db_file": db
                })

    # 3. ANTIGRAVITY-CLI
    if target_cli:
        cli_db = os.path.join(base_dir, "antigravity-cli", "conversation_summaries.db")
        cli_conv_dir = os.path.join(base_dir, "antigravity-cli", "conversations")
        db_titles = {}
        if os.path.exists(cli_db):
            try:
                conn = sqlite3.connect(cli_db)
                cur = conn.cursor()
                cur.execute("SELECT conversation_id, CASE WHEN title != '' THEN title ELSE '(Untitled)' END FROM conversation_summaries;")
                for row in cur.fetchall():
                    db_titles[row[0]] = row[1]
                conn.close()
            except Exception:
                pass

        if os.path.exists(cli_conv_dir):
            for db in glob.glob(os.path.join(cli_conv_dir, "*.db")):
                cid = os.path.basename(db).replace(".db", "")
                title = db_titles.get(cid, "")
                if not title:
                    t_path = os.path.join(base_dir, "antigravity-cli", "brain", cid, ".system_generated", "logs", "transcript.jsonl")
                    if os.path.exists(t_path):
                        try:
                            with open(t_path) as tf:
                                for line in tf:
                                    d = json.loads(line)
                                    if d.get("type") == "USER_INPUT":
                                        txt = re.sub(r"<[^>]+>", " ", d.get("content", ""))
                                        title = " ".join(txt.split())[:55]
                                        break
                        except Exception:
                            pass
                if not title:
                    title = "(Untitled)"
                items.append({
                    "app": "cli",
                    "app_label": "cli ",
                    "id": cid,
                    "title": title,
                    "mtime": os.path.getmtime(db),
                    "db_file": db
                })

    items.sort(key=lambda x: x["mtime"], reverse=True)
    return items

def render_page(items, page_idx, page_size=10, clear_screen=False):
    total_items = len(items)
    total_pages = max(1, math.ceil(total_items / page_size))
    page_idx = max(0, min(page_idx, total_pages - 1))

    start_idx = page_idx * page_size
    end_idx = min(start_idx + page_size, total_items)
    page_items = items[start_idx:end_idx]

    if clear_screen and sys.stdout.isatty():
        sys.stdout.write("\033[2J\033[H")
        sys.stdout.flush()

    print("=" * 90)
    header_text = f"DAFTAR PERCAKAPAN ANTIGRAVITY (Halaman {page_idx + 1} dari {total_pages})"
    print(header_text.center(90))
    print("=" * 90)
    print(f"{'No.':<5} | {'App':<4} | {'Conv ID':<8} | {'Last Modified':<16} | {'Title':<45}")
    print(f"{'-' * 5}-+-{'-' * 4}-+-{'-' * 8}-+-{'-' * 16}-+-{'-' * 45}")

    for i, item in enumerate(page_items, start_idx + 1):
        dt_str = datetime.datetime.fromtimestamp(item["mtime"]).strftime("%Y-%m-%d %H:%M")
        short_id = item["id"][:8]
        if len(item["title"]) > 45:
            title_disp = item["title"][:42] + "..."
        else:
            title_disp = item["title"]
        print(f"[{i:<3}] | {item['app_label']:<4} | {short_id:<8} | {dt_str:<16} | {title_disp:<45}")

    print("-" * 90)
    info_text = f"Menampilkan {start_idx + 1}-{end_idx} dari {total_items} percakapan | Halaman {page_idx + 1}/{total_pages}"
    print(info_text.center(90))
    print("=" * 90)
    print(f"{'Kontrol Navigasi (Langsung tanpa Enter):':<90}")
    print(f"{'  [n] Next page   [p] Prev page   [d] Pilih nomor hapus   [q] Keluar':<90}")
    print(f"{'  (Atau ketik langsung angka nomor percakapan untuk menghapus)':<90}")
    print("-" * 90)

def parse_selection(user_input, total_count):
    selected = set()
    cleaned = user_input.strip()
    if not cleaned or cleaned.lower() in ["q", "quit", "exit", "batal"]:
        return None

    if cleaned.lower() == "all":
        return set(range(total_count))

    parts = [p.strip() for p in cleaned.split(",") if p.strip()]
    for part in parts:
        if "-" in part:
            try:
                s_str, e_str = part.split("-", 1)
                s, e = int(s_str), int(e_str)
                for n in range(s, e + 1):
                    if 1 <= n <= total_count:
                        selected.add(n - 1)
            except ValueError:
                print(f"  Format rentang tidak valid diabaikan: {part}")
        else:
            try:
                n = int(part)
                if 1 <= n <= total_count:
                    selected.add(n - 1)
                else:
                    print(f"  Nomor di luar batas: {n}")
            except ValueError:
                print(f"  Input tidak valid diabaikan: {part}")

    return selected

def execute_deletion(base_dir, selected_items):
    cli_db_path = os.path.join(base_dir, "antigravity-cli", "conversation_summaries.db")
    conn_cli = None
    if os.path.exists(cli_db_path):
        try:
            conn_cli = sqlite3.connect(cli_db_path)
        except Exception:
            pass

    for item in selected_items:
        cid = item["id"]
        app = item["app"]

        # 1. Hapus conversation database & shm/wal/pb
        app_sub = f"antigravity-{app}" if app in ["cli", "ide"] else "antigravity"
        conv_dir = os.path.join(base_dir, app_sub, "conversations")
        for f in glob.glob(os.path.join(conv_dir, f"{cid}*")):
            try:
                os.remove(f)
            except Exception:
                pass

        # 2. Hapus brain folder
        brain_dir = os.path.join(base_dir, app_sub, "brain", cid)
        if os.path.exists(brain_dir):
            shutil.rmtree(brain_dir, ignore_errors=True)

        # 3. Hapus annotations jika ada
        ann_dir = os.path.join(base_dir, app_sub, "annotations")
        for f in glob.glob(os.path.join(ann_dir, f"{cid}*")):
            try:
                os.remove(f)
            except Exception:
                pass

        # 4. Hapus dari SQLite conversation_summaries.db jika CLI
        if app == "cli" and conn_cli:
            try:
                conn_cli.execute("DELETE FROM conversation_summaries WHERE conversation_id = ?;", (cid,))
            except Exception:
                pass

        print(f"  [TERHAPUS] [{item['app_label']}] {cid[:8]} : {item['title']}")

    if conn_cli:
        try:
            conn_cli.commit()
            conn_cli.close()
        except Exception:
            pass

def get_single_char():
    """Membaca 1 karakter dari stdin tanpa perlu menekan Enter (untuk terminal TTY)."""
    if not sys.stdin.isatty():
        line = sys.stdin.readline()
        return line.strip() if line else ""

    import tty
    import termios
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    return ch

def ask_confirmation(count):
    """
    Konfirmasi penghapusan:
    - User menekan Enter (\r, \n) atau y/Y -> langsung konfirmasi hapus!
    - User menekan Esc (\x1b), q/Q, n/N, Ctrl+C (\x03) -> batalkan (cancel).
    """
    prompt_msg = f"\nApakah Anda yakin ingin menghapus {count} percakapan di atas? [Enter/y: Hapus, Esc/q/n: Batal]: "
    sys.stdout.write(prompt_msg)
    sys.stdout.flush()

    if not sys.stdin.isatty():
        try:
            line = sys.stdin.readline()
        except (EOFError, KeyboardInterrupt):
            return False
        if line is None:
            return False
        cleaned = line.strip().lower()
        # Jika user enter langsung (line kosong) atau 'y'/'yes' -> langsung hapus
        if cleaned == "" or cleaned in ["y", "yes"]:
            return True
        return False

    ch = get_single_char()
    # Enter (\r atau \n) atau y/Y -> langsung hapus
    if ch in ["\r", "\n", "y", "Y"]:
        sys.stdout.write("Hapus (Konfirmasi)\n")
        sys.stdout.flush()
        return True
    # Esc (\x1b), q/Q, n/N, Ctrl+C (\x03) -> batal
    sys.stdout.write("Batal (Dibatalkan)\n")
    sys.stdout.flush()
    return False

def main():
    args = parse_args()
    base_dir = os.path.expanduser("~/.gemini")

    target_core = args.core
    target_cli = args.cli
    target_ide = args.ide
    if not target_core and not target_cli and not target_ide:
        target_core = True
        target_cli = True
        target_ide = True

    PAGE_SIZE = 10

    # Mode 1: Hanya list seluruhnya
    if args.list:
        items = collect_conversations(base_dir, target_core, target_cli, target_ide)
        if not items:
            print("Tidak ada percakapan yang ditemukan.")
            return
        total_pages = max(1, math.ceil(len(items) / PAGE_SIZE))
        for p in range(total_pages):
            render_page(items, p, PAGE_SIZE, clear_screen=False)
            print()
        return

    # Mode 2: Hapus semua sekaligus tanpa prompt
    if args.delete_all:
        items = collect_conversations(base_dir, target_core, target_cli, target_ide)
        if not items:
            print("Tidak ada percakapan yang ditemukan.")
            return
        render_page(items, 0, PAGE_SIZE, clear_screen=False)
        print(f"\nSemua {len(items)} percakapan dipilih untuk dihapus.")
        if args.dry_run:
            print("\n[DRY-RUN] Simulasi selesai. Tidak ada file yang dihapus.")
            return
        if not args.force:
            if not ask_confirmation(len(items)):
                print("Pembersihan dibatalkan.")
                return
        print("\nSedang menghapus semua percakapan...")
        execute_deletion(base_dir, items)
        print(f"\n=== Selesai! Berhasil menghapus {len(items)} percakapan. ===")
        return

    # Mode 3: Interactive Pagination & Deletion
    current_page = 0
    while True:
        items = collect_conversations(base_dir, target_core, target_cli, target_ide)
        if not items:
            print("\nTidak ada percakapan yang tersisa.")
            break

        total_pages = max(1, math.ceil(len(items) / PAGE_SIZE))
        if current_page >= total_pages:
            current_page = total_pages - 1

        render_page(items, current_page, PAGE_SIZE, clear_screen=True)

        if not sys.stdin.isatty():
            # Jika piped input / non-tty
            try:
                line = sys.stdin.readline()
            except (EOFError, KeyboardInterrupt):
                break
            if not line:
                break
            line_str = line.strip()
            if line_str.lower() in ['n', 'next']:
                if current_page < total_pages - 1:
                    current_page += 1
                continue
            elif line_str.lower() in ['p', 'prev']:
                if current_page > 0:
                    current_page -= 1
                continue
            elif line_str.lower() in ['q', 'quit', 'exit']:
                break
            else:
                initial_num = line_str
        else:
            # Mode TTY interaktif: Baca 1 karakter tanpa Enter
            sys.stdout.write("Pilihan Anda [n/p/d/q atau angka]: ")
            sys.stdout.flush()
            try:
                ch = get_single_char()
            except (EOFError, KeyboardInterrupt):
                print()
                break

            if ch in ['\x03', '\x04', 'q', 'Q', '\x1b']:  # Ctrl+C, Ctrl+D, q, Esc
                print(f"{ch}\nKeluar.")
                break
            elif ch in ['n', 'N']:
                if current_page < total_pages - 1:
                    current_page += 1
                continue
            elif ch in ['p', 'P']:
                if current_page > 0:
                    current_page -= 1
                continue
            elif ch in ['d', 'D']:
                try:
                    sys.stdout.write("\r\033[K")
                    sys.stdout.flush()
                    initial_num = input("Pilih nomor yang ingin dihapus: ").strip()
                except (EOFError, KeyboardInterrupt):
                    initial_num = ""
            elif ch.isdigit():
                try:
                    import readline
                    def hook():
                        readline.insert_text(ch)
                        readline.set_startup_hook(None)
                    readline.set_startup_hook(hook)
                    sys.stdout.write("\r\033[K")
                    sys.stdout.flush()
                    initial_num = input("Pilih nomor yang ingin dihapus: ").strip()
                except (EOFError, KeyboardInterrupt):
                    initial_num = ""
                finally:
                    try:
                        import readline
                        readline.set_startup_hook(None)
                    except Exception:
                        pass
            else:
                continue

        if not initial_num:
            continue

        res = parse_selection(initial_num, len(items))
        if not res:
            print("Pilihan tidak valid.")
            continue

        selected_items = [items[i] for i in sorted(res)]
        print(f"\nPercakapan yang dipilih untuk dihapus ({len(selected_items)} item):")
        for item in selected_items:
            print(f"  - [{item['app_label']}] {item['id'][:8]} : {item['title']}")

        if args.dry_run:
            print("\n[DRY-RUN] Simulasi selesai. Tidak ada file yang dihapus.")
            break

        if not args.force:
            if not ask_confirmation(len(selected_items)):
                print("Penghapusan dibatalkan. Kembali ke daftar...\n")
                import time
                time.sleep(0.6)
                continue

        print("\nSedang menghapus percakapan terpilih...")
        execute_deletion(base_dir, selected_items)
        print(f"\n=== Berhasil menghapus {len(selected_items)} percakapan! Memperbarui daftar... ===")
        import time
        time.sleep(0.8)

if __name__ == "__main__":
    main()
