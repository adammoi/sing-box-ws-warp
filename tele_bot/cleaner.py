# Mengimpor modul 'os' untuk berinteraksi dengan sistem operasi (seperti mengakses path atau mengatur variabel environment).
import os

# Stop Services
try:
    # Menonaktifkan layanan 'tele_bot'
    os.system('systemctl disable tele_bot')

    # Menonaktifkan layanan 'sing-box'
    os.system('systemctl disable sing-box')
except Exception as e:
    # Jika ada exception saat menonaktifkan layanan, cetak pesan error.
    print(e)

# Daftar file yang akan dihapus.
files = [
    "/root/tele_bot/user_data.pkl",
    "/root/tele_bot/sb-data.json",
    "/root/tele_bot/public_key.pkl",
    "/root/tele_bot/tele_bot.py",
    "/root/user_data.pkl",
    "/root/sb-data.json",
    "/root/public_key.pkl",
    "/root/tele_bot.py",
    '/etc/systemd/system/tele_bot.service',
]

# Loop melalui daftar file dan hapus jika file tersebut ada.
for path in files:
    if os.path.exists(path):
        try:
            # Menghapus file menggunakan perintah 'rm'.
            os.system(f'rm {path}')
            # Menampilkan pesan jika file berhasil dihapus.
            print(f'Deleted {path}\n')
        except Exception as e:
            # Jika ada exception saat menghapus file, cetak pesan error.
            print(e)
