@echo off
setlocal enabledelayedexpansion

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set MODE=CLIENT
set LOGFILE=..\logs\win_engine_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
echo ============================================ > %LOGFILE%
echo SystemA v.3.1 Windows Engine Log >> %LOGFILE%
echo Started: %date% %time% >> %LOGFILE%
echo ============================================ >> %LOGFILE%

echo.
echo [SystemA v.3.1] Windows Engine Baslatiliyor...
echo [SystemA v.3.1] Windows Engine Starting...
echo.

:: Check for winget
where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo Winget bulunamadi. Sistem geri yukleme moduna geciliyor...
    echo Winget not found. Switching to system restore mode...
    goto SYSTEM_RESTORE
)

:: Update all packages via winget
echo [1/35] Winget paket guncellemeleri kontrol ediliyor...
echo [1/35] Checking winget package updates...
winget upgrade --all 2>>%LOGFILE%
echo Winget upgrade completed >> %LOGFILE%

:: Install Python
echo [2/35] Python 3.12 yukleniyor...
echo [2/35] Installing Python 3.12...
winget install -e --id Python.Python.3.12 2>>%LOGFILE%

:: Install AnyDesk
echo [3/35] AnyDesk yukleniyor...
echo [3/35] Installing AnyDesk...
winget install -e --id AnyDesk.AnyDesk 2>>%LOGFILE%

:: Install RustDesk
echo [4/35] RustDesk yukleniyor...
echo [4/35] Installing RustDesk...
winget install -e --id RustDesk.RustDesk 2>>%LOGFILE%

:: Install .NET Runtime
echo [5/35] .NET Runtime yukleniyor...
echo [5/35] Installing .NET Runtime...
powershell -Command "Invoke-WebRequest -Uri https://aka.ms/dotnet/10.0/windowsdesktop-runtime-win-x64.exe -OutFile dotnet.exe" 2>>%LOGFILE%
start /wait dotnet.exe /quiet /norestart 2>>%LOGFILE%
del dotnet.exe 2>nul

:: Server mode SSH
if "%MODE%"=="SERVER" (
    echo Server modu: SSH yukleniyor...
    winget install OpenSSH.OpenSSH 2>>%LOGFILE%
)

:SYSTEM_RESTORE
:: Enable System Restore
echo [6/35] Sistem geri yukleme noktasi olusturuluyor...
echo [6/35] Creating system restore point...
powershell -command "Enable-ComputerRestore -Drive 'C:\'" 2>>%LOGFILE%
powershell -command "Checkpoint-Computer -Description 'System Backup Point' -RestorePointType 'MODIFY_SETTINGS'" 2>>%LOGFILE%

:: Configure VSS
echo [7/35] Volume Shadow Copy yapilandiriliyor...
echo [7/35] Configuring Volume Shadow Copy...
sc config VSS start= auto 2>>%LOGFILE%
net start VSS 2>>%LOGFILE%

:: Clean old shadow copies
echo [8/35] Eski golge kopyalar temizleniyor...
echo [8/35] Cleaning old shadow copies...
for /f "tokens=*" %%i in ('vssadmin list shadows ^| find "Shadow Copy ID"') do set last=%%i
for /f "tokens=*" %%i in ('vssadmin list shadows ^| find "Shadow Copy ID"') do (
    if not "%%i"=="%last%" vssadmin delete shadows /Shadow=%%i /quiet 2>>%LOGFILE%
)

:: Registry backup
echo [9/35] Kayit defteri yedekleniyor...
echo [9/35] Backing up registry...
reg export HKLM\SOFTWARE C:\RegistryBackup.reg /y 2>>%LOGFILE%

:: Configure Disk Cleanup
echo [10/35] Disk temizleme yapilandiriliyor...
echo [10/35] Configuring disk cleanup...
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old Chkdsk Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>>%LOGFILE%

:: Run Disk Cleanup
echo [11/35] Disk temizleme calistiriliyor...
echo [11/35] Running disk cleanup...
cleanmgr /sagerun:1 2>>%LOGFILE%

:: Force garbage collection
echo [12/35] Bellek temizleniyor...
echo [12/35] Cleaning memory...
powershell -Command "[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()" 2>>%LOGFILE%

:: Clean Recycle Bin
echo [13/35] Geri donusum kutusu temizleniyor...
echo [13/35] Cleaning recycle bin...
rd /s /q C:\$Recycle.Bin 2>nul

:: Configure CPU
echo [14/35] CPU yapilandirmasi...
echo [14/35] CPU configuration...
bcdedit /set {current} numproc %NUMBER_OF_PROCESSORS% 2>>%LOGFILE%

:: Clear browser caches
echo [15/35] Tarayici ortbellegi temizleniyor...
echo [15/35] Clearing browser cache...
rd /s /q "C:\Users\%username%\AppData\Local\Microsoft\Edge\User Data\Default\Cache" 2>nul
rd /s /q "C:\Users\%username%\AppData\Local\Google\Chrome\User Data\Default\Cache" 2>nul
rd /s /q "C:\Users\%username%\AppData\Local\Mozilla\Firefox\Profiles" 2>nul

