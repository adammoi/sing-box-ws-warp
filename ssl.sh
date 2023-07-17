install_acme() {
    cd ~
    "Mulai instal skrip acme..."
    curl https://get.acme.sh | sh
    if [ $? -ne 0 ]; then
        "instalasi acme gagal"
        return 1
    else
        "acme berhasil diinstal"
    fi
    return 0
}

#standalone mode
ssl_cert_issue_standalone() {
    #cek acme.sh terlebih dahulu
    if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
        install_acme
        if [ $? -ne 0 ]; then
            "Instalasi acme gagal, silakan periksa log"
            exit 1
        fi
    fi
    #install socat
    if [[ x"${release}" == x"centos" ]]; then
        yum install socat -y
    else
        apt install socat -y
    fi
    if [ $? -ne 0 ]; then
        "Tidak dapat menginstal socat, silakan periksa log kesalahan"
        exit 1
    else
        "socat berhasil diinstal..."
    fi
    #membuat direktori untuk cert
    certPath=/root/cert
    if [ ! -d "$certPath" ]; then
        mkdir $certPath
    fi
    #dapatkan domainnya di sini, dan kami harus memverifikasinya
    read -p "Masukkan nama domain : " domain
    "Nama domain yang  dimasukkan adalah : ${domain}, verifikasi validitas nama domain sedang berlangsung..."
    #di sini kita perlu mengecek apakah sudah ada sertifikat
    local currentCert=$(~/.acme.sh/acme.sh --list | grep ${domain} | wc -l)
    if [ ${currentCert} -ne 0 ]; then
        local certInfo=$(~/.acme.sh/acme.sh --list)
        "Verifikasi validitas nama domain gagal. Lingkungan saat ini sudah memiliki sertifikat nama domain yang sesuai. Aplikasi berulang tidak diizinkan. Detail sertifikat saat ini : "
        "$certInfo"
        exit 1
    else
        "Verifikasi legalitas nama domain berhasil..."
    fi
    #dapatkan port yang dibutuhkan di sini
    WebPort=80
    read -p "Silakan masukkan port yang ingin digunakan, jika menekan Enter, port default 80 akan digunakan : " WebPort
    if [[ ${WebPort} -gt 65535 || ${WebPort} -lt 1 ]]; then
        "Port ${WebPort} yang Anda pilih adalah nilai yang tidak valid, dan port default 80 akan digunakan untuk aplikasi"
    fi
    "${WebPort} akan digunakan untuk aplikasi sertifikat, pastikan port terbuka..."
    #NOTE: Ini harus ditangani oleh pengguna
    #buka port dan matikan progres yang ditempati
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone --httpport ${WebPort}
    if [ $? -ne 0 ]; then
        "Permohonan sertifikat gagal, silakan merujuk ke pesan kesalahan untuk alasannya"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        "Aplikasi sertifikat berhasil, mulai instal sertifikat..."
    fi
    #install cert
    ~/.acme.sh/acme.sh --installcert -d ${domain} --ca-file /root/cert/ca.cer \
        --cert-file /root/cert/${domain}.cer --key-file /root/cert/${domain}.key \
        --fullchain-file /root/cert/fullchain.cer

    if [ $? -ne 0 ]; then
        "Instalasi sertifikat gagal, skrip berakhir"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        "Sertifikat telah berhasil diinstal, dan pembaruan otomatis diaktifkan..."
    fi
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    if [ $? -ne 0 ]; then
        "Setup update otomatis gagal, skrip berakhir"
        ls -lah cert
        chmod 755 $certPath
        exit 1
    else
        "Sertifikat telah diinstal dan pembaruan otomatis telah diaktifkan, informasi spesifiknya adalah sebagai berikut :"
        ls -lah cert
        chmod 755 $certPath
    fi

}

