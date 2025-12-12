# Device Testing Guide

This document provides comprehensive guidelines for testing the English Learning mobile app on physical Android and iOS devices.

---

## Testing Strategy

### Test Device Categories

**Android**:
- **Budget** (2-3 years old): Testing baseline performance
- **Mid-range** (1-2 years old): Testing typical user experience
- **Flagship** (current year): Testing optimal experience

**iOS**:
- **Older devices**: iPhone 8/SE (iOS 15+)
- **Current**: iPhone 12-14 (iOS 16+)
- **Latest**: iPhone 15+ (iOS 17+)

### OS Version Coverage

**Android**:
- ✅ **Android 8.0 (API 26)**: Minimum supported version
- ✅ **Android 10 (API 29)**: Testing mid-range compatibility
- ✅ **Android 12 (API 31)**: Modern features
- ✅ **Android 13+ (API 33+)**: Latest features

**iOS**:
- ✅ **iOS 15**: Minimum supported version
- ✅ **iOS 16**: Current mainstream
- ✅ **iOS 17+**: Latest features

---

## Test Scenarios

### 1. App Installation & Startup

#### Android
```bash
# Install APK on connected device
flutter install -d <device-id>

# Or manually:
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Check for crashes
adb logcat | grep -i "flutter\|crash\|error"
```

**Test Cases**:
- [ ] Fresh install completes successfully
- [ ] App icon displays correctly on launcher
- [ ] App name displays correctly
- [ ] First launch shows splash screen
- [ ] Cold start completes within 3 seconds
- [ ] Warm start completes within 1 second
- [ ] No ANR (Application Not Responding) errors
- [ ] Permissions requested appropriately

#### iOS
```bash
# Install on connected iOS device
flutter install -d <device-id>

# Check Console.app for crashes
# Or use Xcode's Devices window
```

**Test Cases**:
- [ ] App installs without errors
- [ ] App icon displays correctly (all sizes)
- [ ] Launch screen displays properly
- [ ] Cold start < 3 seconds
- [ ] No crashes on first launch
- [ ] Permissions presented correctly
- [ ] Face ID/Touch ID integration works

---

### 2. Authentication Flow

**Test Cases**:
- [ ] Register new account
  - [ ] Email validation works
  - [ ] Password visibility toggle
  - [ ] Error messages display correctly
  - [ ] Loading indicators show
  - [ ] Success navigation to home
  
- [ ] Login with existing account
  - [ ] Credentials remembered (if opted in)
  - [ ] Login success navigates to home
  - [ ] Invalid credentials show error
  - [ ] Network error handled gracefully
  
- [ ] Social auth (if implemented)
  - [ ] Google Sign-In flow
  - [ ] Apple Sign-In (iOS)
  - [ ] Facebook Sign-In
  
- [ ] Session persistence
  - [ ] User stays logged in after app restart
  - [ ] Session expires appropriately
  - [ ] Logout clears session

---

### 3. Audio Features (Critical)

#### Audio Playback

**Test Cases**:
- [ ] Audio plays correctly
  - [ ] Clear audio quality
  - [ ] No stuttering or lag
  - [ ] Volume control works
  - [ ] Playback speed adjustment
  - [ ] Pause/resume functionality
  
- [ ] Audio focus management
  - [ ] Incoming call pauses audio
  - [ ] Notification sounds don't interfere
  - [ ] Other apps' audio handled properly
  - [ ] Audio resumes after interruption
  
- [ ] Headphone scenarios
  - [ ] Audio plays through headphones
  - [ ] Headphone disconnect handled
  - [ ] Bluetooth headphones work
  - [ ] Audio switches correctly
  
- [ ] Background audio
  - [ ] Audio continues when app backgrounded
  - [ ] Media controls show in notification
  - [ ] Lock screen controls work

**Devices to Test**:
- Various headphone types (wired, Bluetooth)
- Different speaker qualities
- Various volume levels
- With/without case on phone

#### Audio Recording

