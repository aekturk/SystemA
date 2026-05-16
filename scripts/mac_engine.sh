#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "Root yetkisi gerekiyor. Sudo ile yeniden baslatiliyor..."
    echo "Root privileges required. Restarting with sudo..."
    sudo "$0" "$@"
    exit $?
fi

MODE="CLIENT"
CURRENT_USER=$(stat -f "%Su" /dev/console)
LOGFILE="../logs/mac_engine_$(date +%Y%m%d_%H%M%S).log"

echo "============================================" > $LOGFILE
echo "SystemA v.3.1 macOS Engine Log" >> $LOGFILE
echo "Started: $(date)" >> $LOGFILE
echo "============================================" >> $LOGFILE

echo ""
echo "[SystemA v.3.1] macOS Engine Baslatiliyor..."
echo "[SystemA v.3.1] macOS Engine Starting..."
echo ""

# Install Homebrew if not present
echo "[1/18] Homebrew kontrol ediliyor..."
echo "[1/18] Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Homebrew yukleniyor..."
    echo "Installing Homebrew..."
    sudo -u "$CURRENT_USER" -H /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a $LOGFILE
fi

# Update Homebrew
echo "[2/18] Homebrew guncelleniyor..."
echo "[2/18] Updating Homebrew..."
sudo -u "$CURRENT_USER" -H brew update 2>&1 | tee -a $LOGFILE
sudo -u "$CURRENT_USER" -H brew upgrade 2>&1 | tee -a $LOGFILE

# Install packages
echo "[3/18] Paketler yukleniyor..."
echo "[3/18] Installing packages..."
sudo -u "$CURRENT_USER" -H brew install python@3.12 2>&1 | tee -a $LOGFILE
sudo -u "$CURRENT_USER" -H brew install --cask anydesk 2>&1 | tee -a $LOGFILE
sudo -u "$CURRENT_USER" -H brew install --cask rustdesk 2>&1 | tee -a $LOGFILE
sudo -u "$CURRENT_USER" -H brew install dotnet-sdk 2>&1 | tee -a $LOGFILE

# SSH Server mode
if [ "$MODE" = "SERVER" ]; then
    echo "[*] Server modu: SSH etkinlestiriliyor..."
    systemsetup -setremotelogin on 2>&1 | tee -a $LOGFILE
fi

# Backup /etc
echo "[4/18] /etc yedekleniyor..."
echo "[4/18] Backing up /etc..."
tar -czf /Users/Shared/etc_backup.tar.gz /etc >/dev/null 2>&1

# Clean Homebrew cache
echo "[5/18] Homebrew ortbellegi temizleniyor..."
echo "[5/18] Cleaning Homebrew cache..."
sudo -u "$CURRENT_USER" -H brew cleanup -s 2>&1 | tee -a $LOGFILE
rm -rf /Library/Caches/Homebrew/* 2>/dev/null

# Clear memory
echo "[6/18] Bellek temizleniyor..."
echo "[6/18] Clearing memory..."
sync && purge 2>&1 | tee -a $LOGFILE

# Clear trash and temp
echo "[7/18] Cop ve gecici dosyalar temizleniyor..."
echo "[7/18] Cleaning trash and temp files..."
rm -rf /Users/*/.Trash/* 2>/dev/null
rm -rf /private/var/folders/*/*/*/* 2>/dev/null
rm -rf /private/var/tmp/* 2>/dev/null
rm -rf /tmp/* 2>/dev/null

# Clear browser caches
echo "[8/18] Tarayici ortbellegi temizleniyor..."
echo "[8/18] Clearing browser caches..."
rm -rf /Users/*/Library/Caches/Google/Chrome/* 2>/dev/null
rm -rf /Users/*/Library/Caches/Firefox/* 2>/dev/null
rm -rf /Users/*/Library/Caches/Microsoft\ Edge/* 2>/dev/null
rm -rf /Users/*/Library/Caches/* 2>/dev/null

# Clear diagnostic reports
echo "[9/18] Tani raporlari temizleniyor..."
echo "[9/18] Clearing diagnostic reports..."
rm -rf /Library/Logs/DiagnosticReports/* 2>/dev/null
rm -rf /Users/*/Library/Logs/DiagnosticReports/* 2>/dev/null

# Verify disk
echo "[10/18] Disk dogrulaniyor..."
echo "[10/18] Verifying disk..."
diskutil verifyVolume / 2>&1 | tee -a $LOGFILE

# TRIM / Secure Erase
echo "[11/18] Disk bakimi yapiliyor..."
echo "[11/18] Performing disk maintenance..."
diskutil apfs trim / >/dev/null 2>&1 || diskutil secureErase freespace 0 / 2>&1 | tee -a $LOGFILE

# Flush DNS
echo "[12/18] DNS ortbellegi temizleniyor..."
echo "[12/18] Flushing DNS cache..."
sudo killall -HUP mDNSResponder 2>&1 | tee -a $LOGFILE

# Disk info
echo "[13/18] Disk bilgisi..."
echo "[13/18] Disk information..."
df -h / 2>&1 | tee -a $LOGFILE

echo ""
echo "============================================" >> $LOGFILE
echo "macOS Engine Completed: $(date)" >> $LOGFILE
echo "============================================" >> $LOGFILE
echo ""
echo "[SystemA v.3.1] macOS Engine tamamlandi!"
echo "[SystemA v.3.1] macOS Engine completed!"
echo ""
echo "Log dosyasi / Log file: $LOGFILE"
echo ""
read -p "Devam etmek icin Enter'a basin / Press Enter to continue..."