ssl_cert_issue_by_cloudflare() {
    echo -E ""
    "******Petunjuk******"
    "Skrip ini akan menggunakan skrip Acme untuk mengajukan sertifikat. Saat menggunakannya, Anda harus memastikan:"
    "1. Ketahui alamat email yang terdaftar di Cloudflare"
    "2. Ketahui Global API Key Cloudflare"
    "3. Nama domain telah di-resolve ke server saat ini oleh Cloudflare"
    "4. Jalur penginstalan default untuk skrip ini untuk mengajukan sertifikat adalah direktori /root/cert"
    confirm "Saya telah mengkonfirmasi syarat di atas [y/n] : " "y"
    if [ $? -eq 0 ]; then
        install_acme
        if [ $? -ne 0 ]; then
            LOGE "Tidak dapat memasang acme, harap periksa log kesalahan"
            exit 1
        fi
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        if [ ! -d "$certPath" ]; then
            mkdir $certPath
        fi
        "Silakan isi nama domain : "
        read -p "Input your domain here : " CF_Domain
        "Nama domain disetel ke : ${CF_Domain}, verifikasi validitas nama domain sedang berlangsung..."
        #di sini kita perlu mengecek apakah sudah ada sertifikat
        currentCert=$(~/.acme.sh/acme.sh --list | grep ${CF_Domain} | wc -l)
        if [ ${currentCert} -ne 0 ]; then
            local certInfo=$(~/.acme.sh/acme.sh --list)
            LOGE "Sertifikat telah diinstal dan pembaruan otomatis telah diaktifkan, informasi spesifiknya adalah sebagai berikut : "
            "$certInfo"
            exit 1
        else
            "Verifikasi legalitas nama domain berhasil..."
        fi
        "Silakan atur API Key:"
        read -p "Input your key here : " CF_GlobalKey
        "API Key Anda:${CF_GlobalKey}"
        "Silakan atur alamat email Anda yang terdaftar : "
        read -p "Masukkan email Anda di sini : " CF_AccountEmail
        "Alamat email Anda adalah:${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "Gagal mengubah CA Default ke Let's Encrypt, skrip berakhir"
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "Penerbitan sertifikat gagal, skrip berakhir"
            rm -rf ~/.acme.sh/${CF_Domain}
            exit 1
        else
            "Sertifikat berhasil diterbitkan, instalasi sedang berlangsung..."
        fi
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
            --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
            --fullchain-file /root/cert/fullchain.cer
        if [ $? -ne 0 ]; then
            LOGE "Instalasi sertifikat gagal, skrip berakhir"
            rm -rf ~/.acme.sh/${CF_Domain}
            exit 1
        else
            "Sertifikat telah berhasil diinstal, dan pembaruan otomatis diaktifkan..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "Setup update otomatis gagal, skrip berakhir"
            ls -lah cert
            chmod 755 $certPath
            exit 1
        else
            "Sertifikat telah diinstal dan pembaruan otomatis telah diaktifkan, informasi spesifiknya adalah sebagai berikut : "
            ls -lah cert
            chmod 755 $certPath
        fi
    else
        show_menu
    fi
}


echo -E ""
echo "******Petunjuk******"
echo "Skrip ini menyediakan dua cara untuk mengimplementasikan penerbitan sertifikat, dan jalur penginstalan sertifikat adalah /root/cert"
echo "Metode 1: acme standalone mode, port harus tetap terbuka"
echo "Metode 2: mode API DNS acme, perlu menyediakan Cloudflare Global API Key"
echo "Jika nama domain adalah nama domain gratis, disarankan untuk menggunakan metode 1 untuk mendaftar"
echo "Jika nama domain bukan nama domain gratis dan Cloudflare digunakan untuk penyelesaian, gunakan metode 2 untuk menerapkan"
    read -p "Silahkan pilih metode yang ingin digunakan, masukkan angka 1 atau 2 dan tekan Enter": method
    echo "Metode yang Anda gunakan adalah : ${method}"

    case "${method}" in
    "1")
        ssl_cert_issue_standalone
        ;;
    "2")
        ssl_cert_issue_by_cloudflare
        ;;
    *)
        echo "Input tidak valid, harap periksa input Anda, skrip berakhir"
        exit 1
        ;;
esac