**Test Cases**:
- [ ] Microphone permission
  - [ ] Permission requested appropriately
  - [ ] Denial handled gracefully
  - [ ] Re-request works if needed
  
- [ ] Recording functionality
  - [ ] Recording starts successfully
  - [ ] Recording indicator visible
  - [ ] Recording quality acceptable
  - [ ] Maximum 10MB buffer enforced
  - [ ] No file writes (memory buffer only)
  - [ ] Recording stops cleanly
  
- [ ] Recording scenarios
  - [ ] Quiet environment
  - [ ] Noisy environment
  - [ ] Various distances from mic
  - [ ] Different microphones (phone, headset)
  
- [ ] Recording interruptions
  - [ ] Incoming call stops recording
  - [ ] Other apps requesting mic
  - [ ] Low memory situations
  - [ ] App backgrounded during recording

**Testing Script**:
```bash
# Android: Check audio permissions
adb shell dumpsys package com.example.english_learning_app | grep "android.permission.RECORD_AUDIO"

# Android: Monitor audio recording
adb logcat | grep -i "audio\|recording\|microphone"

# iOS: Check in Settings > Privacy > Microphone
```

---

### 4. Game Play Features

**Test Cases**:
- [ ] Game configuration
  - [ ] Level selection works
  - [ ] Type selection (listen-only/repeat)
  - [ ] Tag filtering
  - [ ] Count selection
  - [ ] Start game button responsive
  
- [ ] Listen-only mode
  - [ ] Speeches load correctly
  - [ ] Audio playback smooth
  - [ ] Swipe gestures work
  - [ ] Streak counter accurate
  - [ ] Pause/resume functionality
  - [ ] Session completion tracked
  
- [ ] Listen-and-repeat mode
  - [ ] Recording interface clear
  - [ ] Recording works reliably
  - [ ] Pronunciation feedback shown
  - [ ] Score calculation correct
  - [ ] Playback of recording works
  
- [ ] Performance
  - [ ] No lag during gameplay
  - [ ] Smooth animations
  - [ ] Quick transitions
  - [ ] No frame drops

---

### 5. Network & Offline Functionality

**Test Cases**:
- [ ] Online mode
  - [ ] API calls complete successfully
  - [ ] Data loads quickly
  - [ ] Images load properly
  - [ ] Error handling for failed requests
  
- [ ] Offline mode
  - [ ] App functions without internet
  - [ ] Cached data accessible
  - [ ] Offline indicator shown
  - [ ] Actions queued for sync
  
- [ ] Network transitions
  - [ ] WiFi to mobile data switch
  - [ ] Online to offline transition
  - [ ] Offline to online sync
  - [ ] Airplane mode handling
  
- [ ] Background sync
  - [ ] Queued actions sync on reconnect
  - [ ] No data loss
  - [ ] Sync conflicts resolved
  - [ ] Retry logic works

**Testing Commands**:
```bash
# Android: Toggle airplane mode
adb shell cmd connectivity airplane-mode enable
adb shell cmd connectivity airplane-mode disable

# Android: Disable mobile data
adb shell svc data disable
adb shell svc data enable

# Android: Disable WiFi
adb shell svc wifi disable
adb shell svc wifi enable
```

---

### 6. UI & Responsiveness

**Test Cases**:
- [ ] Different screen sizes
  - [ ] Small phones (< 5 inches)
  - [ ] Standard phones (5-6 inches)
  - [ ] Large phones (> 6 inches)
  - [ ] Tablets (7 inches)
  - [ ] Large tablets (10+ inches)
  
- [ ] Different aspect ratios
  - [ ] 16:9 (older devices)
  - [ ] 18:9, 19:9 (modern phones)
  - [ ] Notch devices (iPhone X+)
  - [ ] Punch-hole displays
  
- [ ] Orientations
  - [ ] Portrait mode (primary)
  - [ ] Landscape mode (if supported)
  - [ ] Rotation handling
  
