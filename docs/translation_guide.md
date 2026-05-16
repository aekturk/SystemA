# SystemA v.3.1 Translation Guide

## Supported Languages
- TR - Türkçe (Turkish)
- EN - English
- DE - Deutsch (German)
- FR - Français (French)
- ES - Español (Spanish)
- PT - Português (Portuguese)
- RU - Русский (Russian)
- ZH - 中文 (Chinese)
- JA - 日本語 (Japanese)

## Translation Guidelines

### JSON Structure
Each language file follows the same structure. Translate only the values, not the keys.

### Key Sections
1. **app_name**: Application name (keep as "SystemA v.3.1")
2. **slogan**: "Deep Cleaning, Uninterrupted Performance"
3. **menu**: Menu items and options
4. **messages**: System messages and prompts
5. **reports**: Report section headers and labels
6. **hardware**: Hardware component names
7. **software**: Software-related terms
8. **network**: Network-related terms
9. **health**: Health status descriptions
10. **memorial**: Memorial note (keep the meaning)

### Special Characters
- Ensure proper Unicode encoding
- Test RTL languages if added
- Maintain placeholder positions (%s, %d, etc.)

### Adding a New Language
1. Create `LANGCODE.json` in `/lang/`
2. Translate all string values
3. Add to language selection in main scripts
4. Add to index.html dropdown
