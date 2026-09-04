#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: clean-conversations.sh
# Deskripsi: Menampilkan dan membersihkan percakapan (conversations, brain, 
#            annotations, artifacts) untuk antigravity, antigravity-cli, 
#            dan antigravity-ide di ~/.gemini.
# ==============================================================================

BASE_DIR="${HOME}/.gemini"
FORCE=false
DRY_RUN=false
MODE_LIST=false

# Target scope selector (default: all)
TARGET_CORE=false
TARGET_CLI=false
TARGET_IDE=false

usage() {
  cat <<EOF
Penggunaan: $(basename "$0") [OPSI]

Opsi Tindakan:
  -l, --list       Tampilkan daftar Conversation ID dan judul percakapan
  -f, --force      Hapus langsung tanpa konfirmasi interaktif
  -n, --dry-run    Simulasi tampilan target dan ukuran tanpa menghapus file
  -h, --help       Tampilkan bantuan ini

Opsi Target Scope (Default: Semua):
  --core           Hanya operasikan pada ~/.gemini/antigravity
  --cli            Hanya operasikan pada ~/.gemini/antigravity-cli
  --ide            Hanya operasikan pada ~/.gemini/antigravity-ide
  --all            Operasikan seluruhnya (antigravity, antigravity-cli, antigravity-ide)

Contoh:
  $(basename "$0") --list        # Lihat daftar percakapan & judul di semua app
  $(basename "$0") --ide --list  # Lihat daftar percakapan & judul di IDE saja
  $(basename "$0") --dry-run     # Cek ukuran yang akan dibersihkan
  $(basename "$0") -f            # Bersihkan semua percakapan langsung
  $(basename "$0") --ide -f      # Hanya bersihkan percakapan IDE
EOF
  exit 0
}

# Parsing argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--list)
      MODE_LIST=true
      shift
      ;;
    -f|--force|-y|--yes)
      FORCE=true
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    --core)
      TARGET_CORE=true
      shift
      ;;
    --cli)
      TARGET_CLI=true
      shift
      ;;
    --ide)
      TARGET_IDE=true
      shift
      ;;
    --all)
      TARGET_CORE=true
      TARGET_CLI=true
      TARGET_IDE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Opsi tidak dikenal: $1"
      usage
      ;;
  esac
done

# Jika tidak ada scope spesifik yang dipilih, default ke semua
if [ "${TARGET_CORE}" = false ] && [ "${TARGET_CLI}" = false ] && [ "${TARGET_IDE}" = false ]; then
  TARGET_CORE=true
  TARGET_CLI=true
  TARGET_IDE=true
fi

# ==============================================================================
# MODE: LIST CONVERSATIONS (DENGAN TITLE LENGKAP)
# ==============================================================================
if [ "${MODE_LIST}" = true ]; then
  python3 - <<PYEOF
import os, glob, sqlite3, json, re, datetime

base_dir = os.path.expanduser("~/.gemini")
target_core = "${TARGET_CORE}" == "true"
target_cli = "${TARGET_CLI}" == "true"
target_ide = "${TARGET_IDE}" == "true"

def print_section_header(title):
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)
    print(f"{'Conversation ID':<38} | {'Last Modified':<16} | {'Title'}")
    print("-" * 38 + "-+-" + "-" * 16 + "-+-" + "-" * 40)

