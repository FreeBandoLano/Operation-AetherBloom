# 📱 Android Emulator Setup Guide for AetherBloom
## Complete Step-by-Step Instructions for Android Studio

### Prerequisites ✅
- Android Studio installed on your system
- Flutter SDK configured and working
- AetherBloom project ready for deployment

---

## 🚀 **Step 1: Open Android Studio**

1. **Launch Android Studio** from your Start menu or desktop
2. If you see the "Welcome to Android Studio" screen:
   - Click **"Open"** to open an existing project
   - Navigate to `C:\FlutterProjects\aetherbloom` and select it
3. If Android Studio opens with a different project, use **File → Open** to navigate to AetherBloom

---

## 🔧 **Step 2: Access AVD Manager**

### Method 1: Through the Top Menu
1. In Android Studio, click **Tools** in the top menu bar
2. Select **AVD Manager** (Android Virtual Device Manager)

### Method 2: Through the Toolbar
1. Look for the **device icon** in the top toolbar (usually has a phone/tablet symbol)
2. Click the dropdown arrow next to it
3. Select **"AVD Manager"**

### Method 3: Through Welcome Screen
1. If on the welcome screen, click **"Virtual Device Manager"** in the right panel

---

## 📱 **Step 3: Create New Virtual Device**

1. In the **AVD Manager** window, click **"Create Virtual Device"**
2. You'll see the **"Select Hardware"** dialog

### **Select Device Definition:**
**Recommended for Medical App Testing:**
- **Phone Category**: Choose **"Pixel 7"** or **"Pixel 6"**
  - ✅ Good screen size for medical interfaces
  - ✅ Modern Android features
  - ✅ Reliable FCM support
- **Alternative**: **"Pixel 4"** or **"Nexus 6"** for different screen sizes

**Key Specifications to Note:**
- **Screen Size**: 6.0" - 6.7" (optimal for medical apps)
- **Resolution**: 1080 x 2400 or higher
- **Density**: 420-560 dpi

3. Click **"Next"** after selecting your device

---

## 💿 **Step 4: Select System Image**

1. You'll see the **"System Image"** selection screen

### **Recommended API Level:**
**Choose API 34 (Android 14) or API 33 (Android 13):**
- ✅ Full FCM and notification support
- ✅ Latest security features for medical data
- ✅ Best compatibility with Flutter and Firebase

### **Download Process:**
1. If the system image isn't downloaded:
   - Look for **"Download"** link next to your chosen API level
   - Click **"Download"** 
   - Accept the license agreement
   - Wait for download (may take 5-15 minutes)

### **Image Selection:**
- Choose **"Google APIs"** version (not "Google Play" for development)
- Ensure **x86_64** architecture for better performance

2. Click **"Next"** after selecting system image

---

## ⚙️ **Step 5: Configure AVD Settings**

1. **AVD Name**: Change to something meaningful like:
   - `AetherBloom_Test_Pixel7`
   - `Medical_App_Emulator`

2. **Advanced Settings** (Click "Show Advanced Settings"):

### **Performance Settings:**
- **RAM**: 4096 MB (4GB) - Minimum for smooth operation
- **VM Heap**: 256 MB
- **Internal Storage**: 2048 MB
- **Graphics**: **Hardware - GLES 2.0** (for better performance)

### **Camera Settings:**
- **Front Camera**: Webcam0
- **Back Camera**: Webcam0
(Useful for testing camera features in medical apps)

### **Network Settings:**
- **Network Speed**: Full
- **Network Latency**: None
(Important for real-time Firebase sync)

### **Boot Options:**
- ✅ **Cold boot** (unchecked for faster startup)
- ✅ **Quick Boot** (checked for faster restarts)

3. Click **"Finish"** to create the emulator

---

## 🎮 **Step 6: Start the Emulator**

1. In **AVD Manager**, find your newly created device
2. Click the **▶️ Play button** (triangle icon) in the "Actions" column
3. **First boot may take 2-5 minutes** - be patient!

### **Emulator Boot Process:**
1. **Android logo** appears
2. **Setup wizard** (skip setup for testing)
3. **Home screen** appears

---

## 🔍 **Step 7: Verify Emulator Setup**

### **Check Emulator Features:**
1. **Internet Connection**: 
   - Open Chrome browser in emulator
   - Visit any website to confirm connectivity

2. **Google Play Services**:
   - Look for Google Play Store app
   - This ensures FCM will work properly

3. **System Info**:
   - **Settings → About Phone → Android Version**
   - Verify correct API level

---

## 🏃 **Step 8: Run AetherBloom on Emulator**

### **From Terminal:**
1. Open terminal in VS Code or Command Prompt
2. Navigate to project: `cd C:\FlutterProjects\aetherbloom`
3. List devices: `flutter devices`
4. You should see your emulator listed (e.g., "Pixel 7 API 34")
5. Run app: `flutter run` (Flutter will auto-select the emulator)

### **From Android Studio:**
1. Open the AetherBloom project in Android Studio
2. Select your emulator from the device dropdown (top toolbar)
3. Click **Run** button (green triangle)

### **From VS Code:**
1. Open AetherBloom project in VS Code
2. Press **F5** or **Ctrl+Shift+P** → "Flutter: Launch Emulator"
3. Select your created emulator
4. Run `flutter run` in terminal

---

## 📋 **Step 9: Test FCM Registration**

Once the app is running on the emulator:

1. **Navigate to**: Home → **"FCM Registration"** button
2. **Click**: "Get Current FCM Token"
3. **Verify**: You should see a REAL FCM token (not web simulation)
4. **Example real token**: 
   ```
   📱 Current FCM Token: f4x8k9mN2Kc:APA91bF...
   (Real 152+ character token)
   ```

---

## 🛠️ **Troubleshooting Common Issues**

### **Emulator Won't Start:**
- **Solution**: Ensure HAXM/Hyper-V is enabled in BIOS
- **Check**: Windows Features → Hyper-V platform enabled
- **Try**: Create new AVD with different API level

### **Slow Performance:**
- **Increase RAM**: 6GB+ if your system allows
- **Enable Hardware Graphics**: Hardware - GLES 2.0
- **Close other applications** to free system resources

### **No Internet in Emulator:**
- **Restart emulator**
- **Check**: Windows firewall isn't blocking emulator
- **Try**: Cold boot emulator

### **Flutter App Won't Install:**
- **Run**: `flutter clean` then `flutter run`
- **Check**: Emulator shows in `flutter devices`
- **Verify**: USB Debugging enabled (should be automatic)

---

## ✅ **Success Checklist**

- [ ] Android Studio AVD Manager accessible
- [ ] Virtual device created with API 33/34
- [ ] Emulator boots successfully
- [ ] Internet connection working in emulator
- [ ] Flutter app deploys and runs
- [ ] Real FCM tokens generated (not web simulation)
- [ ] Notifications can be tested

---

## 🎯 **Next Steps After Setup**

1. **Test all notification features** with real FCM tokens
2. **Test Firebase Cloud Messaging** from Firebase Console
3. **Verify real-time Firestore sync** on mobile
4. **Test camera and sensor features** preparation for IoT
5. **Performance testing** with larger datasets

---

## 📞 **Need Help?**

If you encounter issues:
1. **Check Android Studio logs**: View → Tool Windows → Logcat
2. **Flutter doctor**: Run `flutter doctor` to check setup
3. **Emulator logs**: AVD Manager → Actions → Show on Disk → View logs

**Ready to test AetherBloom on real Android environment! 🚀** 