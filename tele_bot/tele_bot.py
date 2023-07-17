import json
import subprocess
import os
import pickle
import datetime
import base64
import requests
from telegram.ext import Updater, CommandHandler, CallbackContext, MessageHandler, Filters
import logging

# Konfigurasi logging (pencatatan pesan) ke file '/root/tele_bot/bot.log'.
# Pengaturan ini akan mengatur level logging ke INFO, yang berarti hanya pesan
# dengan tingkat logging INFO atau yang lebih serius yang akan dicatat ke file log.
# File log akan di-write ulang (filemode='w') setiap kali program dijalankan.

logging.basicConfig(filename='/root/tele_bot/bot.log', filemode='w', level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
# Menjalankan perintah shell "/usr/bin/python3 -V" untuk mendapatkan versi Python yang terpasang.
# Hasil dari perintah ini adalah string yang berisi informasi versi Python yang terpasang,
# misalnya, "Python 3.11.4".
# Kode kemudian memproses hasil perintah untuk mendapatkan hanya nomor versi utama Python (minor version).

python_version = subprocess.run(["/usr/bin/python3", "-V"], text=True, capture_output=True).stdout.strip()
# Menggunakan metode 'split()' untuk memisahkan hasil versi menjadi beberapa kata.
# Hasilnya akan menjadi ['Python', '3.11.4'].

python_version = python_version.split()
# Menggunakan indeks [1] untuk mengakses elemen kedua (indeks 1) dari list hasil.
# Hasilnya akan menjadi '3.11.4'.

python_version = python_version[1]
# Menggunakan metode 'split()' lagi untuk memisahkan versi ke dalam bagian-bagian yang lebih detail.
# Hasilnya akan menjadi ['3', '11', '4'].

python_version = python_version.split('.')
# Menggunakan indeks [1] lagi untuk mengakses elemen kedua dari list hasil (indeks 1).
# Hasilnya adalah versi minor dari Python, dalam hal ini '11'.

python_version = python_version[1]
# Kode ini bertujuan untuk mendapatkan versi minor dari Python yang terpasang.
# Dalam contoh ini, versi minor Python adalah '8', yang mungkin akan digunakan untuk keperluan tertentu dalam aplikasi.

# Definisi fungsi 'open_user_data' untuk membaca data pengguna dari file 'user_data.pkl'.


def open_user_data():
    # Memeriksa apakah file 'user_data.pkl' ada di direktori '/root/tele_bot/'.
    if os.path.exists("/root/tele_bot/user_data.pkl"):
        # Jika file 'user_data.pkl' ada, membuka file tersebut dalam mode baca biner (rb).
        # Kemudian mengambil data (dictionary) yang ada dalam file menggunakan 'pickle.load()'.
        with open("/root/tele_bot/user_data.pkl", "rb") as file:
            user_data = pickle.load(file)
    else:
        # Jika file 'user_data.pkl' tidak ada, mencetak pesan bahwa data pengguna tidak dapat diakses.
        # Membuat dictionary 'user_data' dengan nilai default jika file tidak ada.
        print('cant open user data')
        user_data = {'chat_id': '', 'user_id': '', 'channel_id': '', 'server_IP': '','bot_token': '', 'listen_port': 443, "renewal_interval": 3600, "domain_name": 'domain.com'}
    # Mengembalikan dictionary 'user_data' yang berisi data pengguna dari file atau nilai default.
    return user_data


# Memanggil fungsi 'open_user_data()' dan menyimpan hasilnya dalam variabel 'user_data'.
# Fungsi ini akan membaca data pengguna dari file 'user_data.pkl' jika file tersebut ada,
# atau akan mengembalikan nilai default dari dictionary jika file tidak ada.
user_data = open_user_data()


# Mendapatkan 'server_IP' dan 'bot_token' dari dictionary 'user_data' yang telah dibuka sebelumnya.
# Nilai ini akan digunakan dalam aplikasi sebagai variabel global.
SERVER_IP = user_data['server_IP']
BOT_TOKEN = user_data['bot_token']

# Definisi fungsi 'iploc' untuk mendapatkan informasi lokasi berdasarkan IP publik.


def iploc():
    # URL dari layanan API yang digunakan untuk mendapatkan informasi lokasi berdasarkan IP publik.
    url = 'http://ip-api.com/json/'
    # Mengirimkan permintaan GET ke URL API dan menyimpan responnya dalam variabel 'r'.
    r = requests.get(url)
    # Mengambil data JSON dari respon dan mendapatkan informasi negara berdasarkan IP publik.
    iploc = r.json()['country']
    # Mengembalikan informasi lokasi (negara) yang ditemukan berdasarkan IP publik.
    return iploc

# Definisi fungsi 'save_to_file' untuk menyimpan data ke file dalam format JSON atau pickle.


def save_to_file(data, mode='json', path=''):
    if mode == 'json':
        # Jika mode 'json', data akan disimpan dalam file JSON dengan menggunakan modul 'json.dump()'.
        # File 'config.json' akan digunakan sebagai target penyimpanan.
        with open('/root/config.json', 'w') as file:
            json.dump(data, file)
    elif mode == 'pkl':
        # Jika mode 'pkl', data akan disimpan dalam bentuk biner menggunakan modul 'pickle.dump()'.
        # Path yang diberikan akan digunakan sebagai target penyimpanan.
        with open(path, 'wb') as f:
            pickle.dump(data, f)


# Define  a function to renew uuid, private_key and short_id automatically everyday and send the new config


def renew_data():
    logging.info("Renewing data")
    # Run shell commands to generate UUID, reality keypair, and short ID
    uuid = subprocess.run(["/root/sing-box", "generate","uuid"], text=True, capture_output=True).stdout.strip()
    with open("/root/tele_bot/sb-data.json", "w") as f:
        dic = {"uuid": uuid}
        json.dump(dic, f)

    # Stopping sing-box before editing config, not doing it for first config setup though!
    try:
        subprocess.run(["systemctl", "stop", "sing-box"])
    except Exception as e:
        logging.error(f'Error happened stopping sing-box:\n{e}')

    # Load the JSON data
    json_data = open_config_json()

    # Modify the values in the JSON data
    json_data["inbounds"][0]["users"][0]["uuid"] = uuid

    # Save the modified JSON data to config
    save_to_file(json_data)

    # Restarting sing-box
    try:
        subprocess.run(["systemctl", "restart", "sing-box"])
    except Exception as e:
        print(f'Error happened restarting sing-box:\n{e}')

    return json_data


def open_config_json():
    user_data = open_user_data()
    if os.path.exists("/root/config.json"):
        with open("/root/config.json", "r") as file:
            json_data = json.load(file)
            json_data["inbounds"][0]['listen_port'] = user_data['listen_port']
    else:
        json_data = {
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "trojan",
      "tag": "trojan-in",
      "listen": "::",
      "listen_port": 52001,
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "ipv4_only",
      "users": [
        {
          "uuid": $uuid,
          "alterid": 0
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $server_name,
        "alpn": [
          "http/1.1"
        ],
        "min_version": "1.2",
        "max_version": "1.3",
        "certificate_path": "/etc/certs/cert.pem",
        "key_path": "/etc/certs/key.pem"
      },
      "transport": {
        "type": "ws",
        "path": "/trojan",
        "max_early_data": 0,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}
        save_to_file(json_data)
        json_data = renew_data()
        os.system('systemctl enable --now sing-box')
    return json_data


json_data = open_config_json()

# Define a function to replace the data


def replace_data(server, server_name):
    json_data = open_config_json()
    json_data['inbounds'][0]['tls']['server_name'] = server_name
    return json_data

# Define function for scheduled renewal


def renew_config(context: CallbackContext):
    # Define chat_id
    user_data = open_user_data()
    chat_id = user_data['user_id']
    if user_data['chat_id'] == 'ch':
        channel_id = user_data['channel_id']
    else:
        channel_id = user_data['user_id']

    # Do the renewing process
    renew_data()

    # Send new config to user
    message, encoded64 = generate_trojan_config_string()
    context.bot.send_message(chat_id=chat_id, text=message)
    context.bot.send_message(chat_id=channel_id, text=encoded64)


def generate_trojan_config_string():
    # check to see if public_key exists
    if not os.path.exists("/root/tele_bot/public_key.pkl"):
        renew_data()
    # Load the modified JSON data from the file
    json_data = open_config_json()

    # Extract the necessary data from the JSON data
    uuid = json_data["inbounds"][0]["users"][0]["uuid"]
    listen_port = json_data["inbounds"][0]["listen_port"]
    server_name = json_data["inbounds"][0]["tls"]["server_name"]
    # Generate the trojan proxy configuration string
    loc = iploc()
    server_ip = open_user_data()['server_IP']
    config_string = (f"trojan://$uuid@$server_ip:443/?sni=$server_name&type=ws&host=$server_name&path=%2Ftrojan")
    # CREATE BASE64
    encodedBytes = base64.b64encode(config_string.encode("utf-8"))
    encodedStr = str(encodedBytes, "utf-8")

    # Change web-page if exists
    domain = user_data['domain_name']
    if os.path.exists(f"/var/www/{domain}/html/index.html"):
        with open(f"/var/www/{domain}/html/index.html", "w") as file:
            file.write(encodedStr)

    return config_string, encodedStr

# Define a function to handle the /replace command


def replace_handler(update, context):
    user_data = open_user_data()
    chat_id = update.message.chat_id
    if user_data['chat_id'] == 'ch':
        channel_id = user_data['channel_id']
    else:
        channel_id = chat_id
    text = update.message.text.split()
    if chat_id == user_data['user_id']:
        if len(text) == 2:
            server = text[1]
            server_name = text[1]
            modified_data = replace_data(server, server_name)
            subprocess.run(["systemctl", "stop", "sing-box"])
            save_to_file(modified_data)
            subprocess.run(["systemctl", "restart", "sing-box"])
            context.bot.send_message(
                chat_id=chat_id, text="Data replaced successfully!")
            message, encoded64 = generate_trojan_config_string()
            context.bot.send_message(chat_id=channel_id, text=encoded64)
            context.bot.send_message(chat_id=chat_id, text=message)
        else:
            context.bot.send_message(
                chat_id=chat_id, text="Invalid command format. Usage: /replace domain-name.com")
    else:
        context.bot.send_message(
            chat_id=chat_id, text="You're not allowed to send SNI to this bot, piss off!")

# Define status handler


# Definisi fungsi 'status_handler' untuk menghandle perintah/status bot.
def status_handler(update, context):
    # Membaca data pengguna dari file 'user_data.pkl' menggunakan fungsi 'open_user_data()'.
    user_data = open_user_data()

    # Mendapatkan ID chat dari pesan yang diterima menggunakan Telegram Bot.
    chat_id = update.message.chat_id

    # Memisahkan perintah/status yang diterima untuk mendapatkan nama proses yang dimaksud.
    # Perintah ini diharapkan memiliki format: '/status namaproses'.
    process = update.message.text.split()[1]

    # Memeriksa apakah ID chat pengirim sama dengan 'user_id' dari data pengguna.
    # Jika sama, lanjutkan untuk mengambil status proses menggunakan 'systemctl status'.
    if chat_id == user_data['user_id']:
        # Menjalankan perintah 'systemctl status' dengan nama proses sebagai argumen.
        # Hasil dari perintah ini akan disimpan dalam variabel 'status'.
        status = subprocess.run(
            ["systemctl", "status", process], capture_output=True, text=True).stdout.strip()

        # Mengirimkan pesan balasan yang berisi status proses ke ID chat pengirim.
        context.bot.send_message(chat_id=chat_id, text=status)




def command_handler(update, context):
    user_data = open_user_data()
    chat_id = update.message.chat_id
    command = update.message.text.split()[1:]
    if chat_id == user_data['user_id']:
        output = subprocess.run(
            command, capture_output=True, text=True).stdout.strip()
        with open(f"/root/tele_bot/output.txt", "w") as file:
            file.write(output)
        update.message.reply_document(
            document=open("/root/tele_bot/output.txt", "r"),
            filename="output.txt",
            caption="Here's the output of the command you asked! "
        )


# Define a handler to send log data
def log_handler(update, context):
    user_data = open_user_data()
    chat_id = update.message.chat_id
    if chat_id == user_data['user_id']:
        update.message.reply_document(
            document=open("/root/tele_bot/bot.log", "r"),
            filename="bot.log",
            caption="Here's the Log! "
        )


# Define start handler to send the config


def start_handler(update, context):
    user_data = open_user_data()
    chat_id = update.message.chat_id
    if user_data['chat_id'] == 'ch':
        channel_id = user_data['channel_id']
    else:
        channel_id = chat_id
    if len(str(user_data['user_id'])) == 0:
        user_data['user_id'] = chat_id
        with open(f"/root/tele_bot/user_data.pkl", "wb") as file:
            pickle.dump(user_data, file)
        if int(python_version) < 7:
            context.bot.send_message(
                chat_id=chat_id, text='PYTHON VERSION BELOW 3.7!\nBOT CAN NOT WORK.')
        context.bot.send_message(
            chat_id=chat_id, text='Your Id is saved.\nPlease send /set command to set parameters.')
    elif chat_id == user_data['user_id']:
        renew_data()
        message, encoded64 = generate_trojan_config_string()
        context.bot.send_message(chat_id=channel_id, text=encoded64)
        context.bot.send_message(chat_id=chat_id, text=message)
    else:
        message = 'You are not allowed to send messages to this bot'
        context.bot.send_message(chat_id=chat_id, text=message)

# Define status handler


def user_data_handler(update, context):
    chat_id = update.message.chat_id
    input = update.message.text.split()
    user_data = open_user_data()
    if chat_id == user_data['user_id']:
        if len(input) == 3:
            param = input[1]
            if param in ('channel_id', 'renewal_interval', 'listen_port'):
                value = int(input[2])
            else:
                value = input[2]
            user_data[param] = value
            save_to_file(user_data, 'pkl', '/root/tele_bot/user_data.pkl')
            context.bot.send_message(
                chat_id=chat_id, text=f'{param} set to {value}')
        else:
            context.bot.send_message(
                chat_id=chat_id, text="Silakan kirim pesan sebagai berikut, pertama parameter yang diinginkan, lalu spasi dan kemudian nilainya. Kirim setiap parameter secara terpisah")
            message = ("/set chat_id me / ch\n"
                       "/set channel_id dapatkan channel ID dari bot myidbot \n"
                       "/set server_IP Alamat IP server\n"
                       "/set listen_port Port singbox, misalnya : 443\n"
                       )
            context.bot.send_message(chat_id=chat_id, text=message)


# Function to handle errors
def error(bot, context):
    logging.info(f"bot {bot} caused error {context.error}")

# Define the main function


def main():
    user_data = open_user_data()
    # Create a telegram bot and add a command handler for /replace command
    updater = Updater(BOT_TOKEN)
    j = updater.job_queue
    print('Bot started')
    if user_data['renewal_interval'] != 0:
        try:
            j.run_repeating(renew_config, user_data['renewal_interval']*3600)
        except Exception as e:
            print(f'Error happened during renew:\n{e}')
    updater.dispatcher.add_handler(CommandHandler('replace', replace_handler))
    updater.dispatcher.add_handler(CommandHandler('status', status_handler))
    updater.dispatcher.add_handler(CommandHandler('run', command_handler))
    updater.dispatcher.add_handler(CommandHandler('start', start_handler))
    updater.dispatcher.add_handler(CommandHandler('set', user_data_handler))
    updater.dispatcher.add_handler(CommandHandler('log', log_handler))
    updater.dispatcher.add_error_handler(MessageHandler(Filters.all, error))
    updater.start_polling()
    updater.idle()


if __name__ == '__main__':
    main()
