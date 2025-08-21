# 🐛 Troubleshooting Guide

## Quick Solutions

### ⚡ Common Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| GPS not working | Check location permissions | [GPS Issues](#gps--location-issues) |
| Notifications not showing | Enable exact alarms | [Notification Issues](#notification-issues) |
| App crashes on startup | Clear app data | [App Crashes](#app-crashes) |
| Photos not saving | Grant camera permission | [Photo Issues](#photo-issues) |
| Can't navigate to spot | Check default navigation app | [Navigation Issues](#navigation-issues) |

---

## GPS & Location Issues

### 🛰️ "Unable to get location" Error

**Symptoms:**
- "Unable to get location" message when saving spot
- GPS accuracy shows "Low" or "Unknown"
- Save spot button doesn't work

**Solutions:**

#### 1. Check Location Permissions
```
Android Settings → Apps → Anchor → Permissions → Location
```
- Ensure "Allow all the time" or "Allow only while using app" is selected
- **Avoid "Don't allow"** - this breaks core functionality

#### 2. Enable Location Services
```
Android Settings → Location → Use location
```
- Toggle ON if disabled
- Ensure high accuracy mode enabled

#### 3. Check GPS Signal
- **Go outdoors** - GPS works poorly indoors
- **Wait 30-60 seconds** for GPS lock
- **Clear sky view** - buildings/trees block GPS signals

#### 4. Restart Location Services
```bash
# In phone settings:
Location → Advanced → Google Location Accuracy → Toggle OFF/ON
```

**Still not working?**
- Try airplane mode for 10 seconds, then turn off
- Restart phone to reset GPS chip
- Check if other map apps work (Google Maps, etc.)

---

### 🎯 GPS Accuracy Issues

**Symptoms:**
- Accuracy shows "Low" (>75 meters)
- Warning: "GPS weak (indoors?)"
- Saved location is inaccurate

**Understanding GPS Accuracy:**
- **High (≤25m)**: Perfect for most parking lots
- **Medium (26-75m)**: Good enough for large areas  
- **Low (>75m)**: May need additional context

**Improving Accuracy:**

#### Environmental Factors
- **Move outdoors** - GPS doesn't work well inside buildings
- **Open area** - Away from tall buildings or dense trees
- **Wait longer** - GPS accuracy improves over time
- **Check weather** - Heavy clouds can affect signal

#### Backup Strategies for Low GPS
When GPS is weak, add context:
- **Take a photo** of nearby landmarks
- **Add notes** like "Level 3, near elevator"
- **Include section** like "Blue Zone" or "Row J"

#### Technical Check
```dart
// Debug GPS in app (if debug mode enabled)
Settings → Debug Section → Test GPS
```

---

## Notification Issues

### 🔔 Reminders Not Showing

**Symptoms:**
- Set a reminder but notification never appears
- "Could not schedule reminder" error message
- Notifications work in other apps but not Anchor

**Solutions:**

#### 1. Enable Exact Alarms (Android 12+)
```
Android Settings → Apps → Special app access → Alarms & reminders → Anchor → Allow
```
**This is required on Android 12+ for reliable reminders**

#### 2. Check Notification Permissions
```
Android Settings → Apps → Anchor → Notifications → Allow notifications
```
- Ensure "Parking Reminders" channel is enabled
- Check "Show on lock screen" if desired

#### 3. Disable Battery Optimization
```
Android Settings → Battery → Battery optimization → Anchor → Don't optimize
```
Battery optimization can prevent alarms from firing

#### 4. Check Do Not Disturb
```
Android Settings → Sound & vibration → Do Not Disturb
```
- Ensure alarms are allowed during DND
- Or disable DND during parking times

**Test Notifications:**
```
Anchor → Settings → Debug Section → Test Notifications
```

---

### ⏰ Notifications Showing Late

**Symptoms:**
- Reminders appear minutes/hours after scheduled time
- Inconsistent notification timing

**Causes & Solutions:**

#### Battery Optimization
- **Whitelist Anchor** from battery optimization
- **Disable adaptive battery** for more reliable notifications

#### Doze Mode Issues
- **Keep phone occasionally active** during long parking sessions
- **Charge phone** - aggressive power saving affects alarms

#### Native Alarm Testing
```
Settings → Debug → Test Native Alarm
```
This tests Android's AlarmManager directly

---

## App Crashes

### 💥 App Crashes on Startup

**Symptoms:**
- App immediately closes when opening
- "Anchor has stopped" error message
- App won't stay open

**Solutions:**

#### 1. Clear App Data
```
Android Settings → Apps → Anchor → Storage → Clear Data
```
**Warning:** This deletes all saved parking spots

#### 2. Clear App Cache (First Try This)
```
Android Settings → Apps → Anchor → Storage → Clear Cache
```
Safer option - keeps your data

#### 3. Restart Phone
Sometimes fixes memory or permission issues

#### 4. Update Android WebView
```
Google Play Store → Search "Android System WebView" → Update
```

#### 5. Check Storage Space
- Ensure device has >500MB free space
- Clear unnecessary files/photos

**If still crashing:**
- Uninstall and reinstall app (loses all data)
- Check if other apps also crash (device issue)

---

### 🔄 App Crashes When Saving

**Symptoms:**
- App crashes when tapping "Save Spot"
- Crashes during photo capture
- Error during spot saving

**Solutions:**

#### Check Available Storage
- Need space for database and photos
- Clear old photos/files if storage full

#### Camera Issues
- Grant camera permission
- Close other camera apps
- Restart camera service

#### Database Corruption
```
Settings → Delete All Data → Start Fresh
```
Last resort - rebuilds database

---

## Photo Issues

### 📷 Photos Not Saving

**Symptoms:**
- Camera opens but photo doesn't attach to spot
- "Failed to save photo" error
- Photos missing from saved spots

**Solutions:**

#### 1. Camera Permission
```
Android Settings → Apps → Anchor → Permissions → Camera → Allow
```

#### 2. Storage Permission
```
Android Settings → Apps → Anchor → Permissions → Files and media → Allow
```

#### 3. Check Storage Space
- Photos need ~1-5MB each
- Ensure sufficient free space

#### 4. Camera App Conflicts
- Close other camera apps
- Restart phone if camera seems stuck

---

### 🖼️ Photos Not Displaying

**Symptoms:**
- Spot saved with photo but image doesn't show
- "Photo not found" error
- Thumbnail shows but full image missing

**Solutions:**

#### File System Check
Photos stored in app's private directory:
```
/data/data/com.dash_laifu.anchor/files/media/
```

#### Clear Media Cache
```
Settings → Debug → Clear Media Cache (if available)
```

#### Storage Integrity
```
Settings → Export Data → Check if photos included
```

---

## Navigation Issues

### 🧭 Navigation Not Working

**Symptoms:**
- Tapping "Navigate to Car" does nothing
- "No navigation app found" error
- Wrong navigation app opens

**Solutions:**

#### 1. Check Default Navigation App
```
Anchor → Settings → Default Navigation App
```
- Set to "Google Maps" or "Ask each time"
- Ensure selected app is installed

#### 2. Install Navigation App
- **Google Maps** (recommended)
- **Waze**
- Any app that supports coordinate URLs

#### 3. Test Navigation URL
Debug mode can show the generated navigation URL

#### 4. Phone Settings
```
Android Settings → Apps → Default apps → Opening links
```
Ensure navigation app can handle map links

---

### 🗺️ Wrong Directions

**Symptoms:**
- Navigation goes to wrong location
- Directions to street address instead of exact spot
- Walking directions not optimal

**Understanding Navigation:**
- Anchor passes **exact GPS coordinates** to navigation app
- Navigation app decides routing
- **Walking mode** is automatically requested

**Solutions:**
- **Use exact coordinates** in navigation app
- **Verify GPS accuracy** when saving spot
- **Add context** like photos or notes for reference

---

## Battery & Performance Issues

### 🔋 High Battery Usage

**Symptoms:**
- Anchor uses significant battery
- Phone gets warm during use
- Battery drains faster when app installed

**Investigation:**

#### Check Battery Usage
```
Android Settings → Battery → App battery usage → Anchor
```

**Normal Usage:**
- <1% battery per day with normal use
- Brief GPS usage when saving spots
- Minimal background activity

**High Usage Causes:**
- GPS stuck on (permission issue)
- Background location tracking (shouldn't happen)
- Excessive notifications

#### Solutions:
- **Restart app** to reset GPS
- **Check permissions** - remove unnecessary ones
- **Update app** if available

---

### 🐌 Slow Performance

**Symptoms:**
- App takes long time to open
- Laggy interface
- Slow GPS acquisition

**Solutions:**

#### Device Resources
- **Restart phone** to free memory
- **Close other apps** to free resources
- **Check storage space** (need >500MB free)

#### App Optimization
- **Clear app cache** (keeps data)
- **Update Android** to latest version
- **Check for app updates**

#### Database Performance
- **Clear old history** if many spots saved
- **Export and delete old data** if database large

---

## Permission Issues

### 🔐 Permission Errors

**Symptoms:**
- "Permission denied" errors
- Features not working despite granting permission
- Permission requests keep appearing

**Solutions:**

#### Reset App Permissions
```
Android Settings → Apps → Anchor → Permissions → Reset app preferences
```

#### Manual Permission Check
- **Location**: Required for GPS
- **Camera**: Optional for photos
- **Exact Alarms**: Required for reminders (Android 12+)
- **Notifications**: Required for reminders

#### Permission Troubleshooting
1. **Deny all permissions**
2. **Open app**
3. **Grant permissions one by one** when prompted
4. **Test each feature** after granting

---

## Data & Storage Issues

### 💾 Data Not Saving

**Symptoms:**
- Parking spots disappear after closing app
- Settings reset to defaults
- History shows empty

**Solutions:**

#### Storage Permissions
- Ensure app can write to internal storage
- Check if device storage is full

#### Database Issues
```
Settings → Debug → Database Info (if available)
```

#### Backup & Restore
```
Settings → Export Data → Save backup
Settings → Delete All Data → Import backup
```

---

### 📱 Storage Full Errors

**Symptoms:**
- "Storage full" when saving photos
- App crashes during save
- Cannot export data

**Solutions:**

#### Free Up Space
- Delete old photos/videos
- Clear other app caches
- Move files to cloud storage

#### App Storage Management
- **Limit photo taking** if storage low
- **Delete old parking spots** regularly
- **Export data** and clear history

---

## Debug & Testing Tools

### 🔧 Built-in Debug Features

Access debug tools in Settings screen (debug builds only):

#### GPS Testing
- **Test GPS acquisition**
- **Check accuracy levels**
- **View coordinates**

#### Notification Testing
- **Test immediate notifications**
- **Test scheduled reminders**
- **Test native alarms**
- **Check pending notifications**

#### Database Testing
- **View database info**
- **Test queries**
- **Export data**

#### System Information
- **Android version**
- **Device model**
- **Permission status**

---

### 📋 System Diagnostics

#### Check System Health
```
Android Settings → Device care → Optimize now
```

#### Check App Info
```
Android Settings → Apps → Anchor → App info
```
- Version number
- Last update
- Storage usage
- Battery usage

#### Network Check (Should be None)
```
Android Settings → Data usage → App data usage → Anchor
```
**Should show 0 bytes** - app doesn't use internet

---

## Getting Additional Help

### 📞 Before Contacting Support

1. **Try solutions above** for your specific issue
2. **Check app version** - ensure latest version
3. **Test on different device** if available
4. **Note error messages** exactly as shown
5. **Reproduce steps** that cause the issue

### 📝 Information to Provide

When seeking help, include:
- **Device model and Android version**
- **App version** (Settings → About)
- **Exact error message**
- **Steps to reproduce**
- **When issue started**
- **Other apps that work/don't work**

### 🔄 Last Resort Solutions

#### Factory Reset App
```
Settings → Delete All Data → Start Fresh
```
**Warning:** Deletes all saved parking spots

#### Reinstall App
1. **Export data** first (if possible)
2. **Uninstall app**
3. **Restart phone**
4. **Reinstall from store**
5. **Import data** if saved

---

## Prevention Tips

### 🛡️ Avoid Common Issues

#### Regular Maintenance
- **Keep Android updated**
- **Keep app updated**
- **Maintain 500MB+ free storage**
- **Restart phone weekly**

#### Best Practices
- **Save spots outdoors** when possible
- **Add photos/notes** for low GPS accuracy
- **Test reminders** after setting
- **Export data** regularly for backup

#### Permission Management
- **Grant only needed permissions**
- **Review permissions** after Android updates
- **Don't revoke core permissions** (location)

---

*This troubleshooting guide covers the most common issues. Most problems can be resolved by checking permissions, ensuring GPS signal, and maintaining adequate storage space.*