# --- 1. ANTIGRAVITY (CORE / HUB) ---
if target_core:
    print_section_header("antigravity (Core/Hub) - ~/.gemini/antigravity")
    core_conv_dir = os.path.join(base_dir, "antigravity/conversations")
    pb_file = os.path.join(base_dir, "antigravity/agyhub_summaries_proto.pb")
    
    # Extract titles from protobuf
    pb_titles = {}
    if os.path.exists(pb_file):
        try:
            with open(pb_file, "rb") as f:
                content = f.read().decode("latin1", errors="ignore")
                for m in re.finditer(r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})', content):
                    cid = m.group(1)
                    sub = content[m.end():m.end()+250]
                    # Find printable title
                    strings = re.findall(r'[\x20-\x7E]{5,80}', sub)
                    valid = [s.strip(" '\"(") for s in strings if not s.startswith("file://") and not s.startswith("git@") and not re.match(r'^[0-9a-f\-]+$', s) and not s.startswith("KAnggara")]
                    if valid and cid not in pb_titles:
                        pb_titles[cid] = valid[0]
        except Exception:
            pass

    if os.path.exists(core_conv_dir):
        db_files = glob.glob(os.path.join(core_conv_dir, "*.db"))
        db_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        if not db_files:
            print("  (Tidak ada percakapan)")
        for db in db_files:
            cid = os.path.basename(db).replace(".db", "")
            title = pb_titles.get(cid, "")
            if not title:
                # Fallback transcript
                t_path = os.path.join(base_dir, f"antigravity/brain/{cid}/.system_generated/logs/transcript.jsonl")
                if os.path.exists(t_path):
                    try:
                        with open(t_path) as tf:
                            for line in tf:
                                d = json.loads(line)
                                if d.get("type") == "USER_INPUT":
                                    txt = re.sub(r'<[^>]+>', ' ', d.get("content", ""))
                                    title = ' '.join(txt.split())[:50]
                                    break
                    except Exception:
                        pass
            if not title:
                title = "(Untitled)"
            dt = datetime.datetime.fromtimestamp(os.path.getmtime(db)).strftime("%Y-%m-%d %H:%M")
            print(f"{cid:<38} | {dt:<16} | {title[:50]}")
    else:
        print("  (Direktori tidak ditemukan)")

# --- 2. ANTIGRAVITY-IDE ---
if target_ide:
    print_section_header("antigravity-ide - ~/.gemini/antigravity-ide")
    ide_conv_dir = os.path.join(base_dir, "antigravity-ide/conversations")
    if os.path.exists(ide_conv_dir):
        db_files = glob.glob(os.path.join(ide_conv_dir, "*.db"))
        db_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        if not db_files:
            print("  (Tidak ada percakapan)")
        for db in db_files[:30]:
            cid = os.path.basename(db).replace(".db", "")
            title = ""
            # Check implementation plan metadata
            meta_path = os.path.join(base_dir, f"antigravity-ide/brain/{cid}/implementation_plan.md.metadata.json")
            if os.path.exists(meta_path):
                try:
                    with open(meta_path) as mf:
                        title = json.load(mf).get("summary", "")
                except Exception:
                    pass
            # Fallback transcript first user prompt
            if not title:
                t_path = os.path.join(base_dir, f"antigravity-ide/brain/{cid}/.system_generated/logs/transcript.jsonl")
                if os.path.exists(t_path):
                    try:
                        with open(t_path) as tf:
                            for line in tf:
                                d = json.loads(line)
                                if d.get("type") == "USER_INPUT":
                                    txt = re.sub(r'<[^>]+>', ' ', d.get("content", ""))
                                    txt = re.sub(r'@\[[^\]]+\]', ' ', txt)
                                    title = ' '.join(txt.split())[:50]
                                    break
                    except Exception:
                        pass
            if not title:
                title = "(Untitled)"
            dt = datetime.datetime.fromtimestamp(os.path.getmtime(db)).strftime("%Y-%m-%d %H:%M")
            print(f"{cid:<38} | {dt:<16} | {title[:50]}")
        if len(db_files) > 30:
            print(f"\n  ... dan {len(db_files) - 30} percakapan lainnya.")
    else:
        print("  (Direktori tidak ditemukan)")

# --- 3. ANTIGRAVITY-CLI ---
if target_cli:
    print_section_header("antigravity-cli - ~/.gemini/antigravity-cli")
    cli_db = os.path.join(base_dir, "antigravity-cli/conversation_summaries.db")
    if os.path.exists(cli_db):
        try:
            conn = sqlite3.connect(cli_db)
            cur = conn.cursor()
            cur.execute("""
                SELECT conversation_id, 
                       CASE WHEN title != '' THEN title ELSE '(Untitled)' END,
                       datetime(last_modified_time)
                FROM conversation_summaries
                ORDER BY last_modified_time DESC
                LIMIT 30;
            """)
            rows = cur.fetchall()
            if not rows:
                print("  (Tidak ada percakapan)")
            for cid, title, ltime in rows:
                dt = ltime[:16] if ltime else "-"
                print(f"{cid:<38} | {dt:<16} | {title[:50]}")
            conn.close()
        except Exception as e:
            print(f"  Error membaca database: {e}")
    else:
        print("  (Database conversation_summaries.db tidak ditemukan)")