- [ ] Touch interactions
  - [ ] Buttons responsive
  - [ ] Minimum touch target size (48dp)
  - [ ] Swipe gestures smooth
  - [ ] Scroll performance
  
- [ ] Text rendering
  - [ ] Text readable at default size
  - [ ] Text scaling (accessibility)
  - [ ] Font rendering clear
  - [ ] No text cutoff

---

### 7. Performance Testing

**Test Cases**:
- [ ] Frame rate
  - [ ] Smooth 60 FPS during normal use
  - [ ] No jank during animations
  - [ ] Scrolling smooth
  
- [ ] Memory usage
  - [ ] Baseline memory < 100MB
  - [ ] Peak memory < 150MB
  - [ ] No memory leaks
  - [ ] Proper cleanup on exit
  
- [ ] Battery usage
  - [ ] Normal usage doesn't drain rapidly
  - [ ] Background sync efficient
  - [ ] Audio playback reasonable drain
  
- [ ] App size
  - [ ] Download size < 30MB
  - [ ] Installed size reasonable
  - [ ] Cache management working

**Testing Tools**:
```bash
# Android: Monitor memory
adb shell dumpsys meminfo com.example.english_learning_app

# Android: Monitor CPU
adb shell top | grep com.example.english_learning_app

# Android: Monitor battery
adb shell dumpsys battery

# Android: Monitor FPS (Requires development mode)
adb shell dumpsys gfxinfo com.example.english_learning_app framestats
```

---

### 8. Permissions

**Required Permissions**:
- ✅ **Microphone**: For audio recording
- ✅ **Internet**: For API calls
- ✅ **Network State**: For connectivity checks

**Test Cases**:
- [ ] Permissions requested at appropriate time
- [ ] Permission rationale shown
- [ ] Denial handled gracefully
- [ ] App functions with denied permissions
- [ ] Re-request permissions works
- [ ] Settings deep link for permissions

**Android Permission Check**:
```bash
adb shell dumpsys package com.example.english_learning_app | grep permission
```

**iOS Permission Check**:
- Settings > Privacy > Microphone
- Settings > [App Name] > Permissions

---

### 9. Edge Cases & Error Scenarios

**Test Cases**:
- [ ] Low memory situations
  - [ ] App doesn't crash
  - [ ] Graceful degradation
  - [ ] Warning messages shown
  
- [ ] Storage issues
  - [ ] Full storage handled
  - [ ] Cache cleared appropriately
  
- [ ] Slow network
  - [ ] Loading indicators shown
  - [ ] Timeout handled correctly
  - [ ] Retry options available
  
- [ ] App lifecycle
  - [ ] App paused/resumed correctly
  - [ ] Background > Foreground transition
  - [ ] App termination recovery
  - [ ] State preserved correctly
  
- [ ] Interruptions
  - [ ] Incoming calls handled
  - [ ] Notifications don't break app
  - [ ] Other apps opening
  - [ ] System dialogs (low battery, etc.)

---

### 10. Accessibility

**Test Cases**:
- [ ] Screen readers
  - [ ] TalkBack (Android) navigation
  - [ ] VoiceOver (iOS) navigation
  - [ ] All interactive elements labeled
  - [ ] Proper reading order
  
- [ ] Text scaling
  - [ ] App works with large text
  - [ ] No text cutoff
  - [ ] Layouts adapt
  
- [ ] Color contrast
  - [ ] Sufficient contrast ratios
  - [ ] Information not color-only
  - [ ] Dark mode support
  
- [ ] Touch targets
  - [ ] Minimum 48x48dp size
  - [ ] Adequate spacing
  - [ ] Easy to tap

---

## Testing Workflow

### Pre-Testing Setup

1. **Prepare devices**:
   ```bash
   # List connected devices
   flutter devices
   
   # Install on specific device
   flutter install -d <device-id>
   ```

2. **Enable developer options**:
   - Android: Settings > About > Tap Build Number 7 times
   - iOS: Xcode > Window > Devices and Simulators

3. **Enable USB debugging** (Android)

