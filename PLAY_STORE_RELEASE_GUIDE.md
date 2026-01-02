# 🚀 Play Store Release Guide for FitTrack

## Step 1: Create App Icon 🎨

### 1.1 Design Your Icon
- **Size**: 1024x1024 pixels
- **Format**: PNG with transparent background
- **Design**: Fitness-related (walking person, steps, etc.)
- **Colors**: Blue/Green theme matching your app

### 1.2 Save Icon
- Save as `app_icon.png` in `assets/icon/` folder
- Use free tools: Canva, Figma, or Icons8

### 1.3 Generate Icons
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## Step 2: Create Keystore 🔐

### 2.1 Generate Keystore (Windows)
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2.2 Create key.properties
Create `android/key.properties`:
```
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

## Step 3: Build Release APK 📦

### 3.1 Clean Build
```bash
flutter clean
flutter pub get
```

### 3.2 Build APK
```bash
flutter build apk --release
```

### 3.3 Build App Bundle (Recommended)
```bash
flutter build appbundle --release
```

## Step 4: Test Release Build ✅

### 4.1 Install APK
```bash
flutter install --release
```

### 4.2 Test Features
- [ ] Step counting works
- [ ] Permissions granted
- [ ] Charts display correctly
- [ ] Theme toggle works
- [ ] Data persists

## Step 5: Play Store Assets 📱

### 5.1 Screenshots (Required)
- **Phone**: 2-8 screenshots (1080x1920 or 1440x2560)
- **Tablet**: 1-8 screenshots (1200x1920 or 1600x2560)

### 5.2 Store Listing
- **Title**: "FitTrack - Step Counter & Fitness Tracker"
- **Short Description**: "Track daily steps, calories, and distance with beautiful charts"
- **Full Description**: 
```
🚶‍♂️ Track Your Fitness Journey

FitTrack helps you monitor your daily activity with:
• Step counter using phone sensors
• Calorie calculation
• Distance tracking
• Weekly progress charts
• Light/Dark theme
• Data persistence

Simple, clean, and effective fitness tracking!
```

### 5.3 Graphics
- **Feature Graphic**: 1024x500 pixels
- **App Icon**: 512x512 pixels (high-res)

## Step 6: Upload to Play Store 🏪

### 6.1 Create Developer Account
- Go to play.google.com/console
- Pay $25 registration fee
- Complete account setup

### 6.2 Create New App
- Choose "Create app"
- Fill app details
- Select "App" type

### 6.3 Upload Build
- Go to "Release" → "Production"
- Upload your `.aab` file
- Fill release notes

### 6.4 Complete Store Listing
- Add screenshots
- Write descriptions
- Set content rating
- Add privacy policy

## Step 7: Privacy & Compliance 📋

### 7.1 Privacy Policy (Required)
Create simple privacy policy covering:
- Step data collection
- Local storage only
- No data sharing

### 7.2 Permissions Declaration
- Activity Recognition: For step counting
- Storage: For saving user data

## Step 8: Release Checklist ✅

- [ ] App icon generated
- [ ] Keystore created and secured
- [ ] Release build tested
- [ ] Screenshots taken
- [ ] Store listing complete
- [ ] Privacy policy added
- [ ] All compliance forms filled

## 🎉 Congratulations!

Your FitTrack app is ready for the Play Store! 

**Build Location**: `build/app/outputs/bundle/release/app-release.aab`

**Next Steps**:
1. Upload to Play Console
2. Wait for review (1-3 days)
3. Publish when approved!

---

## Troubleshooting 🔧

**Build Errors**: Run `flutter doctor` and fix issues
**Keystore Issues**: Ensure key.properties path is correct
**Upload Errors**: Check app bundle size (<150MB)

Good luck with your app launch! 🚀