# TaskSnap - Build & Deploy Guide 📱

## Quick Start (5 minutes)

### 1. Open in Xcode
```bash
cd /Users/warnergears/Documents/Projects/SnapTask/TaskSnap
open TaskSnap.xcodeproj
```

### 2. Configure Team & Bundle ID
1. Select **TaskSnap** project (blue icon) in navigator
2. Select **TaskSnap** target
3. Go to **Signing & Capabilities** tab
4. **Team**: Select your Apple ID
5. **Bundle Identifier**: Change to `com.[yourname].tasksnap`

### 3. Add iCloud Capability
1. Click **+ Capability**
2. Select **iCloud**
3. Check **CloudKit**
4. Set container to match your bundle ID: `iCloud.com.[yourname].tasksnap`

### 4. Select Device & Run
1. Connect iPhone via USB
2. Select your iPhone from top toolbar (Cmd+Shift+2)
3. Press **Cmd+R** to build and run

### 5. Trust Developer (First Time Only)
On iPhone: Settings → General → VPN & Device Management → Trust

---

## Detailed Instructions

### Prerequisites
- macOS Sonoma (14.0+) or later
- Xcode 15.0+ (from Mac App Store)
- iPhone running iOS 17.6+
- Apple ID (free developer account works)

### Project Structure
```
TaskSnap/
├── TaskSnap/               # Main app code
│   ├── Views/              # 26 SwiftUI views
│   ├── ViewModels/         # 4 ViewModels
│   ├── Models/             # Data models
│   ├── Services/           # 15 services
│   └── Utils/              # 7 utility files
├── TaskSnapWidgets/        # Widget extension
└── TaskSnap.xcodeproj/     # Xcode project
```

### Build Configuration

#### Debug Build (Development)
- Automatically configured
- No code signing issues expected
- Takes ~30-60 seconds to build

#### Release Build (Distribution)
For App Store submission:
1. Product → Archive
2. Distribute App → App Store Connect
3. Upload

### Common Issues & Solutions

#### Issue: "Signing certificate not found"
**Solution:** 
- Xcode → Preferences → Accounts → Add Apple ID
- Or: Change bundle ID to something unique

#### Issue: "CloudKit container not found"
**Solution:**
- Make sure iCloud capability is added
- Container name must match bundle ID
- May need to create in CloudKit Dashboard

#### Issue: "Build failed with Swift errors"
**Solution:**
- Product → Clean Build Folder (Cmd+Shift+K)
- Build again (Cmd+B)

#### Issue: "App doesn't appear on iPhone"
**Solution:**
- Check iPhone is unlocked and trusted
- Try different USB cable/port
- Restart Xcode and iPhone

### Testing Checklist

Before using daily:
- [ ] App launches without crashes
- [ ] Camera works (test photo capture)
- [ ] Create a test task
- [ ] Move task through columns (To Do → Doing → Done)
- [ ] Check streak updates
- [ ] Test notification permission
- [ ] Verify iCloud sync (if enabled)

### Performance Tips

First build is slow (~2-3 minutes)
- Subsequent builds are faster (~30 seconds)
- Use Cmd+B to build without running
- Use Cmd+R to build and run

### Clean Build
If you encounter weird issues:
```
Product → Clean Build Folder (Cmd+Shift+K)
```

---

## Distribution Options

### Option 1: Personal Device (Free)
- Apple ID (no paid membership required)
- App expires after 7 days (rebuild to refresh)
- Up to 3 apps at once

### Option 2: TestFlight (Free with Paid Membership)
- Apple Developer Program ($99/year)
- Invite testers via email
- App expires after 90 days

### Option 3: App Store (Paid Membership)
- Apple Developer Program ($99/year)
- Global distribution
- Review process required

---

## Next Steps After Build

1. **Test Core Features**
   - Create task with photo
   - Move through columns
   - Complete task
   - Check streak updates

2. **Test Pro Features**
   - Enable iCloud sync
   - Create shared space
   - Test focus mode
   - Try analytics

3. **Prepare for App Store** (if desired)
   - Create screenshots
   - Write description
   - Set up App Store Connect
   - Submit for review

---

## Support

If build fails:
1. Check error message in Xcode
2. Verify all files exist
3. Try clean build (Cmd+Shift+K)
4. Restart Xcode
5. Check Apple Developer forums

---

**Last Updated:** Feb 21, 2025  
**Xcode Version:** 15.0+  
**iOS Version:** 17.6+
