# Dachsy 🐾

A macOS desktop pet — an interactive sausage dog (dachshund) that lives in a window on your screen. Feed it, play with it, keep it clean and happy. Optionally powered by AI responses via Claude or Ollama.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)

---

## Features

- 12 animated states: happy, hungry, tired, sleeping, excited, dirty, sad, playing, feeding, studying, focus, and default
- Stat system: Hunger, Happiness, Energy, and Cleanliness decay over time
- Interactive actions: Feed, Play, Clean, and Pet
- **Work (Pomodoro timer)** — set a focus session duration; all stats stay full while you work, Dachsy studies alongside you and reacts with excitement when the session ends
- **Chat box** — type a message and Dachsy replies; positive messages boost happiness, negative ones make him sad
- Speech bubbles with reactions
- Optional AI responses via **Claude API** or a local **Ollama** model
- Standard macOS window — minimize, close, drag to reposition

---

## Install (Pre-built App)

> Requires macOS 14 or later (Apple Silicon or Intel)

1. Download [Dachsy.app](https://github.com/kingtochan/Dachsy/releases/) from this repository
2. Drag it to your **Applications** folder
3. Right-click the app and choose **Open** (required the first time for apps not from the App Store)
4. Click **Open** in the security dialog

> macOS will show a warning because the app is not notarised. Right-clicking and choosing Open bypasses this once.

---

## Build from Source

### Requirements

- macOS 14 or later
- Xcode Command Line Tools or Xcode 15+
- Swift 5.9+

Install the command line tools if you haven't already:

```bash
xcode-select --install
```

### Steps

```bash
# Clone the repo
git clone https://github.com/your-username/dachsy.git
cd dachsy

# Build
swift build -c release

# Create the app bundle
mkdir -p Dachsy.app/Contents/MacOS Dachsy.app/Contents/Resources
cp .build/release/PetWidget Dachsy.app/Contents/MacOS/Dachsy
cp -r Sources/PetWidget/Resources/sausage_dog_scenarios Dachsy.app/Contents/Resources/
cp Sources/PetWidget/Resources/AppIcon.icns "Dachsy.app/Contents/Resources/"

cat > Dachsy.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key><string>Dachsy</string>
    <key>CFBundleExecutable</key><string>Dachsy</string>
    <key>CFBundleIdentifier</key><string>com.petwidget.dachsy</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>Dachsy</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
</dict>
</plist>
EOF

xattr -cr Dachsy.app
codesign -s - -f --deep Dachsy.app

# Run directly or copy to Applications
open Dachsy.app
```

---

## AI Responses (Optional)

Without an AI key, Dachsy uses built-in pre-written reactions. To enable live AI responses, click the **gear icon** in the title bar.

### Claude API

1. Get an API key at [console.anthropic.com](https://console.anthropic.com)
2. Open Settings in Dachsy → select **Claude** → paste your key
3. Uses `claude-haiku-4-5` (fast and cheap)

### Ollama (Local, Free)

1. Install [Ollama](https://ollama.com) and pull a model:
   ```bash
   ollama pull llama3.2:1b
   ```
2. Open Settings in Dachsy → select **Ollama** → enter the model name (e.g. `llama3.2:1b`)
3. Ollama must be running in the background

---

## Project Structure

```
Sources/PetWidget/
├── PetWidgetApp.swift               — app entry point, window configuration
├── Models.swift                     — dog states, stats, image loading
├── DogViewModel.swift               — game logic, AI service, stat decay
├── ContentView.swift                — main UI
├── Views.swift                      — reusable components (stat bars, speech bubble, buttons)
└── Resources/sausage_dog_scenarios/ — 10 dog state images
```

---

## Auto-start on Login

To have Dachsy launch automatically:

**System Settings → General → Login Items → add Dachsy**

---

## License

Apache-2.0
