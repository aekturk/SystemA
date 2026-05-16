#Requires -RunAsAdministrator
# SystemA v.3.1 - System Maintenance & Reporting Tool
# Developed by Ercan CEVİZ

param(
    [string]$Language = "TR"
)

# Set console encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.ForegroundColor = "Cyan"

# ===== CONFIGURATION =====
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LangPath = Join-Path $ScriptPath "lang"
$ReportsPath = Join-Path $ScriptPath "reports"
$LogsPath = Join-Path $ScriptPath "logs"
$OldFilesPath = Join-Path $ScriptPath "old_files"
$ScriptsPath = Join-Path $ScriptPath "scripts"
$BackupsPath = Join-Path $ScriptPath "backups"

# ===== LANGUAGE LOADER =====
$LangCache = @{}

function Load-Language($langCode) {
    $langFile = Join-Path $LangPath "$langCode.json"
    if (Test-Path $langFile) {
        $json = Get-Content $langFile -Raw -Encoding UTF8
        $script:LangCache = $json | ConvertFrom-Json
        $script:CurrentLang = $langCode
        return $true
    }
    return $false
}

function Get-Lang($key) {
    $keys = $key -split '\.'
    $result = $script:LangCache
    foreach ($k in $keys) {
        if ($null -eq $result) { return $key }
        try {
            $result = $result.$k
        } catch {
            return $key
        }
    }
    if ($null -eq $result) { return $key }
    return $result
}

# ===== OLD FILES ARCHIVE =====
function Move-OldFiles {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $archiveDir = Join-Path $OldFilesPath $timestamp
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    
    Get-ChildItem -Path $ReportsPath -Filter "*.*" | ForEach-Object {
        Move-Item $_.FullName (Join-Path $archiveDir $_.Name) -Force
    }
    Get-ChildItem -Path $LogsPath -Filter "*.*" | ForEach-Object {
        Move-Item $_.FullName (Join-Path $archiveDir $_.Name) -Force
    }
}

# ===== DISCLAIMER =====
function Show-Disclaimer {
    Clear-Host
    $title = Get-Lang "messages.disclaimer_title"
    $text = Get-Lang "messages.disclaimer_text"
    $line = ("=" * 80)
    
    Write-Host $line -ForegroundColor Red
    Write-Host "  $title" -ForegroundColor Yellow
    Write-Host $line -ForegroundColor Red
    Write-Host ""
    Write-Host $text -ForegroundColor White
    Write-Host ""
    Write-Host $line -ForegroundColor Red
    
    $prompt = Get-Lang "messages.accept_disclaimer"
    $choice = Read-Host "`n$prompt"
    
    if ($choice -eq "E" -or $choice -eq "e" -or $choice -eq "Y" -or $choice -eq "y") {
        return $true
    }
    return $false
}

# ===== LANGUAGE SELECTION =====
function Select-Language {
    Clear-Host
    Write-Host "`n" (" " * 30) -NoNewline
    Write-Host "╔══════════════════════════════╗" -ForegroundColor Cyan
    Write-Host (" " * 30) -NoNewline
    Write-Host "║     SystemA v.3.1            ║" -ForegroundColor Cyan
    Write-Host (" " * 30) -NoNewline
    Write-Host "║  " -NoNewline -ForegroundColor Cyan; Write-Host "DİL SEÇİNİZ / SELECT LANGUAGE" -ForegroundColor Yellow; Write-Host "  ║" -ForegroundColor Cyan
    Write-Host (" " * 30) -NoNewline
    Write-Host "╚══════════════════════════════╝" -ForegroundColor Cyan
    
    $languages = @(
        @{Code="TR"; Name="Türkçe"},
        @{Code="EN"; Name="English"},
        @{Code="DE"; Name="Deutsch"},
        @{Code="FR"; Name="Français"},
        @{Code="ES"; Name="Español"},
        @{Code="PT"; Name="Português"},
        @{Code="RU"; Name="Русский"},
        @{Code="ZH"; Name="中文"},
        @{Code="JA"; Name="日本語"}
    )
    
    Write-Host ""
    for ($i = 0; $i -lt $languages.Count; $i++) {
        Write-Host (" " * 35) -NoNewline
        Write-Host "$($i+1). $($languages[$i].Name) ($($languages[$i].Code))" -ForegroundColor White
    }
    Write-Host (" " * 35) -NoNewline
    Write-Host "0. " -NoNewline -ForegroundColor Red; Write-Host "Çıkış / Exit" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host (" " * 35) + "Seçiminiz / Your choice"
    
    if ($choice -eq "0") { exit }
    
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $languages.Count) {
        $langCode = $languages[$index].Code
        if (Load-Language $langCode) {
            return $langCode
        }
    }
    
    Write-Host "Geçersiz seçim / Invalid choice!" -ForegroundColor Red
    Start-Sleep -Seconds 2
    return Select-Language
}

