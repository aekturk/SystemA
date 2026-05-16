# SystemA v.3.1 API Reference

## System Engine Scripts

### Windows Engine (win_engine.bat)
- **Purpose**: Windows system maintenance and optimization
- **Privileges**: Administrator required
- **Key Operations**:
  - Winget package updates
  - System restore point creation
  - Disk cleanup via cleanmgr
  - Registry backup
  - Browser cache clearing
  - DISM and SFC scans
  - Disk defragmentation
  - Network reset operations
  - Event log clearing
  - Power configuration

### Linux Engine (linux_engine.sh)
- **Purpose**: Linux system maintenance and optimization
- **Privileges**: Root required
- **Key Operations**:
  - APT package updates
  - Browser history cleanup
  - Cache clearing
  - Journal cleanup
  - Filesystem trim
  - DNS cache flush

### macOS Engine (mac_engine.sh)
- **Purpose**: macOS system maintenance and optimization
- **Privileges**: Root required
- **Key Operations**:
  - Homebrew updates
  - Cache clearing
  - Disk verification
  - TRIM operations
  - DNS cache flush

## Reporting Module
- Collects system information across 9 languages
- Generates HTML and TXT reports
- Health scoring algorithm (0-100)
