# SystemA v.3.1 Troubleshooting Guide

## Common Issues

### Permission Denied
**Problem**: Script fails with permission errors
**Solution**: Run as Administrator (Windows) or with sudo (Linux/macOS)

### Winget Not Found
**Problem**: Windows package manager not available
**Solution**: Install App Installer from Microsoft Store, or the script will fall back to system restore mode

### Script Not Running
**Problem**: Script doesn't execute
**Solution**: 
- Windows: Right-click → Run as Administrator
- Linux/macOS: `chmod +x script.sh && sudo ./script.sh`

### Report Generation Fails
**Problem**: HTML/TXT reports not generated
**Solution**: 
- Check disk space
- Ensure write permissions in the reports directory
- Check logs for detailed error information

### Language Not Displaying Correctly
**Problem**: Characters appear as boxes or garbled
**Solution**: 
- Ensure UTF-8 encoding in terminal
- Install language packs if needed
- Use a Unicode-compatible terminal

### Network Operations Fail
**Problem**: Network reset or DNS flush fails
**Solution**: 
- Run as administrator
- Check if services are running
- Disable VPN temporarily

## Logs
Check `/logs/` directory for detailed operation logs