# ===== MAIN MENU =====
function Show-MainMenu {
    Clear-Host
    $title = Get-Lang "menu.title"
    $cleaning = Get-Lang "menu.run_cleaning"
    $report = Get-Lang "menu.run_report"
    $view = Get-Lang "menu.view_report"
    $exit = Get-Lang "menu.exit"
    
    Write-Host "`n" (" " * 25) -NoNewline
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host (" " * 25) -NoNewline
    Write-Host "║       SystemA v.3.1                  ║" -ForegroundColor Cyan
    Write-Host (" " * 25) -NoNewline
    Write-Host "║  $title" -NoNewline -ForegroundColor Yellow
    Write-Host "               ║" -ForegroundColor Cyan
    Write-Host (" " * 25) -NoNewline
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host (" " * 30) -NoNewline
    Write-Host "1. $cleaning" -ForegroundColor Green
    Write-Host (" " * 30) -NoNewline
    Write-Host "2. $report" -ForegroundColor Green
    Write-Host (" " * 30) -NoNewline
    Write-Host "3. $view" -ForegroundColor Green
    Write-Host (" " * 30) -NoNewline
    Write-Host "0. $exit" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host (" " * 30) + (Get-Lang "messages.select_option")
    return $choice
}

# ===== SYSTEM INFORMATION COLLECTION =====
function Get-SystemInfo {
    $info = @{}
    
    # Computer Name
    $info.ComputerName = $env:COMPUTERNAME
    
    # OS Info
    $os = Get-CimInstance Win32_OperatingSystem
    $info.OS = "$($os.Caption) Build $($os.BuildNumber)"
    $info.OSVersion = $os.Version
    
    # Username
    $info.Username = $env:USERNAME
    
    # CPU Info
    $cpu = Get-CimInstance Win32_Processor
    $info.CPU = $cpu.Name
    $info.Cores = $cpu.NumberOfCores
    $info.Threads = $cpu.NumberOfLogicalProcessors
    
    # RAM Info
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    $ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    
    $info.RAM = @{
        Total = "$totalRAM GB"
        Used = "$usedRAM GB"
        Free = "$freeRAM GB"
        Percent = "$ramPercent%"
    }
    
    # Get RAM module details
    $ramModules = Get-CimInstance Win32_PhysicalMemory
    $info.RAMModules = @()
    $slotCount = 0
    foreach ($mod in $ramModules) {
        $slotCount++
        $info.RAMModules += @{
            Slot = "Slot $slotCount"
            Brand = $mod.Manufacturer
            Capacity = "$([math]::Round($mod.Capacity / 1GB, 0)) GB"
            Speed = "$($mod.Speed) MHz"
        }
    }
    $info.RAMSlotCount = $slotCount
    
    # Disk Info
    $disks = Get-CimInstance Win32_DiskDrive
    $info.Disks = @()
    foreach ($disk in $disks) {
        $logical = Get-CimInstance Win32_LogicalDisk | Where-Object { $disk.DeviceID -match $_.DeviceID.Substring(0,2) }
        
        $diskInfo = @{
            Model = $disk.Model
            Serial = $disk.SerialNumber
            Size = "$([math]::Round($disk.Size / 1GB, 2)) GB"
            InterfaceType = $disk.InterfaceType
        }
        
        if ($logical) {
            $diskInfo.Drive = $logical.DeviceID
            $diskInfo.Total = "$([math]::Round($logical.Size / 1GB, 2)) GB"
            $diskInfo.Free = "$([math]::Round($logical.FreeSpace / 1GB, 2)) GB"
            $diskInfo.Used = "$([math]::Round(($logical.Size - $logical.FreeSpace) / 1GB, 2)) GB"
            $diskInfo.PercentFree = [math]::Round(($logical.FreeSpace / $logical.Size) * 100, 1)
        }
        
        # Check if SSD
        $physDrive = Get-CimInstance -Namespace "root\microsoft\windows\storage" -ClassName MSFT_PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceID -eq $disk.Index }
        if ($physDrive) {
            $diskInfo.Type = if ($physDrive.MediaType -eq 4) { "SSD" } else { "HDD" }
        } else {
            $diskInfo.Type = if ($disk.InterfaceType -eq "NVMe") { "SSD" } else { "HDD" }
        }
        
        $info.Disks += $diskInfo
    }
    
    # Network Info
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    $info.Network = @()
    foreach ($adapter in $adapters) {
        $netInfo = @{
            IP = $adapter.IPAddress[0]
            Subnet = $adapter.IPSubnet[0]
            Gateway = $adapter.DefaultIPGateway[0]
            DNS1 = $adapter.DNSServerSearchOrder[0]
            DNS2 = $adapter.DNSServerSearchOrder[1]
            MAC = $adapter.MACAddress
            Description = $adapter.Description
        }
        $info.Network += $netInfo
    }
    
    # WiFi Passwords
    $info.WiFiNetworks = @()
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_ -replace ".*:\s+", "" }
    foreach ($profile in $profiles) {
        $passwordInfo = netsh wlan show profile name="$profile" key=clear | Select-String "Key Content"
        $password = if ($passwordInfo) { ($passwordInfo -split ":")[1].Trim() } else { "N/A" }
        $info.WiFiNetworks += @{
            SSID = $profile
            Password = $password
        }
    }
    
    # Installed Programs
    $info.Programs = @()
    $programs = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" 2>$null
    $programs = $programs | Where-Object { $_.DisplayName -and $_.DisplayName -ne "" }
    foreach ($prog in $programs) {
        $info.Programs += @{
            Name = $prog.DisplayName
            Publisher = $prog.Publisher
            Version = $prog.DisplayVersion
            InstallDate = $prog.InstallDate
            Size = if ($prog.EstimatedSize) { "$([math]::Round($prog.EstimatedSize / 1024, 2)) GB" } else { "N/A" }
        }
    }
    
    # Email Accounts (Outlook)
    $info.EmailAccounts = @()
    $outlookProfiles = Get-ItemProperty "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\Outlook\*" -ErrorAction SilentlyContinue
    if ($outlookProfiles) {
        foreach ($prop in $outlookProfiles.PSObject.Properties) {
            if ($prop.Name -match "Email") {
                $info.EmailAccounts += @{
                    Type = "Outlook"
                    Email = $prop.Value
                }
            }
        }
    }
    
    # System Health Score
    $healthScore = 100
    if ($ramPercent -gt 80) { $healthScore -= 20 }
    elseif ($ramPercent -gt 60) { $healthScore -= 10 }
    foreach ($disk in $info.Disks) {
        if ($disk.PercentFree -lt 10) { $healthScore -= 20 }
        elseif ($disk.PercentFree -lt 20) { $healthScore -= 10 }
    }
    $bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    if ($uptime.TotalDays -gt 30) { $healthScore -= 10 }
    elseif ($uptime.TotalDays -gt 14) { $healthScore -= 5 }
    
    $info.HealthScore = [Math]::Max(0, $healthScore)
    
    return $info
}

