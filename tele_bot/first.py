import pickle
import os
import sys
import subprocess
from subprocess import Popen, PIPE
import time


if not os.path.exists('/root/tele_bot'):
    os.system('mkdir tele_bot')
os.system('curl -Lo /root/cleaner.py https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/tele_bot/cleaner.py')
os.system('python3 /root/cleaner.py')
os.system('rm /root/cleaner.py')


print('--------> Creating user_data\n\n')
user_data = {
    "chat_id": "me",
    "user_id": "",
    "channel_id": "",
    "server_IP": "",
    "listen_port": 443,
    "bot_token": "",
    "renewal_interval": 0,
    "domain_name": 'domain.com'
}

try:
    # Mencoba mengambil nilai 'bot_token' dari argumen baris perintah saat menjalankan program.
    user_data["bot_token"] = sys.argv[1]
except:
    # Jika terjadi exception (misalnya, tidak ada argumen pada baris perintah),
    # minta pengguna untuk memasukkan nilai 'bot_token' melalui input keyboard.
    user_data["bot_token"] = input("/////////// Enter bot token : ")
finally:
    # Setelah mencoba mendapatkan nilai 'bot_token', atau setelah meminta input pengguna,
    # simpan dictionary 'user_data' ke dalam file "user_data.pkl" menggunakan modus write binary (wb).
    with open("/root/tele_bot/user_data.pkl", "wb") as f:
        pickle.dump(user_data, f)
        print(f"-------user_data was created!-------\n{user_data}\n\n")


print('--------> Downloading tele_bot.py\n\n')
# Menggunakan perintah 'os.system()' dan 'curl' untuk mengunduh file 'tele_bot.py' & 'user_data_editor.py'
# dari URL tertentu dan menyimpannya di direktori '/root/tele_bot'.
os.system('curl -Lo /root/tele_bot/tele_bot.py https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/tele_bot/tele_bot.py && curl -Lo /root/tele_bot/user_data_editor.py https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/tele_bot/user_data_editor.py')


# Menggunakan perintah 'os.system()' dan 'apt-get' untuk menginstal paket 'pip'.
os.system('apt-get -y install pip')
# Menggunakan perintah 'os.system()' dan 'pip' untuk menginstal paket 'python-telegram-bot' & 'requests'.
os.system('pip install python-telegram-bot && pip install requests')

# Memberi penundaan selama 1 detik sebelum melanjutkan eksekusi.
time.sleep(1)
# Memberi penundaan selama 1 detik lagi sebelum melanjutkan eksekusi.
time.sleep(1)


# Memeriksa apakah file 'tele_bot.service' sudah ada di '/etc/systemd/system/'.
if not os.path.exists('/etc/systemd/system/tele_bot.service'):
    # Jika file 'tele_bot.service' belum ada, maka mulai melakukan konfigurasi layanan.
    print('--------> Setting up Services \n\n')
    # Mengunduh file 'tele_bot.service' dari URL dan menyimpannya di direktori '/etc/systemd/system/'.
    os.system('curl -Lo /etc/systemd/system/tele_bot.service https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/tele_bot/tele_bot.service')
    # Memuat ulang (reload) konfigurasi daemons dari '/etc/systemd/system/'.
    os.system('systemctl daemon-reload')
    # Memberikan penundaan selama 0.2 detik.
    os.system('sleep 0.2')
    # Mengaktifkan layanan 'tele_bot' agar dijalankan saat sistem boot.
    os.system('systemctl enable tele_bot.service')
    # Memberikan penundaan selama 0.2 detik.
    os.system('sleep 0.2')
    # Memulai layanan 'tele_bot'.
    os.system('systemctl start tele_bot.service')
else:
    # Jika file 'tele_bot.service' sudah ada, restart layanan 'tele_bot'.
    os.system('systemctl restart tele_bot.service')

# Restart layanan 'tele_bot'.
os.system('systemctl restart tele_bot')

# Restart layanan 'sing-box'.
os.system('systemctl restart sing-box')

# Cetak pesan bahwa pengaturan layanan telah selesai.
print('--------Setting up Services finished --------\n\n')


s = '''
                                                                        
 _____         _              _____                      _  _           
|   __| ___   |_| ___  _ _   |_   _| _ _  ___  ___  ___ | ||_| ___  ___ 
|   __||   |  | || . || | |    | |  | | ||   ||   || -_|| || ||   || . |
|_____||_|_| _| ||___||_  |    |_|  |___||_|_||_|_||___||_||_||_|_||_  |
            |___|     |___|                                        |___|

'''

print(s)
print('\n\n-------->  Send /start message to your telegram bot')
print('\n\n-------->  After that Send /set  to set your prefrences')