print()
PYEOF
  exit 0
fi

# ==============================================================================
# MODE: CLEAN CONVERSATIONS
# ==============================================================================
TARGET_DIRS=()
TARGET_FILES=()

if [ "${TARGET_CORE}" = true ]; then
  TARGET_DIRS+=(
    "${BASE_DIR}/antigravity/brain"
    "${BASE_DIR}/antigravity/annotations"
    "${BASE_DIR}/antigravity/conversations"
  )
  TARGET_FILES+=(
    "${BASE_DIR}/antigravity/agyhub_summaries_proto.pb"
  )
fi

if [ "${TARGET_CLI}" = true ]; then
  TARGET_DIRS+=(
    "${BASE_DIR}/antigravity-cli/brain"
    "${BASE_DIR}/antigravity-cli/annotations"
    "${BASE_DIR}/antigravity-cli/conversations"
  )
  TARGET_FILES+=(
    "${BASE_DIR}/antigravity-cli/conversation_summaries.db"
    "${BASE_DIR}/antigravity-cli/conversation_summaries.db-shm"
    "${BASE_DIR}/antigravity-cli/conversation_summaries.db-wal"
    "${BASE_DIR}/antigravity-cli/history.jsonl"
  )
fi

if [ "${TARGET_IDE}" = true ]; then
  TARGET_DIRS+=(
    "${BASE_DIR}/antigravity-ide/brain"
    "${BASE_DIR}/antigravity-ide/conversations"
    "${BASE_DIR}/antigravity-ide/html_artifacts"
  )
fi

echo "=== Antigravity Multi-App Conversation Cleaner ==="
echo "Target aplikasi terpilih:"
[ "${TARGET_CORE}" = true ] && echo "  - antigravity (Core/Hub)"
[ "${TARGET_CLI}" = true ] && echo "  - antigravity-cli"
[ "${TARGET_IDE}" = true ] && echo "  - antigravity-ide"
echo

VALID_DIRS=()
for dir in "${TARGET_DIRS[@]}"; do
  if [ -d "${dir}" ]; then
    size="$(du -sh "${dir}" 2>/dev/null | cut -f1 || echo "0B")"
    item_count="$(find "${dir}" -mindepth 1 2>/dev/null | wc -l | tr -d ' ' || echo "0")"
    echo "  [DIR]  ${dir} (${size}, ${item_count} items)"
    VALID_DIRS+=("${dir}")
  fi
done

VALID_FILES=()
for file in "${TARGET_FILES[@]}"; do
  if [ -f "${file}" ]; then
    size="$(du -sh "${file}" 2>/dev/null | cut -f1 || echo "0B")"
    echo "  [FILE] ${file} (${size})"
    VALID_FILES+=("${file}")
  fi
done

echo

if [ ${#VALID_DIRS[@]} -eq 0 ] && [ ${#VALID_FILES[@]} -eq 0 ]; then
  echo "Tidak ada data percakapan yang ditemukan untuk dibersihkan."
  exit 0
fi

if [ "${DRY_RUN}" = true ]; then
  echo "[DRY-RUN] Mode simulasi aktif. Tidak ada file yang dihapus."
  exit 0
fi

# Konfirmasi jika tidak ada flag --force
if [ "${FORCE}" = false ]; then
  read -rp "PERINGATAN: Apakah Anda yakin ingin menghapus seluruh data percakapan di atas? (y/N): " confirm
  case "${confirm}" in
    [yY]|[yY][eE][sS])
      ;;
    *)
      echo "Pembersihan dibatalkan."
      exit 0
      ;;
  esac
fi

echo
echo "Sedang membersihkan percakapan..."

# Bersihkan direktori
for dir in "${VALID_DIRS[@]}"; do
  rm -rf "${dir:?}"/* "${dir:?}"/.[!.]* "${dir:?}"/..?* 2>/dev/null || true
  mkdir -p "${dir}"
  echo "  [BERSIH] Direktori: ${dir}"
done

# Bersihkan file cache/database metadata
for file in "${VALID_FILES[@]}"; do
  rm -f "${file}"
  echo "  [HAPUS]  File metadata: ${file}"
done

echo
echo "=== Pembersihan selesai! Seluruh percakapan telah dihapus. ==="
