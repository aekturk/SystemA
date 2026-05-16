# SystemA v.3.1 Development Guide

## Project Structure
```
SystemA/
├── backups/          # System backup files
├── docs/             # Documentation files
├── images/           # Image assets
├── lang/             # Language JSON files
├── logs/             # Operation logs
├── old_files/        # Archived old files
├── reports/          # Generated reports
├── scripts/          # System engine scripts
│   ├── win_engine.bat
│   ├── linux_engine.sh
│   └── mac_engine.sh
├── index.html        # Web interface
├── SystemA.bat       # Windows launcher
├── SystemA.sh        # Linux/macOS launcher
└── SystemA.ps1       # PowerShell launcher
```

## Adding a New Language
1. Create a new JSON file in `/lang/` (e.g., `IT.json` for Italian)
2. Copy the structure from an existing language file
3. Translate all strings
4. Add the language to the language selection menu in the main scripts
5. Add the language to the dropdown in `index.html`

## Language File Structure
```json
{
  "app_name": "SystemA v.3.1",
  "slogan": "...",
  "menu": { ... },
  "messages": { ... },
  "reports": { ... }
}
```

## Building from Source
No build process required. The application runs directly from source files.