4. **Trust computer** (iOS)

### Testing Checklist

#### Initial Setup (Per Device)
- [ ] Device information documented
- [ ] OS version confirmed
- [ ] Developer mode enabled
- [ ] App installed successfully
- [ ] Logging enabled

#### Core Flow Testing
- [ ] Authentication flow
- [ ] Game configuration
- [ ] Game play (both modes)
- [ ] History viewing
- [ ] Profile management
- [ ] Settings

#### Hardware Testing
- [ ] Audio playback
- [ ] Audio recording
- [ ] Touch interactions
- [ ] Screen orientations

#### Network Testing
- [ ] Online functionality
- [ ] Offline mode
- [ ] Network transitions
- [ ] Background sync

#### Performance Testing
- [ ] Startup time
- [ ] Navigation speed
- [ ] Memory usage
- [ ] Battery impact

#### Edge Case Testing
- [ ] Interruptions
- [ ] Low resources
- [ ] Permissions
- [ ] Error scenarios

---

## Reporting Issues

### Issue Template

```markdown
**Device**: [e.g., Samsung Galaxy S21, iPhone 13 Pro]
**OS Version**: [e.g., Android 12, iOS 16.1]
**App Version**: [e.g., 1.0.0 (build 1)]

**Issue Description**:
[Clear description of the problem]

**Steps to Reproduce**:
1. [First step]
2. [Second step]
3. [...]

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happens]

**Screenshots/Videos**:
[If applicable]

**Logs**:
```
[Paste relevant logs]
```

**Frequency**: [Always / Sometimes / Once]
**Severity**: [Critical / Major / Minor / Cosmetic]
```

### Log Collection

**Android**:
```bash
# Capture logs while reproducing issue
adb logcat -v time > issue_logs.txt

# Or filter for Flutter logs
adb logcat | grep -i flutter > flutter_logs.txt
```

**iOS**:
```bash
# Use Xcode Console
# Or use idevicesyslog (requires libimobiledevice)
idevicesyslog > ios_logs.txt
```

---

## Test Devices Matrix

### Recommended Test Matrix

| Device Type | Model Example | Android | iOS | Priority |
|------------|---------------|---------|-----|----------|
| Budget Phone | Samsung A32 | 11 | - | High |
| Mid-range | Pixel 6a | 13 | - | High |
| Flagship | Samsung S23 | 14 | - | Medium |
| Older iPhone | iPhone 8 | - | 15 | High |
| Current iPhone | iPhone 13 | - | 16 | High |
| Latest iPhone | iPhone 15 | - | 17 | Medium |
| Small Tablet | iPad Mini | - | 16 | Low |
| Large Tablet | iPad Pro 12.9" | - | 17 | Low |

### Minimum Required Tests

✅ **Must Test** (Before Release):
- At least 1 Android device (Android 10+)
- At least 1 iOS device (iOS 15+)
- Both audio playback and recording
- Offline mode
- All critical user flows

🔄 **Should Test** (RC Testing):
- 2-3 Android devices (various manufacturers)
- 2-3 iOS devices (various models)
- Tablet form factors
- Various network conditions
- Extended usage sessions

⚡ **Nice to Test** (Beta Testing):
- 5+ Android devices
- 5+ iOS devices
- Accessibility features
- Performance profiling
- Beta user feedback

---

## Automated Device Testing

### Using Firebase Test Lab (Android)

```bash
# Build APK for testing
flutter build apk --release

# Upload to Firebase Test Lab
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/flutter-apk/app-release.apk \
  --test build/app/outputs/flutter-apk/app-debug-androidTest.apk \
  --device model=Pixel2,version=28,locale=en,orientation=portrait
```

### Using TestFlight (iOS)

1. Build for release:
   ```bash
   flutter build ipa
   ```

2. Upload to App Store Connect:
   - Use Xcode or Transporter app
   
3. Add external testers

4. Collect feedback

---

**Last Updated**: December 11, 2025  
**Next Review**: After device testing completion (M069)
