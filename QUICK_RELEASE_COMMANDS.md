# 🚀 Quick Release Commands

## 1. Generate App Icon
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## 2. Create Keystore (One-time)
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## 3. Build Release
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## 4. Test Release
```bash
flutter build apk --release
flutter install --release
```

## 5. Find Your Files
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`

## 6. Upload to Play Store
1. Go to play.google.com/console
2. Create new app
3. Upload app-release.aab
4. Complete store listing
5. Publish!

---

**Need help?** Check `PLAY_STORE_RELEASE_GUIDE.md` for detailed instructions.