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

def display_list(items):
    print("\n" + "=" * 94)
    print("                              DAFTAR PERCAKAPAN ANTIGRAVITY")
    print("=" * 94)
    print(f"{'No.':<5} | {'App':<4} | {'Conversation ID':<38} | {'Last Modified':<16} | {'Title'}")
    print("-" * 5 + "-+-" + "-" * 4 + "-+-" + "-" * 38 + "-+-" + "-" * 16 + "-+-" + "-" * 22)
    for idx, item in enumerate(items, 1):
        dt_str = datetime.datetime.fromtimestamp(item["mtime"]).strftime("%Y-%m-%d %H:%M")
        title_disp = (item["title"][:35] + "..") if len(item["title"]) > 37 else item["title"]
        print(f"[{idx:<3}] | {item['app_label']:<4} | {item['id']:<38} | {dt_str:<16} | {title_disp}")
    print("-" * 94)
    print(f"Total percakapan: {len(items)}")
    print("=" * 94)

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

    items = collect_conversations(base_dir, target_core, target_cli, target_ide)
    if not items:
        print("Tidak ada percakapan yang ditemukan.")
        return

    display_list(items)

    if args.list:
        return

    selected_indices = set()
    if args.delete_all:
        selected_indices = set(range(len(items)))
    else:
        print("\nFormat pemilihan nomor:")
        print("  - Nomor satuan (contoh: 3)")
        print("  - Beberapa nomor dipisah koma (contoh: 1, 4, 7)")
        print("  - Rentang nomor (contoh: 1-5)")
        print("  - Ketik 'all' untuk memilih semua")
        print("  - Tekan Enter atau ketik 'q' untuk batal\n")
        try:
            choice = input("Pilih nomor yang ingin dihapus: ")
        except (EOFError, KeyboardInterrupt):
            choice = ""
        res = parse_selection(choice, len(items))
        if res is None or len(res) == 0:
            print("Operasi dibatalkan. Tidak ada file yang dihapus.")
            return
        selected_indices = res

    selected_items = [items[i] for i in sorted(selected_indices)]

    print(f"\nPercakapan yang dipilih untuk dihapus ({len(selected_items)} item):")
    for item in selected_items:
        print(f"  - [{item['app_label']}] {item['id']} : {item['title']}")

    if args.dry_run:
        print("\n[DRY-RUN] Simulasi selesai. Tidak ada file yang dihapus.")
        return

    if not args.force:
        try:
            confirm = input(f"\nApakah Anda yakin ingin menghapus {len(selected_items)} percakapan di atas? (y/N): ").strip()
        except (EOFError, KeyboardInterrupt):
            confirm = "n"
        if confirm.lower() not in ["y", "yes"]:
            print("Pembersihan dibatalkan.")
            return

    print("\nSedang menghapus percakapan terpilih...")

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

        print(f"  [TERHAPUS] [{item['app_label']}] {cid} : {item['title']}")

    if conn_cli:
        try:
            conn_cli.commit()
            conn_cli.close()
        except Exception:
            pass

    print(f"\n=== Selesai! Berhasil menghapus {len(selected_items)} percakapan. ===")

if __name__ == "__main__":
    main()
