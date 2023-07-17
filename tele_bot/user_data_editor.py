# Mengimpor modul 'pickle' untuk mengizinkan serialisasi dan deserialisasi objek Python.
import pickle
# Mengimpor modul 'os' untuk berinteraksi dengan sistem operasi (seperti mengakses path atau mengatur variabel lingkungan).
import os

# Menghentikan layanan 'tele_bot.service' menggunakan perintah 'systemctl stop'.
os.system('systemctl stop tele_bot.service')

# Membuat dictionary 'user_data' untuk menyimpan preferensi pengguna terkait bot.
print('--------> Creating user_data\n\n')
user_data = {
    "chat_id": "",
    "user_id": "",
    "channel_id": "",
    "server_IP": "",
    "listen_port": 443,
    "bot_token": "",
    "renewal_interval": 3600,
    "domain_name": 'domain.com'
}

# Meminta pengguna untuk memasukkan jenis chat ("me" atau "ch") menggunakan input keyboard.
user_data["chat_id"] = input(
    "\nYou want the bot to send messages to channel or you?\n----> Type  me or ch: ")

# Melakukan validasi input chat_id, terus meminta input hingga benar.
while not user_data["chat_id"] in ('me', 'ch'):
    user_data["chat_id"] = input("\n----> Please type  me or ch: ")

# Meminta pengguna untuk memasukkan server IP, nomor port, channel ID, token bot, dan preferensi lainnya menggunakan input keyboard.
user_data["server_IP"] = input("Enter server IP : ")
user_data["listen_port"] = int(input("Enter port number : "))
user_data["channel_id"] = input("Enter channel ID you got from @myidbot : ")
user_data["bot_token"] = input("Enter bot token : ")
user_data["renewal_interval"] = int(
    input("Enter renewal interval in HOURS : "))
user_data["domain_name"] = input(
    "Enter domain name if you have one, if not just press Enter : ")

# Menyimpan dictionary 'user_data' ke dalam file "user_data.pkl" menggunakan modus write binary (wb).
with open("/root/tele_bot/user_data.pkl", "wb") as f:
    pickle.dump(user_data, f)
    # Mencetak pesan konfirmasi bahwa user_data berhasil dibuat dan menampilkan isi user_data.
    print(f"-------user_data was created!-------\n{user_data}\n\n")
    # Restart layanan 'tele_bot.service' menggunakan perintah 'systemctl restart'.
    os.system('systemctl restart tele_bot.service')
