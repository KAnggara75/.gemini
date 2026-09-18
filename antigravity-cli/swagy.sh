#!/usr/bin/env python3
"""
swagy.sh (Python 3 implementation)
==================================
Switch akun Google untuk Antigravity CLI (agy).

Usage:
  swagy              tampilkan status akun aktif (default)
  swagy pwa          switch ke akun pakaiwa (pakaiwa.id@gmail.com)
  swagy kaa          switch ke akun kaangara (kaanggara75@gmail.com)
  swagy save         simpan token akun yang sedang aktif di keychain
"""

import subprocess, base64, json, sys, os
from pathlib import Path

# ─── Konfigurasi Akun ─────────────────────────────────────────
# Alias singkat: pwa & kaa, tetap support alias panjang pakaiwa & kaangara
PRIMARY_ACCOUNTS = {
    "pwa": "pakaiwa.id@gmail.com",
    "kaa": "kaanggara75@gmail.com",
}

ALIAS_MAP = {
    "pwa": "pakaiwa.id@gmail.com",
    "pakaiwa": "pakaiwa.id@gmail.com",
    "kaa": "kaanggara75@gmail.com",
    "kaangara": "kaanggara75@gmail.com",
    "kanggara": "kaanggara75@gmail.com",
    "kaanggara": "kaanggara75@gmail.com",
}

GEMINI_DIR    = Path.home() / ".gemini"
ACCOUNTS_DIR  = GEMINI_DIR / "accounts"
ACCOUNTS_JSON = GEMINI_DIR / "google_accounts.json"
KS_SERVICE    = "gemini"
KS_ACCOUNT    = "antigravity"

# ─── ANSI ─────────────────────────────────────────────────────
R  = "\033[0m"
B  = "\033[1m"
GR = "\033[92m"   # bright green
YL = "\033[93m"   # bright yellow
CY = "\033[96m"   # bright cyan
RD = "\033[91m"   # bright red
GY = "\033[90m"   # gray

def info(msg):    print(f"{CY}[INFO]{R} {msg}")
def success(msg): print(f"{GR}[OK]{R} {msg}")
def warn(msg):    print(f"{YL}[WARN]{R} {msg}")
def error(msg):   print(f"{RD}[ERR]{R} {msg}", file=sys.stderr)

# ─── Keychain helpers ──────────────────────────────────────────
def keychain_read() -> str:
    r = subprocess.run(
        ["security", "find-generic-password", "-s", KS_SERVICE, "-a", KS_ACCOUNT, "-w"],
        capture_output=True, text=True
    )
    return r.stdout.strip() if r.returncode == 0 else ""

def keychain_write(token_str: str):
    subprocess.run(
        ["security", "delete-generic-password", "-s", KS_SERVICE, "-a", KS_ACCOUNT],
        capture_output=True
    )
    subprocess.run(
        ["security", "add-generic-password", "-s", KS_SERVICE, "-a", KS_ACCOUNT,
         "-w", token_str, "-U"],
        check=True, capture_output=True
    )

def decode_token(raw: str) -> dict:
    b64 = raw.replace("go-keyring-base64:", "")
    b64 += "=" * (4 - len(b64) % 4)
    return json.loads(base64.b64decode(b64).decode("utf-8"))

def get_email_from_raw(raw: str) -> str:
    try:
        d = decode_token(raw)
        parts = d.get("id_token", "").split(".")
        if len(parts) >= 2:
            payload = parts[1] + "=" * (4 - len(parts[1]) % 4)
            claims  = json.loads(base64.b64decode(payload))
            return claims.get("email", "")
    except Exception:
        pass
    return ""

def get_active_account_email() -> str:
    try:
        return json.loads(ACCOUNTS_JSON.read_text()).get("active", "")
    except Exception:
        return ""

def set_active_account_email(email: str):
    ACCOUNTS_JSON.write_text(json.dumps({"active": email, "old": []}, indent=2))

