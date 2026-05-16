#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "Root yetkisi gerekiyor. Sudo ile yeniden baslatiliyor..."
    echo "Root privileges required. Restarting with sudo..."
    sudo "$0" "$@"
    exit $?
fi

MODE="CLIENT"
export DEBIAN_FRONTEND=noninteractive
LOGFILE="../logs/linux_engine_$(date +%Y%m%d_%H%M%S).log"

echo "============================================" > $LOGFILE
echo "SystemA v.3.1 Linux Engine Log" >> $LOGFILE
echo "Started: $(date)" >> $LOGFILE
echo "============================================" >> $LOGFILE

echo ""
echo "[SystemA v.3.1] Linux Engine Baslatiliyor..."
echo "[SystemA v.3.1] Linux Engine Starting..."
echo ""

# System Update
echo "[1/20] Paket listesi guncelleniyor..."
echo "[1/20] Updating package lists..."
apt-get update -y 2>&1 | tee -a $LOGFILE

echo "[2/20] Paketler guncelleniyor..."
echo "[2/20] Upgrading packages..."
apt-get upgrade -y 2>&1 | tee -a $LOGFILE

echo "[3/20] Sistem guncelleniyor..."
echo "[3/20] Dist-upgrade..."
apt-get dist-upgrade -y 2>&1 | tee -a $LOGFILE

# Install Python
echo "[4/20] Python yukleniyor..."
echo "[4/20] Installing Python..."
apt-get install -y python3 python3-pip 2>&1 | tee -a $LOGFILE

# Install AnyDesk
echo "[5/20] AnyDesk yukleniyor..."
echo "[5/20] Installing AnyDesk..."
wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | gpg --dearmor --yes -o /usr/share/keyrings/anydesk.gpg 2>&1 | tee -a $LOGFILE
echo "deb [signed-by=/usr/share/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk.list
apt-get update -y 2>&1 | tee -a $LOGFILE
apt-get install -y anydesk 2>&1 | tee -a $LOGFILE

# Install RustDesk
echo "[6/20] RustDesk yukleniyor..."
echo "[6/20] Installing RustDesk..."
wget -q https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.deb -O rustdesk.deb 2>&1 | tee -a $LOGFILE
dpkg -i rustdesk.deb 2>&1 | tee -a $LOGFILE
apt-get install -f -y 2>&1 | tee -a $LOGFILE
rm rustdesk.deb

# Install .NET
echo "[7/20] .NET Runtime yukleniyor..."
echo "[7/20] Installing .NET Runtime..."
apt-get install -y dotnet-runtime-8.0 2>&1 | tee -a $LOGFILE

# SSH Server mode
if [ "$MODE" = "SERVER" ]; then
    echo "[*] Server modu: SSH yukleniyor..."
    apt-get install -y openssh-server 2>&1 | tee -a $LOGFILE
    systemctl enable ssh 2>&1 | tee -a $LOGFILE
    systemctl start ssh 2>&1 | tee -a $LOGFILE
fi

# Backup /etc
echo "[8/20] /etc yedekleniyor..."
echo "[8/20] Backing up /etc..."
tar -czf /etc_backup.tar.gz /etc >/dev/null 2>&1

# Clear browser history
echo "[9/20] Tarayici gecmisi temizleniyor..."
echo "[9/20] Clearing browser history..."
find /home -name "History" -exec rm -f {} \; 2>/dev/null
find /home -name "Web Data" -exec rm -f {} \; 2>/dev/null

# Clean package cache
echo "[10/20] Paket ortbellegi temizleniyor..."
echo "[10/20] Cleaning package cache..."
apt-get autoclean -y 2>&1 | tee -a $LOGFILE
apt-get autoremove --purge -y 2>&1 | tee -a $LOGFILE
apt-get clean -y 2>&1 | tee -a $LOGFILE

# Clear memory cache
echo "[11/20] Bellek ortbellegi temizleniyor..."
echo "[11/20] Clearing memory cache..."
sync && echo 3 > /proc/sys/vm/drop_caches 2>&1 | tee -a $LOGFILE

# Clear trash and temp
echo "[12/20] Cop ve gecici dosyalar temizleniyor..."
echo "[12/20] Cleaning trash and temp files..."
rm -rf /home/*/.local/share/Trash/* 2>/dev/null
rm -rf /root/.local/share/Trash/* 2>/dev/null
rm -rf /tmp/* 2>/dev/null
rm -rf /var/tmp/* 2>/dev/null

# Clear browser caches
echo "[13/20] Tarayici ortbellegi temizleniyor..."
echo "[13/20] Clearing browser caches..."
rm -rf /home/*/.cache/google-chrome/* 2>/dev/null
rm -rf /home/*/.cache/mozilla/firefox/* 2>/dev/null
rm -rf /home/*/.cache/microsoft-edge-dev/* 2>/dev/null

# Clear crash reports
echo "[14/20] Hata raporlari temizleniyor..."
echo "[14/20] Clearing crash reports..."
rm -rf /var/crash/* 2>/dev/null
rm -rf /var/metrics/* 2>/dev/null

# Fix packages
echo "[15/20] Paketler yapilandiriliyor..."
echo "[15/20] Configuring packages..."
dpkg --configure -a 2>&1 | tee -a $LOGFILE
apt-get check 2>&1 | tee -a $LOGFILE

# Filesystem operations
echo "[16/20] Dosya sistemi bakimi..."
echo "[16/20] Filesystem maintenance..."
touch /forcefsck 2>/dev/null
fstrim -av 2>&1 | tee -a $LOGFILE

# Journal cleanup
echo "[17/20] Sistem gunlugu temizleniyor..."
echo "[17/20] Cleaning system journal..."
journalctl --vacuum-time=1d 2>&1 | tee -a $LOGFILE

# DNS cache flush
echo "[18/20] DNS ortbellegi temizleniyor..."
echo "[18/20] Flushing DNS cache..."
if systemctl is-active --quiet systemd-resolved; then
    resolvectl flush-caches 2>&1 | tee -a $LOGFILE
fi

# Restart networking
echo "[19/20] Ag servisi yeniden baslatiliyor..."
echo "[19/20] Restarting network service..."
systemctl restart networking >/dev/null 2>&1 || systemctl restart NetworkManager >/dev/null 2>&1

# Disk info
echo "[20/20] Disk bilgisi..."
echo "[20/20] Disk information..."
df -h / 2>&1 | tee -a $LOGFILE

echo ""
echo "============================================" >> $LOGFILE
echo "Linux Engine Completed: $(date)" >> $LOGFILE
echo "============================================" >> $LOGFILE
echo ""
echo "[SystemA v.3.1] Linux Engine tamamlandi!"
echo "[SystemA v.3.1] Linux Engine completed!"
echo ""
echo "Log dosyasi / Log file: $LOGFILE"
echo ""
read -p "Devam etmek icin Enter'a basin / Press Enter to continue..."
