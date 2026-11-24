# PoC CVE 2019 14287
Tugas Besar Pengantar Keamanan Komputasi &amp; Jaringan

# Bedah & Simulasi CVE-2019-14287 (Sudo Privilege Escalation)

> **Disclaimer:** Proyek dan skrip demonstrasi dalam repositori ini dibuat khusus untuk keperluan edukasi akademik pada lingkungan mesin virtual (VM) terisolasi milik sendiri. Penggunaan teknik eksploitasi terhadap sistem tanpa izin adalah tindakan ilegal.
> 
> 

## Deskripsi Proyek

Repositori ini berisi dokumentasi, skrip otomasi lab, dan materi pendukung untuk pembuatan video edukasi keamanan siber berdurasi ~15 menit mengenai kerentanan **CVE-2019-14287**. Tujuan utama dari proyek ini meliputi:

* **Analisis Teknis & Framework:** Membedah akar masalah kerentanan pada utilitas `sudo` serta memetakannya ke standar industri (**CWE**, **CVSS**, dan **MITRE ATT&CK**).


* **Simulasi Lab Terisolasi:** Mendemonstrasikan alur serangan *privilege escalation* secara langsung di lingkungan VM Ubuntu yang terisolasi (*Host-Only* / *Internal Network*).


* **Mitigasi & Deteksi:** Menerapkan *patch* resmi untuk menutup celah keamanan sekaligus membahas cara deteksi serangan dari sisi *defender* (*Blue Team*).



## Tim Penyusun & Pembagian Peran

* **Karel:** Analisis latar belakang CVE, akar masalah kode (CWE-269 & CWE-681), serta pemetaan CVSS, MITRE ATT&CK, dan Cyber Kill Chain.
* **Defandi:** Perancangan skrip lab otomatis serta demonstrasi eksploitasi dan *patching* langsung di dalam VM.
* **Sundariko:** Pembahasan strategi mitigasi, *workaround* konfigurasi, deteksi log sistem, dan kesimpulan.

## Profil Singkat Kerentanan

* **ID Kerentanan:** CVE-2019-14287
* **Komponen Terdampak:** `sudo` versi `< 1.8.28` pada sistem operasi Linux/Unix
* **Skor Keparahan:** CVSS v3.1 **8.8 (High)**
* **Kelemahan Utama:** CWE-269 (*Improper Privilege Management*) & CWE-681 (*Incorrect Conversion between Numeric Types*)
* **Taktik & Teknik ATT&CK:** TA0004 (*Privilege Escalation*) — T1548.003 (*Sudo and Sudo Caching*) & T1068

## Cara Kerja Lab & Alur Demo

Skrip `cve_2019_14287.sh` mengisolasi instalasi `sudo` rentan (`1.8.27`) ke direktori `/usr/local` agar tidak merusak sistem utama VM, lalu menjalankan 5 tahapan demonstrasi:

1. **Kondisi Awal:** Memverifikasi akun pengguna non-root (`korban`) dengan aturan `sudoers` `(ALL, !root)` dan membuktikan bahwa akses `sudo /bin/bash` ditolak.


2. **Eksploitasi:** Memanfaatkan celah integer UID `-1` (`sudo -u#-1 /bin/bash`) untuk melewati batasan `!root`.


3. **Bukti Dampak:** Memverifikasi kenaikan hak akses menjadi `root` (`uid=0`) dan membaca file sensitif `/etc/shadow`.


4. **Patching:** Memperbarui paket `sudo` ke versi aman `1.8.28` secara luring (*offline*).


5. **Uji Ulang:** Menjalankan kembali perintah eksploitasi yang sama dan membuktikan sistem memblokirnya (`sudo: unknown user: #-1`).



## Panduan Penggunaan Skrip

1. **Persiapan Lab (membutuhkan koneksi internet / mode NAT):**
```bash
sudo bash cve_2019_14287.sh setup

```


2. **Isolasi Jaringan & Snapshot:**
Ubah pengaturan jaringan VM ke **Host-Only Adapter** atau **Internal Network**, lalu ambil **Snapshot** sebelum memulai pengujian.


3. **Menjalankan Demo Interaktif (mode luring / offline):**
```bash
sudo bash cve_2019_14287.sh demo

```


4. **Mengulang Pengujian (opsional):**
```bash
sudo bash cve_2019_14287.sh reset

```



## Referensi

* [NVD - CVE-2019-14287](https://nvd.nist.gov/vuln/detail/CVE-2019-14287)


* [Sudo Security Advisory - Potential bypass of Runas user restrictions](https://www.sudo.ws/security/advisories/minus_1_uid/)
* [MITRE ATT&CK - T1548.003](https://attack.mitre.org/techniques/T1548/003/)