:: Clear system caches
echo [16/35] Sistem ortbellegi temizleniyor...
echo [16/35] Clearing system cache...
rd /s /q C:\Windows\Prefetch 2>nul
rd /s /q C:\Users\%username%\AppData\Local\Temp 2>nul
rd /s /q C:\Windows\Temp 2>nul
rd /s /q C:\Windows\SoftwareDistribution\Download 2>nul
rd /s /q C:\Windows\SoftwareDistribution\DeliveryOptimization 2>nul
rd /s /q C:\Users\%username%\AppData\Local\Microsoft\Windows\Explorer 2>nul

:: Clear temp files
echo [17/35] Gecici dosyalar temizleniyor...
echo [17/35] Cleaning temporary files...
del /s /f /q %systemroot%\Temp\*.* 2>nul
del /s /f /q %temp%\*.* 2>nul

:: Clear error reports
echo [18/35] Hata raporlari temizleniyor...
echo [18/35] Cleaning error reports...
del /f /s /q "%PROGRAMDATA%\Microsoft\Windows\WER\ReportArchive\*.*" >nul 2>&1
del /f /s /q "%PROGRAMDATA%\Microsoft\Windows\WER\ReportQueue\*.*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\CrashDumps\*.*" >nul 2>&1

:: DISM operations
echo [19/35] DISM sistem sagligi kontrol ediliyor...
echo [19/35] DISM system health check...
dism /online /cleanup-image /checkhealth 2>>%LOGFILE%
echo [20/35] DISM taramasi...
echo [20/35] DISM scan...
dism /online /cleanup-image /scanhealth 2>>%LOGFILE%
echo [21/35] DISM onarimi...
echo [21/35] DISM restore...
dism /online /cleanup-image /restorehealth 2>>%LOGFILE%
echo [22/35] DISM bilesen temizligi...
echo [22/35] DISM component cleanup...
dism /online /cleanup-image /startcomponentcleanup /resetbase 2>>%LOGFILE%

:: SFC scan
echo [23/35] SFC sistem dosyasi denetleyicisi...
echo [23/35] SFC system file checker...
sfc /scannow 2>>%LOGFILE%

:: CHKDSK
echo [24/35] CHKDSK disk kontrolu...
echo [24/35] CHKDSK disk check...
chkdsk /f /r /x 2>>%LOGFILE%

:: Defrag
echo [25/35] Disk birlestirme...
echo [25/35] Disk defragmentation...
defrag c: /O 2>>%LOGFILE%

:: Network reset
echo [26/35] Ag ayarlari sifirlaniyor...
echo [26/35] Resetting network settings...
netsh winhttp reset proxy 2>>%LOGFILE%

:: Windows Update reset
echo [27/35] Windows Update bilesenleri sifirlaniyor...
echo [27/35] Resetting Windows Update components...
net stop wuauserv 2>>%LOGFILE%
net stop cryptSvc 2>>%LOGFILE%
net stop bits 2>>%LOGFILE%
net stop msiserver 2>>%LOGFILE%

ren C:\Windows\SoftwareDistribution SoftwareDistribution.old 2>>%LOGFILE%
ren C:\Windows\System32\catroot2 catroot2.old 2>>%LOGFILE%
del /s /f /q C:\Windows\SoftwareDistribution\Download\* 2>nul

net start wuauserv 2>>%LOGFILE%
net start cryptSvc 2>>%LOGFILE%
net start bits 2>>%LOGFILE%
net start msiserver 2>>%LOGFILE%

:: Clear event logs
echo [28/35] Olay gunlukleri temizleniyor...
echo [28/35] Clearing event logs...
wevtutil cl Application 2>>%LOGFILE%
wevtutil cl System 2>>%LOGFILE%
wevtutil cl Security 2>>%LOGFILE%

:: Network reset
echo [29/35] DNS ve ag sifirlaniyor...
echo [29/35] DNS and network reset...
ipconfig /flushdns 2>>%LOGFILE%
netsh winsock reset 2>>%LOGFILE%
netsh int ip reset 2>>%LOGFILE%

:: Disable SysMain
echo [30/35] SysMain devre disi birakiliyor...
echo [30/35] Disabling SysMain...
sc stop SysMain 2>>%LOGFILE%
sc config SysMain start= disabled 2>>%LOGFILE%

:: Power settings
echo [31/35] Guc ayarlari yapilandiriliyor...
echo [31/35] Configuring power settings...
powercfg -h off 2>>%LOGFILE%
powercfg /energy 2>>%LOGFILE%
powercfg /batteryreport 2>>%LOGFILE%
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>>%LOGFILE%

:: Windows Defender update
echo [32/35] Windows Defender guncelleniyor...
echo [32/35] Updating Windows Defender...
if exist "%ProgramFiles%\Windows Defender\MpCmdRun.exe" (
    "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate 2>>%LOGFILE%
)

:: Disk info
echo [33/35] Disk bilgisi...
echo [33/35] Disk information...
fsutil volume diskfree c: 2>>%LOGFILE%

echo.
echo ============================================ >> %LOGFILE%
echo Windows Engine Completed: %date% %time% >> %LOGFILE%
echo ============================================ >> %LOGFILE%
echo.
echo [SystemA v.3.1] Windows Engine tamamlandi!
echo [SystemA v.3.1] Windows Engine completed!
echo.
echo Log dosyasi / Log file: %LOGFILE%
echo.
pause
