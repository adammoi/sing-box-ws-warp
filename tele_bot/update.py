import os
print('--------> Downloading tele_bot.py\n\n')
os.system('curl -Lo /root/tele_bot/tele_bot.py https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/tele_bot.py')
os.system('systemctl restart tele_bot.service')
print('Done, enjoy!')