# ─── Commands ─────────────────────────────────────────────────
def cmd_show():
    raw = keychain_read()
    token_email  = get_email_from_raw(raw) if raw else ""
    active_email = get_active_account_email()

    ACCOUNTS_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    print()
    print(f"{B}{CY}╔══ swagy · Antigravity Account Switcher ══════════════════╗{R}")
    print(f"{B}{CY}║{R}  {'🔑 Keychain token : ' + (token_email or 'KOSONG'):<55}{B}{CY}║{R}")
    print(f"{B}{CY}║{R}  {'📋 Akun aktif     : ' + (active_email or 'BELUM SET'):<55}{B}{CY}║{R}")
    print(f"{B}{CY}║{R}")
    print(f"{B}{CY}║{R}  Akun terdaftar:")
    for alias, email in PRIMARY_ACCOUNTS.items():
        tfile = ACCOUNTS_DIR / f"{email}.token"
        if email == token_email:
            status = f"{GR}● AKTIF{R}"
        elif tfile.exists():
            status = f"{GY}○ tersimpan{R}"
        else:
            status = f"{RD}✗ belum disimpan{R}"
        print(f"{B}{CY}║{R}    {B}[{alias:<3}]{R}  {email:<26}  {status}")
    print(f"{B}{CY}║{R}")
    print(f"{B}{CY}╚══════════════════════════════════════════════════════════╝{R}")
    print()
    print(f"  Usage: {B}swagy [pwa|kaa|save]{R}")
    print()

def cmd_save():
    raw = keychain_read()
    if not raw:
        error("Tidak ada token aktif di keychain.")
        sys.exit(1)
    email = get_email_from_raw(raw)
    if not email:
        error("Tidak dapat membaca email dari token aktif.")
        sys.exit(1)
    ACCOUNTS_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    tfile = ACCOUNTS_DIR / f"{email}.token"
    tfile.write_text(raw)
    tfile.chmod(0o600)
    info(f"Menyimpan token akun saat ini: {YL}{email}{R}")
    success(f"Token disimpan ke {GY}{tfile}{R}")

def cmd_switch(target: str):
    # Resolve alias → email (prioritas: pwa / kaa / aliases / exact email)
    target_lower = target.lower().strip()
    target_email = ALIAS_MAP.get(target_lower, target)

    # Validasi
    known = target_email in PRIMARY_ACCOUNTS.values()
    if not known:
        error(f"Akun tidak dikenal: {target}")
        print("Pilihan yang tersedia:")
        for a, e in PRIMARY_ACCOUNTS.items():
            print(f"  {B}{a:<4}{R} → {e}")
        sys.exit(1)

    # Cek jika sudah aktif di keychain
    raw = keychain_read()
    current_email = get_email_from_raw(raw) if raw else ""
    if current_email == target_email:
        # Pastikan google_accounts.json tetap sinkron dengan email riil
        if get_active_account_email() != target_email:
            set_active_account_email(target_email)
        success(f"Sudah menggunakan akun {YL}{target_email}{R}. Tidak perlu switch.")
        return

    print()
    info(f"Switch akun: {YL}{current_email or 'KOSONG'}{R} → {GR}{target_email}{R}")
    ACCOUNTS_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)

    # 1. Backup token akun sekarang
    if current_email and raw:
        info(f"Menyimpan token akun lama: {YL}{current_email}{R}")
        tfile = ACCOUNTS_DIR / f"{current_email}.token"
        tfile.write_text(raw)
        tfile.chmod(0o600)
        success(f"Token {current_email} tersimpan.")

    # 2. Restore token akun tujuan
    tfile = ACCOUNTS_DIR / f"{target_email}.token"
    if not tfile.exists():
        error(f"Token untuk {target_email} belum tersimpan.")
        print(f"{YL}Login dulu dengan akun tersebut di agy, kemudian jalankan:{R}")
        print(f"  {B}swagy save{R}")
        sys.exit(1)

    info(f"Memuat token akun: {GR}{target_email}{R}")
    keychain_write(tfile.read_text())
    success(f"Token {target_email} di-restore ke keychain.")

    # 3. Update google_accounts.json
    set_active_account_email(target_email)
    success(f"google_accounts.json → active: {target_email}")

    # 4. Reset cache sesi
    for cache in [
        GEMINI_DIR / "antigravity-cli" / "cache" / "last_conversations.json",
        GEMINI_DIR / "antigravity-cli" / "cache" / "conversation_metadata.json",
    ]:
        if cache.exists():
            cache.write_text("{}")

    print()
    print(f"{GR}{B}✓ Switch akun selesai!{R}")
    print(f"  Akun aktif: {B}{GR}{target_email}{R}")
    print(f"  Silakan restart {B}agy{R} untuk memulai sesi baru.")
    print()

# ─── Entry Point ──────────────────────────────────────────────
def main():
    target = sys.argv[1] if len(sys.argv) > 1 else ""

    if not target or target == "show":
        cmd_show()
    elif target == "save":
        cmd_save()
    else:
        cmd_switch(target)

if __name__ == "__main__":
    main()