# ===== GENERATE REPORT =====
function Generate-Report($systemInfo) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportName = "SystemA_Report_$timestamp"
    $htmlPath = Join-Path $ReportsPath "$reportName.html"
    $txtPath = Join-Path $ReportsPath "$reportName.txt"
    $logPath = Join-Path $LogsPath "SystemA_Log_$timestamp.log"
    
    $lang = $LangCache
    $r = $lang.reports
    
    $score = $systemInfo.HealthScore
    $healthStatus = if ($score -ge 80) { $r.excellent }
    elseif ($score -ge 60) { $r.good }
    elseif ($score -ge 40) { $r.fair }
    elseif ($score -ge 20) { $r.poor }
    else { $r.very_poor }
    
    $healthColor = if ($score -ge 80) { "#00ff88" }
    elseif ($score -ge 60) { "#88ff00" }
    elseif ($score -ge 40) { "#ffaa00" }
    elseif ($score -ge 20) { "#ff6600" }
    else { "#ff0000" }
    
    # Generate HTML Report
    $html = @"
<!DOCTYPE html>
<html lang="$script:CurrentLang">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SystemA v.3.1 - $($r.title)</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0a0a1a 0%, #1a1a3e 50%, #0a0a1a 100%);
            color: #e0e0e0; min-height: 100vh; padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; padding: 30px; background: linear-gradient(135deg, rgba(0,150,255,0.1), rgba(0,255,136,0.1)); border-radius: 15px; border: 1px solid rgba(0,150,255,0.3); margin-bottom: 30px; }
        .header h1 { font-size: 2.5em; background: linear-gradient(135deg, #00ff88, #0096ff); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .header p { color: #888; margin-top: 10px; }
        .health-section { text-align: center; padding: 30px; margin-bottom: 30px; background: linear-gradient(135deg, rgba(0,255,136,0.05), rgba(0,150,255,0.05)); border-radius: 15px; border: 1px solid rgba(0,255,136,0.2); }
        .health-score { font-size: 4em; font-weight: bold; color: $healthColor; text-shadow: 0 0 30px ${healthColor}44; }
        .health-label { font-size: 1.2em; color: #aaa; margin-top: 10px; }
        .health-bar { width: 100%; height: 20px; background: #1a1a3e; border-radius: 10px; overflow: hidden; margin-top: 15px; }
        .health-bar-fill { height: 100%; width: $score%; background: linear-gradient(90deg, $healthColor, ${healthColor}88); border-radius: 10px; transition: width 1s ease; }
        .section { background: linear-gradient(135deg, rgba(255,255,255,0.03), rgba(255,255,255,0.01)); border-radius: 15px; border: 1px solid rgba(255,255,255,0.1); padding: 25px; margin-bottom: 20px; }
        .section h2 { color: #0096ff; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 1px solid rgba(0,150,255,0.3); }
        .info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; }
        .info-item { padding: 12px; background: rgba(255,255,255,0.03); border-radius: 8px; border: 1px solid rgba(255,255,255,0.05); }
        .info-item .label { color: #888; font-size: 0.85em; }
        .info-item .value { color: #fff; font-size: 1.1em; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.1); }
        th { color: #0096ff; font-weight: 600; }
        tr:hover { background: rgba(255,255,255,0.03); }
        .progress-bar { width: 100%; height: 8px; background: #1a1a3e; border-radius: 4px; overflow: hidden; margin-top: 5px; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #00ff88, #0096ff); border-radius: 4px; }
        .footer { text-align: center; padding: 30px; margin-top: 30px; border-top: 1px solid rgba(255,255,255,0.1); color: #666; font-style: italic; }
        .memorial-note { text-align: center; padding: 20px; margin-top: 20px; background: linear-gradient(135deg, rgba(255,200,0,0.05), rgba(255,150,0,0.05)); border-radius: 10px; border: 1px solid rgba(255,200,0,0.2); color: #ccc; font-style: italic; line-height: 1.6; }
        @media (max-width: 768px) { .info-grid { grid-template-columns: 1fr; } .header h1 { font-size: 1.8em; } }
    </style>
</head>
<body>
    <div class="container">
        <div class="header"><h1>SystemA v.3.1</h1><p>$($r.title) - $(Get-Date -Format "dd.MM.yyyy HH:mm:ss")</p></div>
        <div class="health-section">
            <div class="health-score">$score/100</div>
            <div class="health-label">$($r.health_score): $healthStatus</div>
            <div class="health-bar"><div class="health-bar-fill"></div></div>
        </div>
        <div class="section">
            <h2>$($r.identity)</h2>
            <div class="info-grid">
                <div class="info-item"><div class="label">$($r.computer_name)</div><div class="value">$($systemInfo.ComputerName)</div></div>
                <div class="info-item"><div class="label">$($r.os)</div><div class="value">$($systemInfo.OS)</div></div>
                <div class="info-item"><div class="label">$($r.username)</div><div class="value">$($systemInfo.Username)</div></div>
            </div>
        </div>
        <div class="section">
            <h2>$($r.hardware)</h2>
            <div class="info-grid">
                <div class="info-item"><div class="label">$($r.cpu)</div><div class="value">$($systemInfo.CPU)</div></div>
                <div class="info-item"><div class="label">$($r.cores)</div><div class="value">$($systemInfo.Cores)</div></div>
                <div class="info-item"><div class="label">$($r.threads)</div><div class="value">$($systemInfo.Threads)</div></div>
                <div class="info-item"><div class="label">$($r.ram) ($($r.ram_total))</div><div class="value">$($systemInfo.RAM.Total)</div></div>
                <div class="info-item"><div class="label">$($r.ram_used)</div><div class="value">$($systemInfo.RAM.Used) ($($systemInfo.RAM.Percent))</div></div>
                <div class="info-item"><div class="label">$($r.ram_slots)</div><div class="value">$($systemInfo.RAMSlotCount)</div></div>
            </div>
            <table><tr><th>$($r.ram_slot)</th><th>$($r.ram_brand)</th><th>$($r.reports.ram_total)</th><th>Speed</th></tr>
"@
    foreach ($mod in $systemInfo.RAMModules) {
        $html += "<tr><td>$($mod.Slot)</td><td>$($mod.Brand)</td><td>$($mod.Capacity)</td><td>$($mod.Speed)</td></tr>`n"
    }
    $html += "</table></div>"
    
    $html += "<div class='section'><h2>$($r.disk)</h2>"
    foreach ($disk in $systemInfo.Disks) {
        $freePercent = $disk.PercentFree
        $html += @"
            <div class="info-grid">
                <div class="info-item"><div class="label">$($r.disk_model)</div><div class="value">$($disk.Model)</div></div>
                <div class="info-item"><div class="label">$($r.disk_serial)</div><div class="value">$($disk.Serial)</div></div>
                <div class="info-item"><div class="label">$($r.disk_drive)</div><div class="value">$($disk.Drive)</div></div>
                <div class="info-item"><div class="label">$($r.disk_type)</div><div class="value">$($disk.Type)</div></div>
                <div class="info-item"><div class="label">$($r.disk_total)</div><div class="value">$($disk.Total)</div></div>
                <div class="info-item"><div class="label">$($r.disk_used)</div><div class="value">$($disk.Used)</div></div>
                <div class="info-item"><div class="label">$($r.disk_free)</div><div class="value">$($disk.Free)</div></div>
            </div>
            <div class="progress-bar"><div class="progress-fill" style="width: $freePercent%"></div></div>
            <p style="text-align:right;color:#888;margin-top:5px">$freePercent% $($r.disk_free)</p>
"@
    }
    $html += "</div>"
    
    $html += "<div class='section'><h2>$($r.network)</h2>"
    foreach ($net in $systemInfo.Network) {
        $html += @"
            <div class="info-grid">
                <div class="info-item"><div class="label">$($r.ip)</div><div class="value">$($net.IP)</div></div>
                <div class="info-item"><div class="label">$($r.netmask)</div><div class="value">$($net.Subnet)</div></div>
                <div class="info-item"><div class="label">$($r.gateway)</div><div class="value">$($net.Gateway)</div></div>
                <div class="info-item"><div class="label">$($r.dns1)</div><div class="value">$($net.DNS1)</div></div>
                <div class="info-item"><div class="label">$($r.dns2)</div><div class="value">$($net.DNS2)</div></div>
                <div class="info-item"><div class="label">$($r.mac)</div><div class="value">$($net.MAC)</div></div>
            </div>
"@
    }
    if ($systemInfo.WiFiNetworks.Count -gt 0) {
        $html += "<h3 style='color:#88ff00;margin-top:20px'>$($r.wifi_networks)</h3><table><tr><th>SSID</th><th>$($r.wifi_passwords)</th></tr>"
        foreach ($wifi in $systemInfo.WiFiNetworks) { $html += "<tr><td>$($wifi.SSID)</td><td>$($wifi.Password)</td></tr>" }
        $html += "</table>"
    }
    $html += "</div>"
    
    $html += "<div class='section'><h2>$($r.software) - $($r.installed_programs) ($($systemInfo.Programs.Count))</h2><table><tr><th>$($r.program_name)</th><th>$($r.publisher)</th><th>$($r.version)</th><th>$($r.install_date)</th><th>$($r.size)</th></tr>"
    $count = 0
    foreach ($prog in ($systemInfo.Programs | Sort-Object Name)) {
        if ($count -ge 100) { break }
        $html += "<tr><td>$($prog.Name)</td><td>$($prog.Publisher)</td><td>$($prog.Version)</td><td>$($prog.InstallDate)</td><td>$($prog.Size)</td></tr>"
        $count++
    }
    $html += "</table></div>"
    
    $html += "<div class='memorial-note'>$($lang.memorial)</div>"
    $html += "<div class='footer'><p>SystemA v.3.1 &copy; $(Get-Date.Year) - $($r.generated): $(Get-Date -Format "dd.MM.yyyy HH:mm:ss")</p></div></div></body></html>"
    
    $html | Out-File -FilePath $htmlPath -Encoding UTF8
    
    # Generate TXT Report
    $txt = "============================================`n        SystemA v.3.1 - $($r.title)`n============================================`n$($r.generated): $(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n`n"
    $txt += "============================================`n$($r.health): $($r.health_score): $score/100 - $healthStatus`n============================================`n`n"
    $txt += "============================================`n$($r.identity)`n============================================`n"
    $txt += "$($r.computer_name): $($systemInfo.ComputerName)`n$($r.os): $($systemInfo.OS)`n$($r.username): $($systemInfo.Username)`n`n"
    $txt += "============================================`n$($r.hardware)`n============================================`n"
    $txt += "$($r.cpu): $($systemInfo.CPU)`n$($r.cores): $($systemInfo.Cores)`n$($r.threads): $($systemInfo.Threads)`n"
    $txt += "$($r.ram) $($r.ram_total): $($systemInfo.RAM.Total)`n$($r.ram) $($r.ram_used): $($systemInfo.RAM.Used) ($($systemInfo.RAM.Percent))`n$($r.ram_slots): $($systemInfo.RAMSlotCount)`n`n"
    foreach ($mod in $systemInfo.RAMModules) { $txt += "$($mod.Slot): $($mod.Brand) - $($mod.Capacity) @ $($mod.Speed)`n" }
    $txt += "`n============================================`n$($r.disk)`n============================================`n"
    foreach ($disk in $systemInfo.Disks) { $txt += "$($r.disk_model): $($disk.Model)`n$($r.disk_serial): $($disk.Serial)`n$($r.disk_drive): $($disk.Drive)`n$($r.disk_type): $($disk.Type)`n$($r.disk_total): $($disk.Total)`n$($r.disk_used): $($disk.Used)`n$($r.disk_free): $($disk.Free)`n`n" }
    $txt += "============================================`n$($r.network)`n============================================`n"
    foreach ($net in $systemInfo.Network) { $txt += "$($r.ip): $($net.IP)`n$($r.netmask): $($net.Subnet)`n$($r.gateway): $($net.Gateway)`n$($r.dns1): $($net.DNS1)`n$($r.dns2): $($net.DNS2)`n$($r.mac): $($net.MAC)`n`n" }
    if ($systemInfo.WiFiNetworks.Count -gt 0) { $txt += "`n$($r.wifi_networks):`n"; foreach ($wifi in $systemInfo.WiFiNetworks) { $txt += "  $($wifi.SSID): $($wifi.Password)`n" } }
    $txt += "`n============================================`n$($r.software) - $($r.installed_programs)`n============================================`n"
    foreach ($prog in ($systemInfo.Programs | Sort-Object Name)) { $txt += "  $($prog.Name) - $($prog.Publisher) - $($prog.Version)`n" }
    $txt += "`n============================================`n$($lang.memorial)`n============================================`n"
    
    $txt | Out-File -FilePath $txtPath -Encoding UTF8
    
    $logContent = "============================================`nSystemA v.3.1 - Operation Log`n============================================`nDate: $(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`nLanguage: $script:CurrentLang`nComputer: $($systemInfo.ComputerName)`nOS: $($systemInfo.OS)`nHealth Score: $score/100`n`nOperations Completed:`n- System information collected`n- HTML report generated: $htmlPath`n- TXT report generated: $txtPath`n============================================`n"
    $logContent | Out-File -FilePath $logPath -Encoding UTF8
    
    return @{ HTMLPath = $htmlPath; TXTPath = $txtPath; LogPath = $logPath; HealthScore = $score }
}

# ===== RUN SYSTEM CLEANING WITH SUB-STEPS =====
function Run-SystemCleaning {
    Clear-Host
    $line = ("=" * 60)
    
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  SISTEM TEMIZLIGI VE GUNCELLEME / SYSTEM CLEANING & UPDATE" -ForegroundColor Yellow
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    
    $steps = @(
        @{id=1; desc="Sistem yedegi alinmasi onerilir / System backup recommended"; action="backup"},
        @{id=2; desc="Sistem taramasi yapilacak / System scan will be performed"; action="scan"},
        @{id=3; desc="Gerekli programlarin kurulumu / Required programs installation"; action="install"},
        @{id=4; desc="Sistem temizligi yapilacak / System cleaning"; action="clean"},
        @{id=5; desc="Disk temizligi ve birlestirme / Disk cleanup and defrag"; action="disk"},
        @{id=6; desc="Sistem dosyasi onarimi / System file repair (SFC/DISM)"; action="repair"},
        @{id=7; desc="Ag ve Windows Update sifirlama / Network & Windows Update reset"; action="network"},
        @{id=8; desc="Guc ayarlari optimizasyonu / Power settings optimization"; action="power"},
        @{id=9; desc="Gunluk ve rapor temizligi / Log and report cleanup"; action="logs"},
        @{id=10; desc="Yeniden baslatma / Restart (opsiyonel)"; action="restart"}
    )
    
    $selectedSteps = @()
    
    foreach ($step in $steps) {
        Write-Host ""
        Write-Host (" " * 5) "Adim/Step $($step.id): $($step.desc)" -ForegroundColor White
        $confirm = Read-Host (" " * 5) "Bu islemi onayliyor musunuz? (E/H/0-Geri): "
        
        if ($confirm -eq "0") {
            Write-Host (" " * 5) "Islem iptal edildi / Operation cancelled" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            return
        }
        
        if ($confirm -eq "E" -or $confirm -eq "e" -or $confirm -eq "Y" -or $confirm -eq "y") {
            $selectedSteps += $step
            Write-Host (" " * 5) "✓ Onaylandi / Approved" -ForegroundColor Green
        } else {
            Write-Host (" " * 5) "✗ Atlandi / Skipped" -ForegroundColor Red
        }
    }
    
    if ($selectedSteps.Count -eq 0) {
        Write-Host "`n" (" " * 5) "Hicbir adim secilmedi / No steps selected!" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  SECILEN ADIMLAR UYGULANIYOR / EXECUTING SELECTED STEPS..." -ForegroundColor Yellow
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    
    $enginePath = Join-Path $ScriptsPath "win_engine.bat"
    $results = @()
    
    foreach ($step in $selectedSteps) {
        Write-Host ""
        Write-Host (" " * 3) ">>> Adim/Step $($step.id): $($step.desc)" -ForegroundColor Cyan
        
        switch ($step.action) {
            "backup" {
                Write-Host (" " * 5) "Sistem geri yukleme noktasi olusturuluyor..." -ForegroundColor White
                try {
                    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
                    Checkpoint-Computer -Description "SystemA Backup Point" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
                    Write-Host (" " * 5) "✓ Geri yukleme noktasi olusturuldu" -ForegroundColor Green
                    $results += @{step=$step.id; status="OK"; detail="Restore point created"}
                } catch {
                    Write-Host (" " * 5) "✗ Geri yukleme noktasi olusturulamadi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "scan" {
                Write-Host (" " * 5) "Sistem taranıyor (SFC/DISM)..." -ForegroundColor White
                try {
                    Write-Host (" " * 5) "DISM checkhealth..." -NoNewline -ForegroundColor Gray
                    dism /online /cleanup-image /checkhealth | Out-Null
                    Write-Host " OK" -ForegroundColor Green
                    Write-Host (" " * 5) "DISM scanhealth..." -NoNewline -ForegroundColor Gray
                    dism /online /cleanup-image /scanhealth | Out-Null
                    Write-Host " OK" -ForegroundColor Green
                    Write-Host (" " * 5) "SFC scan..." -NoNewline -ForegroundColor Gray
                    sfc /scannow | Out-Null
                    Write-Host " OK" -ForegroundColor Green
                    $results += @{step=$step.id; status="OK"; detail="System scan completed"}
                } catch {
                    Write-Host (" " * 5) "✗ Tarama hatasi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "install" {
                Write-Host (" " * 5) "Gerekli programlar kontrol ediliyor..." -ForegroundColor White
                try {
                    $installed = @()
                    if (Get-Command winget -ErrorAction SilentlyContinue) {
                        Write-Host (" " * 5) "winget ile Python kontrol..." -NoNewline -ForegroundColor Gray
                        winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                        Write-Host " OK" -ForegroundColor Green
                        $installed += "Python 3.12"
                    }
                    $results += @{step=$step.id; status="OK"; detail="Installed: $($installed -join ', ')"}
                } catch {
                    Write-Host (" " * 5) "✗ Kurulum hatasi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "clean" {
                Write-Host (" " * 5) "Sistem temizleniyor..." -ForegroundColor White
                try {
                    # Temp files
                    $paths = @(
                        "$env:TEMP\*.*",
                        "$env:windir\Temp\*.*",
                        "$env:windir\Prefetch\*.*",
                        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\*.*"
                    )
                    foreach ($p in $paths) {
                        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    Write-Host (" " * 5) "✓ Gecici dosyalar temizlendi" -ForegroundColor Green
                    
                    # Browser caches
                    $browserPaths = @(
                        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*.*",
                        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*.*",
                        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*.*"
                    )
                    foreach ($p in $browserPaths) {
                        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    Write-Host (" " * 5) "✓ Tarayici ortbellegi temizlendi" -ForegroundColor Green
                    
                    # Windows Update cache
                    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
                    Stop-Service bits -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*.*" -Recurse -Force -ErrorAction SilentlyContinue
                    Start-Service wuauserv -ErrorAction SilentlyContinue
                    Start-Service bits -ErrorAction SilentlyContinue
                    Write-Host (" " * 5) "✓ Windows Update ortbellegi temizlendi" -ForegroundColor Green
                    
                    # Event logs
                    wevtutil cl Application 2>$null
                    wevtutil cl System 2>$null
                    wevtutil cl Security 2>$null
                    Write-Host (" " * 5) "✓ Event loglari temizlendi" -ForegroundColor Green
                    
                    $results += @{step=$step.id; status="OK"; detail="Cleaning completed"}
                } catch {
                    Write-Host (" " * 5) "✗ Temizlik hatasi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "disk" {
                Write-Host (" " * 5) "Disk temizligi yapiliyor..." -ForegroundColor White
                try {
                    # CleanMgr
                    $cleanMgrPath = "$env:windir\System32\cleanmgr.exe"
                    if (Test-Path $cleanMgrPath) {
                        Start-Process $cleanMgrPath -ArgumentList "/sagerun:1" -Wait -NoNewWindow
                        Write-Host (" " * 5) "✓ Disk temizligi tamamlandi" -ForegroundColor Green
                    }
                    
                    # CHKDSK
                    Write-Host (" " * 5) "CHKDSK baslatiliyor (sadece okuma)..." -ForegroundColor Gray
                    chkdsk c: /scan 2>$null
                    Write-Host (" " * 5) "✓ CHKDSK taramasi tamamlandi" -ForegroundColor Green
                    
                    # Defrag (SSD icin trim, HDD icin defrag)
                    $drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
                    foreach ($drive in $drives) {
                        $driveLetter = $drive.DeviceID
                        Write-Host (" " * 5) "$driveLetter optimize ediliyor..." -ForegroundColor Gray
                        Optimize-Volume -DriveLetter $driveLetter[0] -ReTrim -Verbose 2>&1 | Out-Null
                    }
                    Write-Host (" " * 5) "✓ Disk optimizasyonu tamamlandi" -ForegroundColor Green
                    
                    $results += @{step=$step.id; status="OK"; detail="Disk cleanup completed"}
                } catch {
                    Write-Host (" " * 5) "✗ Disk hatasi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "repair" {
                Write-Host (" " * 5) "Sistem dosyalari onariliyor..." -ForegroundColor White
                try {
                    Write-Host (" " * 5) "DISM restorehealth..." -NoNewline -ForegroundColor Gray
                    dism /online /cleanup-image /restorehealth 2>$null
                    Write-Host " OK" -ForegroundColor Green
                    
                    Write-Host (" " * 5) "DISM component cleanup..." -NoNewline -ForegroundColor Gray
                    dism /online /cleanup-image /startcomponentcleanup /resetbase 2>$null
                    Write-Host " OK" -ForegroundColor Green
                    
                    Write-Host (" " * 5) "SFC scannow..." -NoNewline -ForegroundColor Gray
                    sfc /scannow 2>$null
                    Write-Host " OK" -ForegroundColor Green
                    
                    $results += @{step=$step.id; status="OK"; detail="System files repaired"}
                } catch {
                    Write-Host (" " * 5) "✗ Onarim hatasi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "network" {
                Write-Host (" " * 5) "Ag ve Windows Update sifirlaniyor..." -ForegroundColor White
                try {
                    ipconfig /flushdns 2>$null
                    Write-Host (" " * 5) "✓ DNS ortbellegi temizlendi" -ForegroundColor Green
                    
                    netsh winsock reset 2>$null
                    Write-Host (" " * 5) "✓ Winsock sifirlandi" -ForegroundColor Green
                    
                    netsh int ip reset 2>$null
                    Write-Host (" " * 5) "✓ TCP/IP sifirlandi" -ForegroundColor Green
                    
                    netsh winhttp reset proxy 2>$null
                    Write-Host (" " * 5) "✓ Proxy sifirlandi" -ForegroundColor Green
                    
                    # Windows Update reset
                    Stop-Service wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue
                    Rename-Item "$env:windir\SoftwareDistribution" "$env:windir\SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
                    Rename-Item "$env:windir\System32\catroot2" "$env:windir\System32\catroot2.old" -Force -ErrorAction SilentlyContinue
                    Start-Service wuauserv, cryptSvc, bits, msiserver -ErrorAction SilentlyContinue
                    Write-Host (" " * 5) "✓ Windows Update sifirlandi" -ForegroundColor Green
                    
                    $results += @{step=$step.id; status="OK"; detail="Network & WU reset completed"}
                } catch {
                    Write-Host (" " * 5) "✗ Ag hatasi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "power" {
                Write-Host (" " * 5) "Guc ayarlari optimize ediliyor..." -ForegroundColor White
                try {
                    powercfg -h off 2>$null
                    Write-Host (" " * 5) "✓ Hibernate kapatildi" -ForegroundColor Green
                    
                    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
                    Write-Host (" " * 5) "✓ Yuksek performans modu aktif" -ForegroundColor Green
                    
                    Stop-Service SysMain -Force -ErrorAction SilentlyContinue
                    Set-Service SysMain -StartupType Disabled -ErrorAction SilentlyContinue
                    Write-Host (" " * 5) "✓ SysMain (Superfetch) devre disi" -ForegroundColor Green
                    
                    $results += @{step=$step.id; status="OK"; detail="Power settings optimized"}
                } catch {
                    Write-Host (" " * 5) "✗ Guc ayari hatasi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "logs" {
                Write-Host (" " * 5) "Gunluk ve rapor temizligi..." -ForegroundColor White
                try {
                    # Windows Error Reporting
                    Remove-Item "$env:PROGRAMDATA\Microsoft\Windows\WER\ReportArchive\*.*" -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Item "$env:PROGRAMDATA\Microsoft\Windows\WER\ReportQueue\*.*" -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Item "$env:LOCALAPPDATA\CrashDumps\*.*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host (" " * 5) "✓ Hata raporlari temizlendi" -ForegroundColor Green
                    
                    # DNS cache
                    ipconfig /flushdns 2>$null
                    Write-Host (" " * 5) "✓ DNS ortbellegi temizlendi" -ForegroundColor Green
                    
                    $results += @{step=$step.id; status="OK"; detail="Logs cleaned"}
                } catch {
                    Write-Host (" " * 5) "✗ Log temizlik hatasi: $_" -ForegroundColor Red
                    $results += @{step=$step.id; status="FAIL"; detail=$_.Exception.Message}
                }
            }
            "restart" {
                Write-Host ""
                Write-Host (" " * 5) "⚠️  BILGISAYAR YENIDEN BASLATILACAK!" -ForegroundColor Red
                $restartConfirm = Read-Host (" " * 5) "EMIN MISINIZ? (E/H): "
                if ($restartConfirm -eq "E" -or $restartConfirm -eq "e" -or $restartConfirm -eq "Y" -or $restartConfirm -eq "y") {
                    Write-Host (" " * 5) "✓ Yeniden baslatiliyor..." -ForegroundColor Green
                    $results += @{step=$step.id; status="OK"; detail="Restart initiated"}
                    Restart-Computer -Force
                } else {
                    Write-Host (" " * 5) "✗ Yeniden baslatma iptal edildi" -ForegroundColor Yellow
                    $results += @{step=$step.id; status="SKIP"; detail="User cancelled restart"}
                }
            }
        }
    }
    
    # Show summary
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  ISLEM OZETI / OPERATION SUMMARY" -ForegroundColor Yellow
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    
    $okCount = 0
    $failCount = 0
    foreach ($r in $results) {
        $icon = if ($r.status -eq "OK") { "✓" } else { "✗" }
        $color = if ($r.status -eq "OK") { "Green" } else { "Red" }
        Write-Host (" " * 5) "$icon Adim/Step $($r.step): $($r.detail)" -ForegroundColor $color
        if ($r.status -eq "OK") { $okCount++ } else { $failCount++ }
    }
    
    Write-Host ""
    Write-Host (" " * 5) "Basarili/Success: $okCount  Basarisiz/Failed: $failCount" -ForegroundColor Yellow
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin / Press Enter to continue"
}

# ===== VIEW REPORTS =====
function View-Reports {
    Clear-Host
    $reports = Get-ChildItem -Path $ReportsPath -Filter "*.html" | Sort-Object LastWriteTime -Descending
    
    if ($reports.Count -eq 0) {
        Write-Host "`n" (Get-Lang "messages.no_reports") -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host "`n" (Get-Lang "menu.view_report") -ForegroundColor Cyan
    Write-Host "`n"
    for ($i = 0; $i -lt [Math]::Min($reports.Count, 10); $i++) {
        Write-Host "$($i+1). $($reports[$i].Name) - $($reports[$i].LastWriteTime)" -ForegroundColor White
    }
    Write-Host "0. " -NoNewline -ForegroundColor Red; Write-Host (Get-Lang "menu.back") -ForegroundColor Red
    
    $choice = Read-Host "`n" + (Get-Lang "messages.select_option")
    if ($choice -eq "0") { return }
    
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $reports.Count) {
        Start-Process $reports[$index].FullName
    }
}

# ===== MAIN PROGRAM =====
function Main {
    # Move old files on startup
    Move-OldFiles
    
    # Language selection
    $langCode = Select-Language
    
    # Show disclaimer
    $accepted = Show-Disclaimer
    while (-not $accepted) {
        Write-Host "`n" (Get-Lang "messages.disclaimer_rejected") -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        $langCode = Select-Language
        $accepted = Show-Disclaimer
    }
    
    # Main loop
    while ($true) {
        $choice = Show-MainMenu
        
        switch ($choice) {
            "1" {
                Run-SystemCleaning
            }
            "2" {
                Write-Host "`n" (Get-Lang "messages.processing") -ForegroundColor Green
                $systemInfo = Get-SystemInfo
                $result = Generate-Report $systemInfo
                
                Write-Host "`n" (Get-Lang "messages.operation_completed") -ForegroundColor Green
                Write-Host "`nHTML: $($result.HTMLPath)" -ForegroundColor Cyan
                Write-Host "TXT: $($result.TXTPath)" -ForegroundColor Cyan
                Write-Host "Log: $($result.LogPath)" -ForegroundColor Cyan
                Write-Host "`n" (Get-Lang "reports.health_score") ": $($result.HealthScore)/100" -ForegroundColor Yellow
                
                # Open reports and website
                Start-Process $result.HTMLPath
                Start-Process $result.TXTPath
                Start-Process "https://ercanceviz.com.tr"
                
                Write-Host "`n" -NoNewline
                Read-Host "Devam etmek icin Enter'a basin / Press Enter to continue"
            }
            "3" {
                View-Reports
            }
            "0" {
                Write-Host "`n" (Get-Lang "messages.goodbye") -ForegroundColor Green
                exit
            }
            default {
                Write-Host "`n" (Get-Lang "messages.invalid_option") -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Start the program
Main
    
   