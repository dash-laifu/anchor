# 📋 Google Play Store Release Checklist

## Pre-Release Preparation

### 🔑 Keystore Setup
- [ ] **Generate release keystore**: Run `.\scripts\setup-keystore.ps1`
- [ ] **Backup keystore securely**: Store `anchor-release-key.keystore` in safe location
- [ ] **Document passwords**: Save in secure password manager
- [ ] **Test keystore**: Verify `key.properties` configuration works

### 📱 App Testing
- [ ] **Functional testing**: All features work correctly
- [ ] **GPS accuracy**: Test in various environments (indoor/outdoor)
- [ ] **Notifications**: Verify reminders work on different Android versions
- [ ] **Permissions**: Test permission flows and denials
- [ ] **Storage**: Test with limited device storage
- [ ] **Performance**: No memory leaks or excessive battery usage
- [ ] **Offline mode**: Verify app works without internet

### 📄 Legal & Compliance
- [ ] **Privacy policy**: Ensure docs/PRIVACY.md is accessible
- [ ] **Content rating**: App suitable for all ages
- [ ] **Permissions justified**: Each permission has clear purpose
- [ ] **No restricted content**: No violence, gambling, adult content

## Google Play Console Setup

### 🏪 Store Listing
- [ ] **App name**: "Anchor - Parking Saver"
- [ ] **Short description**: Under 80 characters, highlights key benefit
- [ ] **Full description**: Comprehensive feature list and benefits
- [ ] **App icon**: 512×512 PNG uploaded
- [ ] **Feature graphic**: 1024×500 PNG created and uploaded
- [ ] **Screenshots**: Minimum 2 phone screenshots uploaded
- [ ] **Category**: Maps & Navigation selected
- [ ] **Tags**: parking, navigation, GPS, privacy, offline

### 📊 App Content
- [ ] **Content rating**: Complete questionnaire (expect "Everyone")
- [ ] **Target audience**: 13+ years (safe for location services)
- [ ] **Data safety**: Complete data collection disclosure
- [ ] **App access**: Free app, available globally

### 🔒 Data Safety Section
- [ ] **Location data**: Yes - for saving parking spots (not shared)
- [ ] **Photos**: Yes - for spot identification (stored locally)
- [ ] **Personal info**: No
- [ ] **Data sharing**: None with third parties
- [ ] **Data deletion**: Users can delete all data
- [ ] **Encryption**: Not applicable (no data transmission)

## Build & Release

### 🔨 Release Build
- [ ] **Update version**: Set version number in pubspec.yaml
- [ ] **Build app bundle**: Run `.\scripts\release.ps1 -Version 1.0.0 -Bundle`
- [ ] **Test release build**: `flutter install --release`
- [ ] **Verify signing**: Check app bundle is properly signed
- [ ] **File size check**: Ensure under 150MB limit

### 📤 Upload to Play Console
- [ ] **Create release**: Go to Production track
- [ ] **Upload app bundle**: Upload `app-release.aab`
- [ ] **Release notes**: Write clear version 1.0.0 notes
- [ ] **Release name**: "1.0.0 - Initial Release"
- [ ] **Rollout percentage**: Start with 100% for initial release

## Review & Launch

### 🔍 Pre-Launch Review
- [ ] **Store listing review**: All information complete and accurate
- [ ] **Screenshots review**: Show actual app functionality
- [ ] **Description review**: No misleading claims
- [ ] **Permissions review**: Only necessary permissions requested
- [ ] **Content rating review**: Accurate for app content

### 🚀 Submit for Review
- [ ] **Review submission**: Click "Review release"
- [ ] **Confirm details**: Double-check all information
- [ ] **Submit**: Click "Start rollout to production"
- [ ] **Monitor status**: Check review progress daily

### 📱 Post-Launch
- [ ] **Verify live**: Check app appears in Play Store
- [ ] **Test download**: Download from store and test
- [ ] **Monitor reviews**: Respond to user feedback
- [ ] **Check analytics**: Monitor download and usage stats
- [ ] **Plan updates**: Prepare for future versions

## Quick Reference Commands

### Keystore Setup
```powershell
.\scripts\setup-keystore.ps1
```

### Build Release
```powershell
# App Bundle (recommended)
.\scripts\release.ps1 -Version 1.0.0 -Bundle

# APK (alternative)
.\scripts\release.ps1 -Version 1.0.0 -Apk
```

### Test Release
```powershell
flutter install --release
```

### Version Update
```yaml
# pubspec.yaml
version: 1.0.0+1  # Increment build number for each release
```

## Common Issues & Solutions

### Build Issues
| Issue | Solution |
|-------|----------|
| Keystore not found | Run `.\scripts\setup-keystore.ps1` |
| Signing failed | Check `key.properties` file exists and is correct |
| Build timeout | Increase Flutter build timeout |
| APK too large | Enable code obfuscation and optimize assets |

### Upload Issues
| Issue | Solution |
|-------|----------|
| Upload key mismatch | Use same keystore for all releases |
| Version conflict | Increment version code in pubspec.yaml |
| Permission warnings | Justify each permission in store listing |
| Icon rejected | Ensure 512×512 PNG with transparent background |

### Review Issues
| Issue | Solution |
|-------|----------|
| Privacy policy missing | Link to docs/PRIVACY.md or create web page |
| Misleading description | Ensure description matches actual app features |
| Permission not justified | Explain location/camera use in store listing |
| Content rating incorrect | Review questionnaire answers for accuracy |

## Success Metrics

### Launch Week Goals
- [ ] **App approved**: No rejection from Google review
- [ ] **Zero crashes**: No critical crash reports
- [ ] **Downloads**: 10+ organic downloads
- [ ] **Rating**: 4.0+ star rating
- [ ] **Reviews**: First positive user reviews

### Month 1 Goals
- [ ] **User growth**: 100+ downloads
- [ ] **Retention**: Users saving multiple parking spots
- [ ] **Performance**: <1% crash rate
- [ ] **Feedback**: Feature requests from users
- [ ] **Store presence**: Visible in navigation category searches

## Documentation References

- **Complete Guide**: `docs/PLAYSTORE_RELEASE.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`
- **Privacy Policy**: `docs/PRIVACY.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **API Reference**: `docs/API.md`

## Support Contacts

### Google Play Console
- **Developer Console**: [play.google.com/console](https://play.google.com/console)
- **Policy Help**: [support.google.com/googleplay/android-developer](https://support.google.com/googleplay/android-developer)
- **Developer Support**: Available through console

### App Resources
- **Documentation**: See `docs/` directory
- **Issue Tracking**: GitHub repository issues
- **Developer Contact**: For critical issues or security concerns

---

**💡 Pro Tips:**
- Start review process early (can take 1-3 days)
- Test on multiple devices and Android versions
- Keep keystore and passwords extremely secure
- Monitor first reviews closely for user feedback
- Prepare update plan for addressing initial user feedback

**🎯 Remember:** A successful launch is just the beginning. Plan for ongoing updates, user support, and feature improvements based on real user feedback.
